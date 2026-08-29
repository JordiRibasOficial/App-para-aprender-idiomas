import { z } from "zod";

// Must match SubscriptionPlan.monthlyProductId / .annualProductId in
// src/mobile/lib/domain/models/subscription_plan.dart — those are the only
// product ids the store can ever hand back to this endpoint. Restricting to
// this whitelist (instead of accepting any non-empty string) also closes a
// path-injection route: productId gets spliced into the outbound Google/Apple
// API URL in google_play.ts/apple.ts, so an unbounded value could redirect
// that authenticated, privileged request to a different API endpoint.
const KNOWN_PRODUCT_IDS = ["monthly_sub", "annual_sub"] as const;

export const VerifyPurchaseInputSchema = z.object({
  platform: z.enum(["android", "ios"]),
  productId: z.enum(KNOWN_PRODUCT_IDS),
  // Android: the purchase token from Play Billing.
  // iOS: the App Store transaction id (StoreKit 2's `transactionId`).
  // Bounded and, like productId, URL-encoded before use (see
  // google_play.ts/apple.ts) — this is store-issued but still untrusted
  // input arriving over the wire.
  purchaseToken: z.string().min(1).max(4096),
  // Optional — only present if the user gave an email during onboarding
  // (see OnboardingState.email in the mobile app; guest users send none).
  // Used once, in this same request, to send the durable-medium purchase
  // confirmation TRLGDCU arts. 98.7/99.2 require (see handler.ts) — never
  // persisted. This is the one place in the whole backend that receives an
  // email address; every other table only ever sees the anonymous user id.
  email: z.string().email().max(320).optional(),
});

export type Platform = z.infer<typeof VerifyPurchaseInputSchema>["platform"];
export type VerifyPurchaseInput = z.infer<typeof VerifyPurchaseInputSchema>;

export interface VerificationResult {
  isActive: boolean;
  expiresAt: string | null;
  /** Raw provider response, stored for support/audit — never shown to the client as-is. */
  raw: unknown;
}

export interface PurchaseVerifier {
  verify(input: VerifyPurchaseInput): Promise<VerificationResult>;
}

export interface SubscriptionUpsert {
  userId: string;
  platform: Platform;
  productId: string;
  storeTransactionId: string;
  status: "active" | "expired";
  expiresAt: string | null;
  rawResponse: unknown;
}
