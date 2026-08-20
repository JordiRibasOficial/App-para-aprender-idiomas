import { corsPreflightResponse, jsonResponse } from "../_shared/http.ts";
import { GetCourseContentInputSchema } from "./types.ts";
import type { PremiumLanguage } from "./types.ts";

export interface HandlerDeps {
  /** Resolves the caller's user id from the request's Authorization header, or null if unauthenticated. */
  getUserId(authHeader: string | null): Promise<string | null>;
  /**
   * Records this call as a request for `userId` and reports whether
   * they've exceeded the allowed rate — true means reject with 429. Called
   * once per request, after auth succeeds, before the premium check.
   */
  isRateLimited(userId: string): Promise<boolean>;
  /** Whether `userId` has a currently-active (unexpired) subscription row. */
  hasActivePremium(userId: string): Promise<boolean>;
  /** The 3 Premium course JSON blobs, keyed by language — see index.ts for how these are loaded. */
  courseContent: Record<PremiumLanguage, unknown>;
}

/**
 * Entry point Deno.serve calls. Wraps the real logic below in a catch-all —
 * same rationale as verify-purchase/handler.ts: the Premium check throws a
 * raw Postgres error message on failure, and this keeps that off the client.
 */
export async function handleGetCourseContent(req: Request, deps: HandlerDeps): Promise<Response> {
  try {
    return await handleGetCourseContentUnsafe(req, deps);
  } catch (error) {
    console.error("get-course-content: unhandled error", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
}

/**
 * Serves premium (pt/fr/ja) course content only to callers with an active
 * subscription. This exists because the mobile app used to bundle every
 * course — including the Premium-gated ones — directly in the APK/IPA,
 * with only a client-side boolean deciding whether the onboarding UI let a
 * user pick a Premium language. That content was sitting on every device
 * regardless of payment status; a patched build (no root required, just a
 * decompile-and-repackage) could flip the check and read it for free. This
 * function is the fix: the content itself now lives only here, and never
 * reaches a device that hasn't been verified server-side as Premium.
 */
async function handleGetCourseContentUnsafe(req: Request, deps: HandlerDeps): Promise<Response> {
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

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const parsed = GetCourseContentInputSchema.safeParse(body);
  if (!parsed.success) {
    return jsonResponse({ error: "Invalid request body", detail: parsed.error.flatten() }, 400);
  }

  if (!(await deps.hasActivePremium(userId))) {
    return jsonResponse({ error: "An active Premium subscription is required" }, 403);
  }

  return jsonResponse(deps.courseContent[parsed.data.targetLanguage], 200);
}
