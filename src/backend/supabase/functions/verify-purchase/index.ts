import { createClient } from "@supabase/supabase-js";

import { createGetCaller } from "../_shared/auth.ts";
import { sendPurchaseConfirmationEmail } from "../_shared/email.ts";
import { createRateLimiter } from "../_shared/rate_limit.ts";
import { handleVerifyPurchase } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
import type { Platform, PurchaseVerifier, SubscriptionUpsert } from "./types.ts";
import { GooglePlayVerifier } from "./google_play.ts";
import { AppleVerifier } from "./apple.ts";

// Supabase injects these into every Edge Function automatically.
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// service-role client: bypasses RLS, used only for the one write this
// function is trusted to make (see the migration — clients have no
// insert/update policy on `subscriptions`, only this function does).
const admin = createClient(supabaseUrl, supabaseServiceRoleKey);

const getCaller = createGetCaller(supabaseUrl, supabaseAnonKey);

// Generous enough for legitimate use (purchase, restore, retries after a
// flaky network) while stopping a script from hammering this endpoint —
// each call here is a real Google/Apple API request with its own quota
// and cost. Tune by watching verify_purchase_attempts volume in prod.
const isRateLimited = createRateLimiter(admin, {
  table: "verify_purchase_attempts",
  maxAttempts: 20,
  windowMs: 10 * 60 * 1000,
});

/**
 * Delegates to the `claim_subscription` Postgres function rather than doing
 * a PostgREST upsert here. The upsert this replaced resolved a conflict on
 * (platform, store_transaction_id) by overwriting the row's `user_id`, so
 * replaying a genuine store token from a second account transferred the
 * entitlement to it. The function makes ownership first-claim-wins and does
 * it atomically — see the 20260901120000 migration.
 *
 * Returns false when the transaction belongs to another account (nothing
 * written); the handler turns that into a 409.
 */
async function claimSubscription(row: SubscriptionUpsert): Promise<boolean> {
  const { data, error } = await admin.rpc("claim_subscription", {
    p_user_id: row.userId,
    p_platform: row.platform,
    p_product_id: row.productId,
    p_store_transaction_id: row.storeTransactionId,
    p_status: row.status,
    p_expires_at: row.expiresAt,
    p_raw_response: row.rawResponse,
  });
  if (error) throw new Error(`Failed to persist subscription: ${error.message}`);
  // Fail closed: only an explicit true counts as a successful claim.
  return data === true;
}

function buildVerifiers(): Partial<Record<Platform, PurchaseVerifier>> {
  const verifiers: Partial<Record<Platform, PurchaseVerifier>> = {};

  const googleServiceAccountJson = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
  const googlePackageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME");
  if (googleServiceAccountJson && googlePackageName) {
    verifiers.android = new GooglePlayVerifier(
      JSON.parse(googleServiceAccountJson),
      googlePackageName,
    );
  }

  const appleKeyId = Deno.env.get("APPLE_KEY_ID");
  const appleIssuerId = Deno.env.get("APPLE_ISSUER_ID");
  const applePrivateKey = Deno.env.get("APPLE_PRIVATE_KEY");
  const appleBundleId = Deno.env.get("APPLE_BUNDLE_ID");
  if (appleKeyId && appleIssuerId && applePrivateKey && appleBundleId) {
    verifiers.ios = new AppleVerifier({
      keyId: appleKeyId,
      issuerId: appleIssuerId,
      privateKey: applePrivateKey,
      bundleId: appleBundleId,
      environment: Deno.env.get("APPLE_ENVIRONMENT") === "production" ? "production" : "sandbox",
    });
  }

  // Deliberately no fallback/mock verifier here: an unconfigured platform
  // must fail closed (handler.ts returns 503), never silently grant
  // entitlement. See handler.ts's doc comment for why.
  return verifiers;
}

const deps: HandlerDeps = {
  getCaller,
  isRateLimited,
  verifiers: buildVerifiers(),
  claimSubscription,
  sendConfirmationEmail: sendPurchaseConfirmationEmail,
};

Deno.serve((req) => handleVerifyPurchase(req, deps));
