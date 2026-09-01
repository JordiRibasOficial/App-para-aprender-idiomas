import { corsPreflightResponse, jsonResponse } from "../_shared/http.ts";
import type { UserDataExport } from "./types.ts";
import { isRealAccount } from "../_shared/auth.ts";
import type { Caller } from "../_shared/auth.ts";

export interface HandlerDeps {
  /** Resolves the caller's own id and account email, or null if unauthenticated. */
  getCaller(authHeader: string | null): Promise<Caller | null>;
  /**
   * Records this call as a request for `userId` and reports whether
   * they've exceeded the allowed rate — true means reject with 429. Called
   * once per request, after auth succeeds, before building the export.
   */
  isRateLimited(userId: string): Promise<boolean>;
  /** Assembles the caller's own export — see index.ts for the real Supabase queries. */
  buildExport(userId: string): Promise<UserDataExport>;
}

/**
 * Entry point Deno.serve calls. Wraps the real logic below in a catch-all —
 * same rationale as the other two functions: a Postgres error shouldn't
 * leak its raw message to the client.
 */
export async function handleExportUserData(req: Request, deps: HandlerDeps): Promise<Response> {
  try {
    return await handleExportUserDataUnsafe(req, deps);
  } catch (error) {
    console.error("export-user-data: unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
}

/**
 * RGPD art. 15/20 (right of access / data portability): lets a user pull
 * everything our backend holds about them — tied to their own anonymous
 * session identity, verified via the same Bearer-token check every other
 * function here uses. No input body: there is nothing to specify, the
 * caller only ever gets their own data (never anyone else's, enforced by
 * scoping every query to this userId — see index.ts).
 *
 * Deliberately excludes `store_transaction_id` and `raw_response` from
 * `subscriptions`: those are opaque store-internal identifiers and the
 * full raw verification payload kept for our own support/audit trail,
 * not data meaningfully "about" the user beyond what the other fields
 * already summarize. [PENDIENTE: confirm this scoping with the data
 * protection advisor — see docs/business/records-of-processing-activities.md.]
 */
async function handleExportUserDataUnsafe(req: Request, deps: HandlerDeps): Promise<Response> {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const caller = await deps.getCaller(req.headers.get("Authorization"));
  if (!caller) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }
  if (!isRealAccount(caller)) {
    return jsonResponse(
      { error: "A real account is required to export your data." },
      403,
    );
  }
  const userId = caller.id;

  if (await deps.isRateLimited(userId)) {
    return jsonResponse({ error: "Too many requests. Try again later." }, 429);
  }

  const data = await deps.buildExport(userId);
  return jsonResponse(data, 200);
}
