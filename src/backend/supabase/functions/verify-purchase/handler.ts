import { VerifyPurchaseInputSchema } from "./types.ts";
import type { Platform, PurchaseVerifier, SubscriptionUpsert } from "./types.ts";

export interface HandlerDeps {
  /** Resolves the caller's user id from the request's Authorization header, or null if unauthenticated. */
  getUserId(authHeader: string | null): Promise<string | null>;
  /**
   * Records this call as a verification attempt for `userId` and reports
   * whether they've exceeded the allowed rate — true means reject with 429.
   * Called once per request, after auth succeeds, before any store call.
   */
  isRateLimited(userId: string): Promise<boolean>;
  /** One verifier per platform. A missing entry means that platform isn't configured yet. */
  verifiers: Partial<Record<Platform, PurchaseVerifier>>;
  upsertSubscription(row: SubscriptionUpsert): Promise<void>;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      // Most browser-facing security headers (CSP, X-Frame-Options,
      // Referrer-Policy, Permissions-Policy) protect HTML pages from
      // clickjacking/script injection/leaky referrers — this endpoint never
      // serves HTML, so they'd be theater. nosniff is the one exception:
      // it costs nothing and blocks a browser from reinterpreting this
      // JSON body as something executable if it's ever loaded directly
      // (e.g. a phishing page linking straight to the raw endpoint).
      "X-Content-Type-Options": "nosniff",
    },
  });
}

// CORS is a browser-only mechanism — it can't restrict which *app* calls
// this endpoint (mobile clients, curl, another server never send an Origin
// header, so CORS doesn't apply to them at all). The actual access control
// is the Bearer-token check in getUserId() below plus rate limiting. This
// function's only client is the Flutter app, which never runs inside a
// browser origin, so there is no legitimate Origin to allow — omitting
// Access-Control-Allow-Origin entirely means any browser-based caller (e.g.
// a malicious page trying to reuse a leaked anon key from a victim's
// session) gets its request blocked by the browser itself before this code
// ever sees the response. Deno.serve's default response to an OPTIONS
// preflight would otherwise fall through to the 405 below with no CORS
// headers, which browsers already treat as a deny — this makes that denial
// explicit instead of incidental.
function corsPreflightResponse(): Response {
  return new Response(null, { status: 204 });
}

/**
 * Pure-ish request handler, independent of the Deno.serve/Supabase runtime
 * wiring in index.ts — takes its dependencies as parameters so tests can
 * inject fakes instead of hitting real Postgres/Google/Apple.
 *
 * Security property this preserves end to end: entitlement is granted only
 * on a *positive* verification result from a *configured* verifier. Every
 * failure mode (no auth, bad input, unconfigured platform, verifier
 * error) returns an error response and writes nothing — it never falls
 * back to "assume active." A modified client cannot self-grant Premium by
 * sending a well-formed request; it still needs a store to vouch for it.
 */
export async function handleVerifyPurchase(req: Request, deps: HandlerDeps): Promise<Response> {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const userId = await deps.getUserId(req.headers.get("Authorization"));
  if (!userId) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  if (await deps.isRateLimited(userId)) {
    return jsonResponse(
      { error: "Too many verification attempts. Try again later." },
      429,
    );
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const parsed = VerifyPurchaseInputSchema.safeParse(body);
  if (!parsed.success) {
    return jsonResponse({ error: "Invalid request body", detail: parsed.error.flatten() }, 400);
  }
  const input = parsed.data;

  const verifier = deps.verifiers[input.platform];
  if (!verifier) {
    return jsonResponse(
      { error: `Purchase verification is not configured for platform "${input.platform}"` },
      503,
    );
  }

  let result;
  try {
    result = await verifier.verify(input);
  } catch (error) {
    // The caught error's message includes Google/Apple's raw API response
    // (see google_play.ts/apple.ts) — useful for debugging, not for the
    // client. Log it server-side (visible via `supabase functions logs` /
    // the Dashboard) and return a generic message instead of forwarding
    // upstream internals to whoever is calling this endpoint.
    console.error("verify-purchase: store verification call failed", error);
    return jsonResponse({ error: "Verification request to the store failed" }, 502);
  }

  const status = result.isActive ? "active" : "expired";
  await deps.upsertSubscription({
    userId,
    platform: input.platform,
    productId: input.productId,
    storeTransactionId: input.purchaseToken,
    status,
    expiresAt: result.expiresAt,
    rawResponse: result.raw,
  });

  return jsonResponse({ status, expiresAt: result.expiresAt }, 200);
}
