// Shared by every Edge Function in this project — not deployed on its own
// (Supabase's CLI skips directories prefixed with `_`).
import { createClient } from "@supabase/supabase-js";

/**
 * Factory, not a bare function: each function's index.ts already has its
 * own `supabaseUrl`/`supabaseAnonKey` read from the environment, and this
 * closes over them once instead of re-reading `Deno.env` per call.
 */
export function createGetUserId(
  supabaseUrl: string,
  supabaseAnonKey: string,
): (authHeader: string | null) => Promise<string | null> {
  return async (authHeader) => {
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
  };
}
