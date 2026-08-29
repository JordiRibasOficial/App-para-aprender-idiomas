import { corsPreflightResponse, jsonResponse } from "../_shared/http.ts";
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
  /**
   * Sends the TRLGDCU durable-medium purchase confirmation (see the call
   * site below). Best-effort by design — see there for why a rejection
   * here must never fail the request.
   */
  sendConfirmationEmail(input: {
    to: string;
    productId: "monthly_sub" | "annual_sub";
    platform: Platform;
  }): Promise<void>;
}

/**
 * Entry point Deno.serve calls. Wraps the real logic below in a catch-all:
 * failures outside the store-verifier call (rate limit check, subscription
 * upsert — see index.ts) throw raw Postgres error messages, and this is
 * the net that keeps those off the client instead of relying on the
 * runtime's default unhandled-exception behavior.
 */
export async function handleVerifyPurchase(req: Request, deps: HandlerDeps): Promise<Response> {
  try {
    return await handleVerifyPurchaseUnsafe(req, deps);
  } catch (error) {
    console.error("verify-purchase: unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
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
async function handleVerifyPurchaseUnsafe(req: Request, deps: HandlerDeps): Promise<Response> {
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

  // Best-effort, deliberately outside the try/catch chain that turns
  // failures into error responses above: the entitlement is already
  // granted by this point (the upsert above succeeded), and a confirmation
  // email that fails to send must never undo that or turn an otherwise
  // successful purchase into an error response. See
  // docs/business/terms-of-service-draft.md §4 for the legal requirement
  // this fulfills, and _shared/email.ts for why it's a plain HTTP call.
  if (input.email && status === "active") {
    try {
      await deps.sendConfirmationEmail({
        to: input.email,
        productId: input.productId,
        platform: input.platform,
      });
    } catch (error) {
      console.error("verify-purchase: confirmation email failed", error);
    }
  }

  return jsonResponse({ status, expiresAt: result.expiresAt }, 200);
}
