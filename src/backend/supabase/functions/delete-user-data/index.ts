import { createClient } from "@supabase/supabase-js";

import { createGetUserId } from "../_shared/auth.ts";
import { createRateLimiter } from "../_shared/rate_limit.ts";
import { handleDeleteUserData } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";

// Supabase injects these into every Edge Function automatically.
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// service-role client: deleting an Auth user requires the Admin API, which
// only works with the service-role key.
const admin = createClient(supabaseUrl, supabaseServiceRoleKey);

const getUserId = createGetUserId(supabaseUrl, supabaseAnonKey);

// Tighter than export's 10/10min: there is even less legitimate reason to
// call this repeatedly — the first successful call already deletes the
// identity being rate-limited, so this mostly guards against rapid retries
// after a transient error.
const isRateLimited = createRateLimiter(admin, {
  table: "delete_user_data_requests",
  maxAttempts: 5,
  windowMs: 10 * 60 * 1000,
});

async function deleteUser(userId: string): Promise<void> {
  // Deletes the auth.users row itself, not just rows in public tables —
  // every table this backend writes for a user (subscriptions,
  // verify_purchase_attempts, get_course_content_requests,
  // export_user_data_requests, delete_user_data_requests) has an
  // `on delete cascade` FK to auth.users(id), so this one call is enough
  // to erase all of it in a single transaction, not five separate deletes
  // that could partially fail.
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) {
    throw new Error(`Failed to delete user: ${error.message}`);
  }
}

const deps: HandlerDeps = {
  getUserId,
  isRateLimited,
  deleteUser,
};

Deno.serve((req) => handleDeleteUserData(req, deps));
