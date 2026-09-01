// Shared by every Edge Function in this project — not deployed on its own
// (Supabase's CLI skips directories prefixed with `_`).
import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * DB-backed sliding-window rate limiter: counts requests for `userId` in
 * `table` within the last `windowMs` and records this one, reporting whether
 * the cap is already spent (true means reject with 429).
 *
 * The count and the insert happen inside one Postgres function
 * (`record_and_check_rate_limit`, see the 20260901120000 migration) rather
 * than as two round trips from here. The earlier two-step version had a
 * TOCTOU window: requests fired concurrently all read the same pre-insert
 * count and all passed the cap, which on verify-purchase is the only thing
 * bounding how many billed Google Play API calls a single account can
 * trigger. The function takes a per-(table, user) advisory lock, so
 * concurrent calls for the same user serialize and the cap actually holds.
 *
 * `table` must have `user_id uuid` and `created_at timestamptz` columns, be
 * reachable only by the service-role client passed in here, and be listed in
 * that function's allowlist.
 */
export function createRateLimiter(
  admin: SupabaseClient,
  options: { table: string; maxAttempts: number; windowMs: number },
): (userId: string) => Promise<boolean> {
  return async (userId) => {
    const { data, error } = await admin.rpc("record_and_check_rate_limit", {
      p_table: options.table,
      p_user_id: userId,
      p_max_attempts: options.maxAttempts,
      p_window_ms: options.windowMs,
    });
    if (error) throw new Error(`Rate limit check failed: ${error.message}`);
    // Fail closed: an unexpected null answer is treated as "limited" rather
    // than waving the request through.
    return data !== false;
  };
}
