import { z } from "zod";

export const VerifyPurchaseInputSchema = z.object({
  platform: z.enum(["android", "ios"]),
  productId: z.string().min(1),
  // Android: the purchase token from Play Billing.
  // iOS: the App Store transaction id (StoreKit 2's `transactionId`).
  purchaseToken: z.string().min(1),
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
