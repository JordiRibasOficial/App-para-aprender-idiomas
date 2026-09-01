// Shared by every Edge Function in this project — not deployed on its own
// (Supabase's CLI skips directories prefixed with `_`).
import { createClient } from "@supabase/supabase-js";

export interface Caller {
  id: string;
  /** null for an anonymous session — a real account always has one. */
  email: string | null;
  /** Supabase's own flag for a `signInAnonymously()` session. */
  isAnonymous: boolean;
  /**
   * Whether the address in [email] has actually been proven to belong to
   * whoever is holding this session. Supabase auto-confirms at signup when
   * the project has email confirmation switched off, so this is only ever
   * false when confirmation is on and the user hasn't completed it.
   */
  isEmailConfirmed: boolean;
}

/**
 * Factory, not a bare function: each function's index.ts already has its
 * own `supabaseUrl`/`supabaseAnonKey` read from the environment, and this
 * closes over them once instead of re-reading `Deno.env` per call.
 *
 * Resolves the caller from their Bearer token, returning null if the token
 * is missing, malformed, expired, or otherwise rejected by Supabase Auth.
 */
export function createGetCaller(
  supabaseUrl: string,
  supabaseAnonKey: string,
): (authHeader: string | null) => Promise<Caller | null> {
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
    return {
      id: data.user.id,
      email: data.user.email ?? null,
      isAnonymous: data.user.is_anonymous === true,
      isEmailConfirmed: data.user.email_confirmed_at != null,
    };
  };
}

/**
 * The single definition of "this caller has a real account" that every
 * function gates on — purchasing, Premium content, data export, data
 * deletion and marketing consent all require one.
 *
 * Checks the three properties separately on purpose, rather than inferring
 * from `email != null` alone as an earlier version did:
 *
 * - `isAnonymous` is Supabase's own answer to the actual question. Deriving
 *   it from a null email was a proxy that happened to hold, and would stop
 *   holding the moment another sign-in method (phone) or a change in when
 *   Supabase populates `email` on the anonymous->permanent upgrade path
 *   entered the picture.
 * - `isEmailConfirmed` stops an unconfirmed signup from counting. Without
 *   it, anyone could register as someone else's address and have
 *   verify-purchase send our confirmation mail there on demand — turning
 *   our own sending domain into an attacker-triggered mailer, at the cost
 *   of its reputation. It also means the address we're legally required to
 *   send the TRLGDCU confirmation to is one the recipient actually controls.
 */
export function isRealAccount(
  caller: Caller,
): caller is Caller & { email: string } {
  return !caller.isAnonymous && caller.email != null && caller.isEmailConfirmed;
}
