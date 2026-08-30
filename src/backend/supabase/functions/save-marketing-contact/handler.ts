import { corsPreflightResponse, jsonResponse } from "../_shared/http.ts";
import { SaveMarketingContactInputSchema } from "./types.ts";
import type { Caller } from "../_shared/auth.ts";

export interface HandlerDeps {
  /** Resolves the caller's own id and account email, or null if unauthenticated. */
  getCaller(authHeader: string | null): Promise<Caller | null>;
  isRateLimited(userId: string): Promise<boolean>;
  upsertContact(input: { userId: string; email: string }): Promise<void>;
}

/**
 * Entry point Deno.serve calls — same catch-all rationale as the other
 * functions.
 */
export async function handleSaveMarketingContact(
  req: Request,
  deps: HandlerDeps,
): Promise<Response> {
  try {
    return await handleSaveMarketingContactUnsafe(req, deps);
  } catch (error) {
    console.error("save-marketing-contact: unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
}

/**
 * Records LSSICE art. 21 marketing consent for the caller's own account.
 * Two things this deliberately enforces, both load-bearing for why this
 * table can be trusted as real, attributable consent:
 *
 * - The caller must be a real account (a non-null email) — an anonymous
 *   session has no email to attach consent to, so it's rejected rather
 *   than silently accepted with a null identity.
 * - The submitted email must match the caller's own account email — a
 *   signed-in caller can't use this to add a *different* address (a
 *   friend's, a scraped one) to the marketing list.
 */
async function handleSaveMarketingContactUnsafe(
  req: Request,
  deps: HandlerDeps,
): Promise<Response> {
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
  if (!caller.email) {
    return jsonResponse(
      { error: "A real account is required to opt in to marketing email." },
      403,
    );
  }

  if (await deps.isRateLimited(caller.id)) {
    return jsonResponse({ error: "Too many requests. Try again later." }, 429);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const parsed = SaveMarketingContactInputSchema.safeParse(body);
  if (!parsed.success) {
    return jsonResponse({ error: "Invalid request body", detail: parsed.error.flatten() }, 400);
  }

  if (parsed.data.email.toLowerCase() !== caller.email.toLowerCase()) {
    return jsonResponse(
      { error: "email must match the authenticated account's own email" },
      403,
    );
  }

  await deps.upsertContact({ userId: caller.id, email: parsed.data.email });
  return jsonResponse({ saved: true }, 200);
}
