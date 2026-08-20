import { corsPreflightResponse, jsonResponse } from "../_shared/http.ts";

export interface HandlerDeps {
  /** Resolves the caller's user id from the request's Authorization header, or null if unauthenticated. */
  getUserId(authHeader: string | null): Promise<string | null>;
  /**
   * Records this call as a request for `userId` and reports whether
   * they've exceeded the allowed rate — true means reject with 429. Called
   * once per request, after auth succeeds, before deleting anything.
   */
  isRateLimited(userId: string): Promise<boolean>;
  /**
   * Deletes everything this backend holds about `userId` — see index.ts:
   * deletes the underlying Supabase Auth user, which cascades to every
   * table with a `references auth.users (id) on delete cascade` FK
   * (subscriptions, verify_purchase_attempts, and the rate-limit tracking
   * tables), so there is nothing left to individually delete afterward.
   */
  deleteUser(userId: string): Promise<void>;
}

/**
 * Entry point Deno.serve calls. Wraps the real logic below in a catch-all —
 * same rationale as the other functions: a Postgres/Auth error shouldn't
 * leak its raw message to the client.
 */
export async function handleDeleteUserData(req: Request, deps: HandlerDeps): Promise<Response> {
  try {
    return await handleDeleteUserDataUnsafe(req, deps);
  } catch (error) {
    console.error("delete-user-data: unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
}

/**
 * RGPD art. 17 (right to erasure): permanently deletes everything this
 * backend holds tied to the caller's own identity, mirroring
 * export-user-data's scope exactly. No input body — there is nothing to
 * specify, the caller only ever deletes their own data, never anyone
 * else's, enforced by deleting exactly the userId resolved from their own
 * auth token (see index.ts).
 *
 * This is destructive and irreversible: once deleteUser succeeds, the
 * caller's anonymous Supabase identity no longer exists, so any Bearer
 * token minted for it stops working immediately (the mobile client signs
 * out locally right after this call succeeds — see
 * SupabaseUserDataDeletionRepository).
 */
async function handleDeleteUserDataUnsafe(req: Request, deps: HandlerDeps): Promise<Response> {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const userId = await deps.getUserId(req.headers.get("Authorization"));
  if (!userId) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  if (await deps.isRateLimited(userId)) {
    return jsonResponse({ error: "Too many requests. Try again later." }, 429);
  }

  await deps.deleteUser(userId);
  return jsonResponse({ deleted: true }, 200);
}
