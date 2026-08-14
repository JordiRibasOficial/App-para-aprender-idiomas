import { createClient } from "@supabase/supabase-js";

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

async function getUserId(authHeader: string | null): Promise<string | null> {
  if (!authHeader?.startsWith("Bearer ")) return null;
  const jwt = authHeader.slice("Bearer ".length);
  // A fresh anon-key client per call, authenticated as the caller — this
  // validates the JWT the same way any other Supabase client would,
  // without needing to hand-parse or verify it ourselves.
  const asCaller = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data, error } = await asCaller.auth.getUser(jwt);
  if (error || !data.user) return null;
  return data.user.id;
}

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
  verifiers: buildVerifiers(),
  upsertSubscription,
};

Deno.serve((req) => handleVerifyPurchase(req, deps));
