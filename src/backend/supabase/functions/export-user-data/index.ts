import { createClient } from "@supabase/supabase-js";

import { createGetCaller } from "../_shared/auth.ts";
import { createRateLimiter } from "../_shared/rate_limit.ts";
import { handleExportUserData } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
import type { UserDataExport } from "./types.ts";

// Supabase injects these into every Edge Function automatically.
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// service-role client: `subscriptions` already has a client-read RLS
// policy (auth.uid() = user_id), but `verify_purchase_attempts` has none
// at all — only this function's service-role client can read it. Using
// service role for both keeps this one query path consistent and, same as
// get-course-content, avoids a second round-trip to mint a scoped client.
const admin = createClient(supabaseUrl, supabaseServiceRoleKey);

const getCaller = createGetCaller(supabaseUrl, supabaseAnonKey);

// Lower than the other two functions: there's no legitimate reason for a
// user to re-export their own data many times in a short window, and each
// call does two table reads — this still comfortably covers "exported,
// then retried after a network hiccup."
const isRateLimited = createRateLimiter(admin, {
  table: "export_user_data_requests",
  maxAttempts: 10,
  windowMs: 10 * 60 * 1000,
});

async function buildExport(userId: string): Promise<UserDataExport> {
  const [subscriptionsResult, attemptsResult] = await Promise.all([
    admin
      .from("subscriptions")
      .select("platform, product_id, status, verified_at, expires_at, created_at")
      .eq("user_id", userId),
    admin.from("verify_purchase_attempts").select("created_at").eq("user_id", userId),
  ]);

  if (subscriptionsResult.error) {
    throw new Error(`Failed to read subscriptions: ${subscriptionsResult.error.message}`);
  }
  if (attemptsResult.error) {
    throw new Error(`Failed to read verification attempts: ${attemptsResult.error.message}`);
  }

  return {
    userId,
    exportedAt: new Date().toISOString(),
    subscriptions: subscriptionsResult.data.map((row) => ({
      platform: row.platform,
      productId: row.product_id,
      status: row.status,
      verifiedAt: row.verified_at,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
    })),
    verificationAttempts: attemptsResult.data.map((row) => ({
      createdAt: row.created_at,
    })),
  };
}

const deps: HandlerDeps = {
  getCaller,
  isRateLimited,
  buildExport,
};

Deno.serve((req) => handleExportUserData(req, deps));
