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
    headers: { "Content-Type": "application/json" },
  });
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
    return jsonResponse(
      { error: "Verification request to the store failed", detail: String(error) },
      502,
    );
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
