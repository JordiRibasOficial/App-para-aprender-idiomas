import { createClient } from "@supabase/supabase-js";

import { createGetCaller } from "../_shared/auth.ts";
import { createRateLimiter } from "../_shared/rate_limit.ts";
import { handleSaveMarketingContact } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";

// Supabase injects these into every Edge Function automatically.
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// service-role client: bypasses RLS, used only for the one write this
// function is trusted to make (see the migration — clients have no
// insert/update policy on `marketing_contacts`, only this function does).
const admin = createClient(supabaseUrl, supabaseServiceRoleKey);

const getCaller = createGetCaller(supabaseUrl, supabaseAnonKey);

// Generous enough for a real user retrying after a flaky network call while
// still stopping abuse — this table is small, low-value to an attacker, and
// each row is a no-op re-opt-in for the same account anyway (see the
// upsert below), so a wide window is fine.
const isRateLimited = createRateLimiter(admin, {
  table: "marketing_contact_requests",
  maxAttempts: 10,
  windowMs: 10 * 60 * 1000,
});

async function upsertContact(input: { userId: string; email: string }): Promise<void> {
  const { error } = await admin.from("marketing_contacts").upsert(
    {
      user_id: input.userId,
      email: input.email,
      consented_at: new Date().toISOString(),
      // Re-opting in after a previous unsubscribe clears it — consistent
      // with consented_at itself being refreshed to "now" on every call.
      unsubscribed_at: null,
    },
    { onConflict: "user_id" },
  );
  if (error) throw new Error(`Failed to save marketing contact: ${error.message}`);
}

const deps: HandlerDeps = {
  getCaller,
  isRateLimited,
  upsertContact,
};

Deno.serve((req) => handleSaveMarketingContact(req, deps));
