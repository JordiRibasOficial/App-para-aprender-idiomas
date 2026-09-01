import { assertEquals } from "@std/assert";

import { handleSaveMarketingContact } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
import type { Caller } from "../_shared/auth.ts";

const REAL_CALLER: Caller = {
  id: "user-1",
  email: "ana@example.com",
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
    upsertContact: () => Promise.resolve(),
    ...overrides,
  };
}

function request(
  body: unknown,
  authHeader: string | null = "Bearer valid-token",
): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("http://localhost/save-marketing-contact", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test("rejects requests without a valid auth token", async () => {
  const response = await handleSaveMarketingContact(
    request({ email: "ana@example.com" }, null),
    buildDeps(),
  );
  assertEquals(response.status, 401);
});

Deno.test("rejects an anonymous caller — no email to attach consent to", async () => {
  const deps = buildDeps({
    getCaller: () => Promise.resolve(ANONYMOUS_CALLER),
  });
  const response = await handleSaveMarketingContact(
    request({ email: "ana@example.com" }),
    deps,
  );
  assertEquals(response.status, 403);
});

Deno.test("rejects a submitted email that doesn't match the caller's own account email", async () => {
  let upsertCalled = false;
  const deps = buildDeps({
    upsertContact: () => {
      upsertCalled = true;
      return Promise.resolve();
    },
  });
  const response = await handleSaveMarketingContact(
    request({ email: "someone-else@example.com" }),
    deps,
  );

  assertEquals(response.status, 403);
  assertEquals(upsertCalled, false);
});

Deno.test("accepts a submitted email that matches case-insensitively", async () => {
  const response = await handleSaveMarketingContact(
    request({ email: "ANA@EXAMPLE.COM" }),
    buildDeps(),
  );
  assertEquals(response.status, 200);
});

Deno.test("rejects a rate-limited caller with 429, without saving anything", async () => {
  let upsertCalled = false;
  const deps = buildDeps({
    isRateLimited: () => Promise.resolve(true),
    upsertContact: () => {
      upsertCalled = true;
      return Promise.resolve();
    },
  });
  const response = await handleSaveMarketingContact(
    request({ email: "ana@example.com" }),
    deps,
  );

  assertEquals(response.status, 429);
  assertEquals(upsertCalled, false);
});

Deno.test("rejects an invalid email with 400", async () => {
  const response = await handleSaveMarketingContact(
    request({ email: "not-an-email" }),
    buildDeps(),
  );
  assertEquals(response.status, 400);
});

Deno.test("rejects invalid JSON with 400", async () => {
  const headers = new Headers({
    "Content-Type": "application/json",
    Authorization: "Bearer valid-token",
  });
  const req = new Request("http://localhost/save-marketing-contact", {
    method: "POST",
    headers,
    body: "{not json",
  });
  const response = await handleSaveMarketingContact(req, buildDeps());
  assertEquals(response.status, 400);
});

Deno.test("saves and confirms for a valid caller", async () => {
  let savedWith: { userId: string; email: string } | null = null;
  const deps = buildDeps({
    upsertContact: (input) => {
      savedWith = input;
      return Promise.resolve();
    },
  });
  const response = await handleSaveMarketingContact(
    request({ email: "ana@example.com" }),
    deps,
  );
  const body = await response.json();

  assertEquals(response.status, 200);
  assertEquals(body, { saved: true });
  assertEquals(savedWith, { userId: "user-1", email: "ana@example.com" });
});

Deno.test("a save failure surfaces as a generic 500, not the raw Postgres error", async () => {
  const deps = buildDeps({
    upsertContact: () => Promise.reject(new Error("Failed to save marketing contact: timeout")),
  });
  const response = await handleSaveMarketingContact(
    request({ email: "ana@example.com" }),
    deps,
  );
  const body = await response.json();

  assertEquals(response.status, 500);
  assertEquals(body, { error: "Internal server error" });
});

Deno.test("every JSON response sets X-Content-Type-Options: nosniff", async () => {
  const response = await handleSaveMarketingContact(request({}, null), buildDeps());
  assertEquals(response.headers.get("X-Content-Type-Options"), "nosniff");
});

Deno.test(
  "an OPTIONS preflight gets a bare 204 with no Access-Control-Allow-Origin",
  async () => {
    const req = new Request("http://localhost/save-marketing-contact", {
      method: "OPTIONS",
      headers: { Origin: "https://evil.example" },
    });
    const response = await handleSaveMarketingContact(req, buildDeps());

    assertEquals(response.status, 204);
    assertEquals(response.headers.get("Access-Control-Allow-Origin"), null);
  },
);

Deno.test("rejects a GET request", async () => {
  const req = new Request("http://localhost/save-marketing-contact", {
    method: "GET",
    headers: { Authorization: "Bearer valid-token" },
  });
  const response = await handleSaveMarketingContact(req, buildDeps());
  assertEquals(response.status, 405);
});

Deno.test(
  "rejects a signed-up-but-unconfirmed caller — consent needs a proven address",
  async () => {
    const deps = buildDeps({
      getCaller: () => Promise.resolve(UNCONFIRMED_CALLER),
    });
    const response = await handleSaveMarketingContact(
      request({ email: "unconfirmed@example.com" }),
      deps,
    );
    assertEquals(response.status, 403);
  },
);
