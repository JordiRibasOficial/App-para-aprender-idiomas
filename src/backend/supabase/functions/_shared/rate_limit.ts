// Shared by every Edge Function in this project — not deployed on its own
// (Supabase's CLI skips directories prefixed with `_`).
import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * DB-backed sliding-window rate limiter: counts rows for `userId` in
 * `table` created within the last `windowMs`, then records this call as a
 * new row. `table` must have `user_id uuid` and `created_at timestamptz`
 * columns and be reachable only by the service-role client passed in here
 * (see the migration that creates it) — same shape as the original
 * `verify_purchase_attempts` table this generalizes.
 */
export function createRateLimiter(
  admin: SupabaseClient,
  options: { table: string; maxAttempts: number; windowMs: number },
): (userId: string) => Promise<boolean> {
  return async (userId) => {
    const windowStart = new Date(Date.now() - options.windowMs).toISOString();
    const { count, error } = await admin
      .from(options.table)
      .select("*", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", windowStart);
    if (error) throw new Error(`Rate limit check failed: ${error.message}`);
    if ((count ?? 0) >= options.maxAttempts) return true;

    const { error: insertError } = await admin.from(options.table).insert({ user_id: userId });
    if (insertError) {
      throw new Error(`Failed to record request: ${insertError.message}`);
    }
    return false;
  };
}
