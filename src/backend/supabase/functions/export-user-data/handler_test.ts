import { assertEquals } from "@std/assert";

import { handleExportUserData } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
import type { UserDataExport } from "./types.ts";
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

const FAKE_EXPORT: UserDataExport = {
  userId: "user-1",
  exportedAt: "2026-08-19T00:00:00.000Z",
  subscriptions: [
    {
      platform: "android",
      productId: "annual_sub",
      status: "active",
      verifiedAt: "2026-08-01T00:00:00.000Z",
      expiresAt: "2027-08-01T00:00:00.000Z",
      createdAt: "2026-08-01T00:00:00.000Z",
    },
  ],
  verificationAttempts: [{ createdAt: "2026-08-01T00:00:00.000Z" }],
};

function buildDeps(overrides: Partial<HandlerDeps> = {}): HandlerDeps {
  return {
    getCaller: (authHeader) =>
      Promise.resolve(authHeader === "Bearer valid-token" ? REAL_CALLER : null),
    isRateLimited: () => Promise.resolve(false),
    buildExport: () => Promise.resolve(FAKE_EXPORT),
    ...overrides,
  };
}

function request(authHeader: string | null = "Bearer valid-token"): Request {
  const headers = new Headers();
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("http://localhost/export-user-data", { method: "POST", headers });
}

Deno.test("rejects requests without a valid auth token", async () => {
  const response = await handleExportUserData(request(null), buildDeps());
  assertEquals(response.status, 401);
});

Deno.test("rejects an anonymous caller — no account to export data for", async () => {
  const deps = buildDeps({ getCaller: () => Promise.resolve(ANONYMOUS_CALLER) });
  const response = await handleExportUserData(request(), deps);
  assertEquals(response.status, 403);
});

Deno.test("rejects a rate-limited caller with 429, without building an export", async () => {
  let buildExportCalled = false;
  const deps = buildDeps({
    isRateLimited: () => Promise.resolve(true),
    buildExport: () => {
      buildExportCalled = true;
      return Promise.resolve(FAKE_EXPORT);
    },
  });
  const response = await handleExportUserData(request(), deps);

  assertEquals(response.status, 429);
  assertEquals(buildExportCalled, false);
});

Deno.test(
  "a rate-limit check failure surfaces as a generic 500, not the raw Postgres error",
  async () => {
    const deps = buildDeps({
      isRateLimited: () => Promise.reject(new Error("Rate limit check failed: connection refused")),
    });
    const response = await handleExportUserData(request(), deps);
    const body = await response.json();

    assertEquals(response.status, 500);
    assertEquals(body, { error: "Internal server error" });
  },
);

Deno.test("returns the caller's own export for a valid caller", async () => {
  const response = await handleExportUserData(request(), buildDeps());
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body, FAKE_EXPORT);
});

Deno.test("buildExport is called with the authenticated caller's own userId, not an attacker-supplied one", async () => {
  let calledWith: string | null = null;
  const deps = buildDeps({
    buildExport: (userId) => {
      calledWith = userId;
      return Promise.resolve(FAKE_EXPORT);
    },
  });

  await handleExportUserData(request(), deps);

  assertEquals(calledWith, "user-1");
});

Deno.test("a query failure surfaces as a generic 500, not the raw Postgres error", async () => {
  const deps = buildDeps({
    buildExport: () =>
      Promise.reject(new Error("Failed to read subscriptions: connection refused")),
  });
  const response = await handleExportUserData(request(), deps);
  const body = await response.json();

  assertEquals(response.status, 500);
  assertEquals(body, { error: "Internal server error" });
});

Deno.test("every JSON response sets X-Content-Type-Options: nosniff", async () => {
  const response = await handleExportUserData(request(null), buildDeps());
  assertEquals(response.headers.get("X-Content-Type-Options"), "nosniff");
});

Deno.test(
  "an OPTIONS preflight gets a bare 204 with no Access-Control-Allow-Origin — this endpoint has no browser client to allow",
  async () => {
    const req = new Request("http://localhost/export-user-data", {
      method: "OPTIONS",
      headers: { Origin: "https://evil.example" },
    });
    const response = await handleExportUserData(req, buildDeps());

    assertEquals(response.status, 204);
    assertEquals(response.headers.get("Access-Control-Allow-Origin"), null);
  },
);

Deno.test("rejects a GET request", async () => {
  const req = new Request("http://localhost/export-user-data", {
    method: "GET",
    headers: { Authorization: "Bearer valid-token" },
  });
  const response = await handleExportUserData(req, buildDeps());
  assertEquals(response.status, 405);
});

Deno.test("rejects a signed-up-but-unconfirmed caller — not a proven identity", async () => {
  const deps = buildDeps({ getCaller: () => Promise.resolve(UNCONFIRMED_CALLER) });
  const response = await handleExportUserData(request(), deps);
  assertEquals(response.status, 403);
});
