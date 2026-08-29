import { createClient } from "@supabase/supabase-js";

import { createGetUserId } from "../_shared/auth.ts";
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

const getUserId = createGetUserId(supabaseUrl, supabaseAnonKey);

// Generous enough for legitimate use (purchase, restore, retries after a
// flaky network) while stopping a script from hammering this endpoint —
// each call here is a real Google/Apple API request with its own quota
// and cost. Tune by watching verify_purchase_attempts volume in prod.
const isRateLimited = createRateLimiter(admin, {
  table: "verify_purchase_attempts",
  maxAttempts: 20,
  windowMs: 10 * 60 * 1000,
});

async function upsertSubscription(row: SubscriptionUpsert): Promise<void> {
  const { error } = await admin.from("subscriptions").upsert(
    {
      user_id: row.userId,
      platform: row.platform,
      product_id: row.productId,
      store_transaction_id: row.storeTransactionId,
      status: row.status,
      expires_at: row.expiresAt,
      raw_response: row.rawResponse,
      verified_at: new Date().toISOString(),
    },
    { onConflict: "platform,store_transaction_id" },
  );
  if (error) throw new Error(`Failed to persist subscription: ${error.message}`);
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
  getUserId,
  isRateLimited,
  verifiers: buildVerifiers(),
  upsertSubscription,
  sendConfirmationEmail: sendPurchaseConfirmationEmail,
};

Deno.serve((req) => handleVerifyPurchase(req, deps));
