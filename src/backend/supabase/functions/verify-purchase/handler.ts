import { corsPreflightResponse, jsonResponse } from "../_shared/http.ts";
import { VerifyPurchaseInputSchema } from "./types.ts";
import type { Platform, PurchaseVerifier, SubscriptionUpsert } from "./types.ts";
import { isRealAccount } from "../_shared/auth.ts";
import type { Caller } from "../_shared/auth.ts";

export interface HandlerDeps {
  /** Resolves the caller's own id and account email, or null if unauthenticated. */
  getCaller(authHeader: string | null): Promise<Caller | null>;
  /**
   * Records this call as a verification attempt for `userId` and reports
   * whether they've exceeded the allowed rate — true means reject with 429.
   * Called once per request, after auth succeeds, before any store call.
   */
  isRateLimited(userId: string): Promise<boolean>;
  /** One verifier per platform. A missing entry means that platform isn't configured yet. */
  verifiers: Partial<Record<Platform, PurchaseVerifier>>;
  /**
   * Binds this store transaction to `row.userId`, returning false — and
   * writing nothing — if it already belongs to a different account. See the
   * 20260901120000 migration for why a store transaction is permanently
   * owned by whoever claims it first.
   */
  claimSubscription(row: SubscriptionUpsert): Promise<boolean>;
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

  const caller = await deps.getCaller(req.headers.get("Authorization"));
  if (!caller) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }
  if (!isRealAccount(caller)) {
    return jsonResponse(
      { error: "A real, confirmed account is required to purchase or restore a subscription." },
      403,
    );
  }
  const userId = caller.id;

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
  // A real, currently-active store token is readable on the buying device
  // and can simply be handed to someone else. Before this check, replaying
  // one from a second account passed the store's verification (the purchase
  // *is* genuine) and moved the entitlement row onto the replayer — giving
  // away Premium for free and stripping it from whoever actually paid.
  // Ownership is now first-claim-wins, enforced atomically in Postgres.
  const claimed = await deps.claimSubscription({
    userId,
    platform: input.platform,
    productId: input.productId,
    storeTransactionId: input.purchaseToken,
    status,
    expiresAt: result.expiresAt,
    rawResponse: result.raw,
  });
  if (!claimed) {
    return jsonResponse(
      {
        error:
          "This purchase is already linked to a different account. Sign in with that account to restore it.",
      },
      409,
    );
  }

  // Best-effort, deliberately outside the try/catch chain that turns
  // failures into error responses above: the entitlement is already
  // granted by this point (the upsert above succeeded), and a confirmation
  // email that fails to send must never undo that or turn an otherwise
  // successful purchase into an error response. See
  // docs/business/terms-of-service-draft.md §4 for the legal requirement
  // this fulfills, and _shared/email.ts for why it's a plain HTTP call.
  //
  // Uses caller.email (the account's own, verified server-side by
  // getCaller), not a client-supplied address — the caller is guaranteed
  // to have a real account by this point (checked above), so there's no
  // longer a legitimate case for "send this purchase confirmation to a
  // different address than my own account's."
  if (status === "active") {
    try {
      await deps.sendConfirmationEmail({
        to: caller.email,
        productId: input.productId,
        platform: input.platform,
      });
    } catch (error) {
      console.error("verify-purchase: confirmation email failed", error);
    }
  }

  return jsonResponse({ status, expiresAt: result.expiresAt }, 200);
}
