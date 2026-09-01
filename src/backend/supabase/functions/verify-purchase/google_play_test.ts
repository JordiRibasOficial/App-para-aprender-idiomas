import { assertEquals } from "@std/assert";

import { isSubscriptionActive } from "./google_play.ts";

const FUTURE = "4102444800000"; // 2100-01-01
const PAST = "1000000000000"; // 2001-09-09
const NOW = Date.parse("2026-09-01T00:00:00.000Z");

Deno.test("a paid subscription with a future expiry is active", () => {
  assertEquals(
    isSubscriptionActive({ expiryTimeMillis: FUTURE, paymentState: 1 }, NOW),
    true,
  );
});

Deno.test("an active free trial is active — Play granted it deliberately", () => {
  assertEquals(
    isSubscriptionActive({ expiryTimeMillis: FUTURE, paymentState: 2 }, NOW),
    true,
  );
});

Deno.test(
  "a PENDING payment is NOT active, despite carrying a future expiry",
  () => {
    // The regression this locks down: Play issues paymentState 0 with a
    // normal future expiryTimeMillis for payment methods that settle later.
    // Deciding on expiry alone handed full Premium to purchases we had not
    // actually been paid for.
    assertEquals(
      isSubscriptionActive({ expiryTimeMillis: FUTURE, paymentState: 0 }, NOW),
      false,
    );
  },
);

Deno.test("a deferred pending upgrade/downgrade is not treated as paid", () => {
  assertEquals(
    isSubscriptionActive({ expiryTimeMillis: FUTURE, paymentState: 3 }, NOW),
    false,
  );
});

Deno.test(
  "an absent paymentState fails closed — Play omits it for cancelled/expired subs",
  () => {
    assertEquals(isSubscriptionActive({ expiryTimeMillis: FUTURE }, NOW), false);
  },
);

Deno.test("a paid subscription whose expiry has passed is not active", () => {
  assertEquals(
    isSubscriptionActive({ expiryTimeMillis: PAST, paymentState: 1 }, NOW),
    false,
  );
});

Deno.test("a paid subscription with no expiry at all is not active", () => {
  assertEquals(isSubscriptionActive({ paymentState: 1 }, NOW), false);
});
