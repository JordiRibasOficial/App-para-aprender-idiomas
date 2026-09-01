import { assertEquals } from "@std/assert";

import { handleDeleteUserData } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
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

function buildDeps(overrides: Partial<HandlerDeps> = {}): HandlerDeps {
  return {
    getCaller: (authHeader) =>
      Promise.resolve(authHeader === "Bearer valid-token" ? REAL_CALLER : null),
    isRateLimited: () => Promise.resolve(false),
    deleteUser: () => Promise.resolve(),
    ...overrides,
  };
}

function request(authHeader: string | null = "Bearer valid-token"): Request {
  const headers = new Headers();
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("http://localhost/delete-user-data", { method: "POST", headers });
}

Deno.test("rejects requests without a valid auth token", async () => {
  const response = await handleDeleteUserData(request(null), buildDeps());
  assertEquals(response.status, 401);
});

Deno.test("rejects an anonymous caller — no account to delete", async () => {
  const deps = buildDeps({ getCaller: () => Promise.resolve(ANONYMOUS_CALLER) });
  const response = await handleDeleteUserData(request(), deps);
  assertEquals(response.status, 403);
});

Deno.test("rejects a rate-limited caller with 429, without deleting anything", async () => {
  let deleteUserCalled = false;
  const deps = buildDeps({
    isRateLimited: () => Promise.resolve(true),
    deleteUser: () => {
      deleteUserCalled = true;
      return Promise.resolve();
    },
  });
  const response = await handleDeleteUserData(request(), deps);

  assertEquals(response.status, 429);
  assertEquals(deleteUserCalled, false);
});

Deno.test(
  "a rate-limit check failure surfaces as a generic 500, not the raw Postgres error",
  async () => {
    const deps = buildDeps({
      isRateLimited: () => Promise.reject(new Error("Rate limit check failed: connection refused")),
    });
    const response = await handleDeleteUserData(request(), deps);
    const body = await response.json();

    assertEquals(response.status, 500);
    assertEquals(body, { error: "Internal server error" });
  },
);

Deno.test("deletes and confirms for a valid caller", async () => {
  const response = await handleDeleteUserData(request(), buildDeps());
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body, { deleted: true });
});

Deno.test("deleteUser is called with the authenticated caller's own userId, not an attacker-supplied one", async () => {
  let calledWith: string | null = null;
  const deps = buildDeps({
    deleteUser: (userId) => {
      calledWith = userId;
      return Promise.resolve();
    },
  });

  await handleDeleteUserData(request(), deps);

  assertEquals(calledWith, "user-1");
});

Deno.test("a deletion failure surfaces as a generic 500, not the raw Admin API error", async () => {
  const deps = buildDeps({
    deleteUser: () => Promise.reject(new Error("Failed to delete user: connection refused")),
  });
  const response = await handleDeleteUserData(request(), deps);
  const body = await response.json();

  assertEquals(response.status, 500);
  assertEquals(body, { error: "Internal server error" });
});

Deno.test("every JSON response sets X-Content-Type-Options: nosniff", async () => {
  const response = await handleDeleteUserData(request(null), buildDeps());
  assertEquals(response.headers.get("X-Content-Type-Options"), "nosniff");
});

Deno.test(
  "an OPTIONS preflight gets a bare 204 with no Access-Control-Allow-Origin — this endpoint has no browser client to allow",
  async () => {
    const req = new Request("http://localhost/delete-user-data", {
      method: "OPTIONS",
      headers: { Origin: "https://evil.example" },
    });
    const response = await handleDeleteUserData(req, buildDeps());

    assertEquals(response.status, 204);
    assertEquals(response.headers.get("Access-Control-Allow-Origin"), null);
  },
);

Deno.test("rejects a GET request", async () => {
  const req = new Request("http://localhost/delete-user-data", {
    method: "GET",
    headers: { Authorization: "Bearer valid-token" },
  });
  const response = await handleDeleteUserData(req, buildDeps());
  assertEquals(response.status, 405);
});

Deno.test("rejects a signed-up-but-unconfirmed caller — not a proven identity", async () => {
  let deleteUserCalled = false;
  const deps = buildDeps({
    getCaller: () => Promise.resolve(UNCONFIRMED_CALLER),
    deleteUser: () => {
      deleteUserCalled = true;
      return Promise.resolve();
    },
  });
  const response = await handleDeleteUserData(request(), deps);
  assertEquals(response.status, 403);
  assertEquals(deleteUserCalled, false);
});
