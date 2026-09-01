import { assertEquals } from "@std/assert";

import { handleGetCourseContent } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
import type { PremiumLanguage } from "./types.ts";
import type { Caller } from "../_shared/auth.ts";

const REAL_CALLER: Caller = {
  id: "user-1",
  email: "user@example.com",
  isAnonymous: false,
  isEmailConfirmed: true,
};
const ANONYMOUS_CALLER: Caller = {
  id: "anon-1",
  email: null,
  isAnonymous: true,
  isEmailConfirmed: false,
};
/// Signed up but never proved the address is theirs — not a usable identity.
const UNCONFIRMED_CALLER: Caller = {
  id: "unconfirmed-1",
  email: "unconfirmed@example.com",
  isAnonymous: false,
  isEmailConfirmed: false,
};

const FAKE_CONTENT: Record<PremiumLanguage, unknown> = {
  pt: { sourceLanguage: "es", targetLanguage: "pt", fake: true },
  fr: { sourceLanguage: "es", targetLanguage: "fr", fake: true },
  ja: { sourceLanguage: "es", targetLanguage: "ja", fake: true },
};

function buildDeps(overrides: Partial<HandlerDeps> = {}): HandlerDeps {
  return {
    getCaller: (authHeader) =>
      Promise.resolve(authHeader === "Bearer valid-token" ? REAL_CALLER : null),
    isRateLimited: () => Promise.resolve(false),
    hasActivePremium: () => Promise.resolve(true),
    courseContent: FAKE_CONTENT,
    ...overrides,
  };
}

function request(body: unknown, authHeader: string | null = "Bearer valid-token"): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("http://localhost/get-course-content", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test("rejects requests without a valid auth token", async () => {
  const response = await handleGetCourseContent(
    request({ targetLanguage: "pt" }, null),
    buildDeps(),
  );
  assertEquals(response.status, 401);
});

Deno.test("rejects an anonymous caller — no account to attach Premium access to", async () => {
  const deps = buildDeps({ getCaller: () => Promise.resolve(ANONYMOUS_CALLER) });
  const response = await handleGetCourseContent(request({ targetLanguage: "pt" }), deps);
  assertEquals(response.status, 403);
});

Deno.test(
  "rejects a rate-limited caller with 429, without checking premium or leaking course content",
  async () => {
    const deps = buildDeps({ isRateLimited: () => Promise.resolve(true) });
    const response = await handleGetCourseContent(request({ targetLanguage: "pt" }), deps);
    assertEquals(response.status, 429);
  },
);

Deno.test(
  "a rate-limit check failure surfaces as a generic 500, not the raw Postgres error",
  async () => {
    const deps = buildDeps({
      isRateLimited: () => Promise.reject(new Error("Rate limit check failed: connection refused")),
    });
    const response = await handleGetCourseContent(request({ targetLanguage: "pt" }), deps);
    const body = await response.json();

    assertEquals(response.status, 500);
    assertEquals(body, { error: "Internal server error" });
  },
);

Deno.test("rejects a malformed body", async () => {
  const response = await handleGetCourseContent(request({}), buildDeps());
  assertEquals(response.status, 400);
});

Deno.test("rejects a targetLanguage outside the premium catalogue (including 'en', which is free/bundled)", async () => {
  const response = await handleGetCourseContent(request({ targetLanguage: "en" }), buildDeps());
  assertEquals(response.status, 400);
});

Deno.test("rejects a non-Premium caller with 403, without leaking any course content", async () => {
  const deps = buildDeps({ hasActivePremium: () => Promise.resolve(false) });
  const response = await handleGetCourseContent(request({ targetLanguage: "pt" }), deps);
  const body = await response.json();

  assertEquals(response.status, 403);
  assertEquals(body, { error: "An active Premium subscription is required" });
});

Deno.test("returns the requested course for an active Premium caller", async () => {
  const response = await handleGetCourseContent(request({ targetLanguage: "fr" }), buildDeps());
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body, FAKE_CONTENT.fr);
});

Deno.test("a Premium-check failure surfaces as a generic 500, not the raw Postgres error", async () => {
  const deps = buildDeps({
    hasActivePremium: () => Promise.reject(new Error("Premium check failed: connection refused")),
  });
  const response = await handleGetCourseContent(request({ targetLanguage: "pt" }), deps);
  const body = await response.json();

  assertEquals(response.status, 500);
  assertEquals(body, { error: "Internal server error" });
});

Deno.test("every JSON response sets X-Content-Type-Options: nosniff", async () => {
  const response = await handleGetCourseContent(request({}, null), buildDeps());
  assertEquals(response.headers.get("X-Content-Type-Options"), "nosniff");
});

Deno.test(
  "an OPTIONS preflight gets a bare 204 with no Access-Control-Allow-Origin — this endpoint has no browser client to allow",
  async () => {
    const req = new Request("http://localhost/get-course-content", {
      method: "OPTIONS",
      headers: { Origin: "https://evil.example" },
    });
    const response = await handleGetCourseContent(req, buildDeps());

    assertEquals(response.status, 204);
    assertEquals(response.headers.get("Access-Control-Allow-Origin"), null);
  },
);

Deno.test("rejects a GET request", async () => {
  const req = new Request("http://localhost/get-course-content", {
    method: "GET",
    headers: { Authorization: "Bearer valid-token" },
  });
  const response = await handleGetCourseContent(req, buildDeps());
  assertEquals(response.status, 405);
});

Deno.test("rejects a signed-up-but-unconfirmed caller — not a proven identity", async () => {
  const deps = buildDeps({ getCaller: () => Promise.resolve(UNCONFIRMED_CALLER) });
  const response = await handleGetCourseContent(request({ targetLanguage: "pt" }), deps);
  assertEquals(response.status, 403);
});
