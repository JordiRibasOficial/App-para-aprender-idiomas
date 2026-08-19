import { assertEquals } from "@std/assert";

import { handleVerifyPurchase } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
import type { Platform, PurchaseVerifier, SubscriptionUpsert, VerifyPurchaseInput } from "./types.ts";

class FakeVerifier implements PurchaseVerifier {
  constructor(
    private readonly result: { isActive: boolean; expiresAt: string | null } = {
      isActive: true,
      expiresAt: "2030-01-01T00:00:00.000Z",
    },
    private readonly error: Error | null = null,
  ) {}

  verify(_input: VerifyPurchaseInput) {
    if (this.error) return Promise.reject(this.error);
    return Promise.resolve({ ...this.result, raw: { fake: true } });
  }
}

function buildDeps(overrides: Partial<HandlerDeps> = {}): {
  deps: HandlerDeps;
  upserts: SubscriptionUpsert[];
} {
  const upserts: SubscriptionUpsert[] = [];
  const deps: HandlerDeps = {
    getUserId: (authHeader) => Promise.resolve(authHeader === "Bearer valid-token" ? "user-1" : null),
    isRateLimited: () => Promise.resolve(false),
    verifiers: { android: new FakeVerifier() } as Partial<Record<Platform, PurchaseVerifier>>,
    upsertSubscription: (row) => {
      upserts.push(row);
      return Promise.resolve();
    },
    ...overrides,
  };
  return { deps, upserts };
}

function request(body: unknown, authHeader: string | null = "Bearer valid-token"): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("http://localhost/verify-purchase", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test("rejects requests without a valid auth token, without writing anything", async () => {
  const { deps, upserts } = buildDeps();
  const response = await handleVerifyPurchase(
    request({ platform: "android", productId: "annual_sub", purchaseToken: "tok" }, null),
    deps,
  );

  assertEquals(response.status, 401);
  assertEquals(upserts.length, 0);
});

Deno.test(
  "rejects a rate-limited caller with 429, without calling the verifier or writing anything",
  async () => {
    const { deps, upserts } = buildDeps({ isRateLimited: () => Promise.resolve(true) });
    const response = await handleVerifyPurchase(
      request({ platform: "android", productId: "annual_sub", purchaseToken: "tok" }),
      deps,
    );

    assertEquals(response.status, 429);
    assertEquals(upserts.length, 0);
  },
);

Deno.test("rejects a malformed body", async () => {
  const { deps, upserts } = buildDeps();
  const response = await handleVerifyPurchase(
    request({ platform: "android" /* missing productId/purchaseToken */ }),
    deps,
  );

  assertEquals(response.status, 400);
  assertEquals(upserts.length, 0);
});

Deno.test(
  "rejects a productId outside the known whitelist, without calling the verifier",
  async () => {
    const { deps, upserts } = buildDeps();
    const response = await handleVerifyPurchase(
      request({
        platform: "android",
        // Path-injection attempt: this must never reach the outbound
        // Google/Apple request URL in google_play.ts/apple.ts.
        productId: "../../edits",
        purchaseToken: "tok",
      }),
      deps,
    );

    assertEquals(response.status, 400);
    assertEquals(upserts.length, 0);
  },
);

Deno.test(
  "fails closed with 503 and writes nothing when the platform has no configured verifier",
  async () => {
    const { deps, upserts } = buildDeps();
    const response = await handleVerifyPurchase(
      request({ platform: "ios", productId: "annual_sub", purchaseToken: "tok" }),
      deps,
    );

    assertEquals(response.status, 503);
    assertEquals(upserts.length, 0);
  },
);

Deno.test(
  "a verifier error is surfaced as 502 without leaking the upstream error detail to the client",
  async () => {
    const { deps, upserts } = buildDeps({
      verifiers: {
        android: new FakeVerifier(
          undefined,
          new Error("Google Play verification failed: 401 {\"error\":\"invalid_grant\",\"secret_hint\":\"abc\"}"),
        ),
      },
    });
    const response = await handleVerifyPurchase(
      request({ platform: "android", productId: "annual_sub", purchaseToken: "tok" }),
      deps,
    );
    const body = await response.json();

    assertEquals(response.status, 502);
    assertEquals(upserts.length, 0);
    assertEquals(body, { error: "Verification request to the store failed" });
  },
);

Deno.test("a verifier error is surfaced as 502 and grants nothing", async () => {
  const { deps, upserts } = buildDeps({
    verifiers: { android: new FakeVerifier(undefined, new Error("network down")) },
  });
  const response = await handleVerifyPurchase(
    request({ platform: "android", productId: "annual_sub", purchaseToken: "tok" }),
    deps,
  );

  assertEquals(response.status, 502);
  assertEquals(upserts.length, 0);
});

Deno.test("a positive verification persists an active subscription for the caller", async () => {
  const { deps, upserts } = buildDeps();
  const response = await handleVerifyPurchase(
    request({ platform: "android", productId: "annual_sub", purchaseToken: "tok-abc" }),
    deps,
  );

  assertEquals(response.status, 200);
  const body = await response.json();
  assertEquals(body.status, "active");
  assertEquals(upserts.length, 1);
  assertEquals(upserts[0], {
    userId: "user-1",
    platform: "android",
    productId: "annual_sub",
    storeTransactionId: "tok-abc",
    status: "active",
    expiresAt: "2030-01-01T00:00:00.000Z",
    rawResponse: { fake: true },
  });
});

Deno.test("an expired purchase is persisted as expired, not active", async () => {
  const { deps, upserts } = buildDeps({
    verifiers: { android: new FakeVerifier({ isActive: false, expiresAt: null }) },
  });
  const response = await handleVerifyPurchase(
    request({ platform: "android", productId: "annual_sub", purchaseToken: "tok" }),
    deps,
  );

  assertEquals(response.status, 200);
  const body = await response.json();
  assertEquals(body.status, "expired");
  assertEquals(upserts[0].status, "expired");
});

Deno.test("rejects a GET request", async () => {
  const { deps } = buildDeps();
  const req = new Request("http://localhost/verify-purchase", {
    method: "GET",
    headers: { Authorization: "Bearer valid-token" },
  });
  const response = await handleVerifyPurchase(req, deps);

  assertEquals(response.status, 405);
});

Deno.test("every JSON response sets X-Content-Type-Options: nosniff", async () => {
  const { deps } = buildDeps();
  const response = await handleVerifyPurchase(request({}, null), deps);

  assertEquals(response.status, 401);
  assertEquals(response.headers.get("X-Content-Type-Options"), "nosniff");
});

Deno.test(
  "an OPTIONS preflight gets a bare 204 with no Access-Control-Allow-Origin — this endpoint has no browser client to allow",
  async () => {
    const { deps } = buildDeps();
    const req = new Request("http://localhost/verify-purchase", {
      method: "OPTIONS",
      headers: { Origin: "https://evil.example" },
    });
    const response = await handleVerifyPurchase(req, deps);

    assertEquals(response.status, 204);
    assertEquals(response.headers.get("Access-Control-Allow-Origin"), null);
  },
);
