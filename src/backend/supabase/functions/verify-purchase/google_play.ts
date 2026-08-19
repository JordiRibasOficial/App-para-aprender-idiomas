import type { PurchaseVerifier, VerificationResult, VerifyPurchaseInput } from "./types.ts";
import { importPkcs8Key, signJwt } from "./jwt.ts";

// Deno's fetch has no default timeout — an outbound call that hangs would
// otherwise hold the invocation open until the platform's own function
// timeout kills it, wasting a rate-limit slot and leaving the mobile app
// waiting far longer than necessary for what should be a quick check.
const FETCH_TIMEOUT_MS = 10_000;

export interface GoogleServiceAccount {
  client_email: string;
  private_key: string;
}

async function getAccessToken(serviceAccount: GoogleServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const key = await importPkcs8Key(serviceAccount.private_key, {
    name: "RSASSA-PKCS1-v1_5",
    hash: "SHA-256",
  });
  const assertion = await signJwt(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    },
    key,
    "RSASSA-PKCS1-v1_5",
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });
  if (!response.ok) {
    throw new Error(
      `Google OAuth token exchange failed: ${response.status} ${await response.text()}`,
    );
  }
  const data = (await response.json()) as { access_token: string };
  return data.access_token;
}

interface SubscriptionPurchaseResponse {
  expiryTimeMillis?: string;
  paymentState?: number;
}

/**
 * Verifies an Android subscription purchase server-to-server against the
 * Google Play Developer API, using a service account's OAuth2 JWT bearer
 * flow — the standard flow documented at
 * https://developers.google.com/android-publisher/authorization.
 */
export class GooglePlayVerifier implements PurchaseVerifier {
  constructor(
    private readonly serviceAccount: GoogleServiceAccount,
    private readonly packageName: string,
  ) {}

  async verify(input: VerifyPurchaseInput): Promise<VerificationResult> {
    const accessToken = await getAccessToken(this.serviceAccount);
    // productId/purchaseToken are validated by VerifyPurchaseInputSchema but
    // still untrusted, attacker-influenced wire input — encode them so
    // neither can break out of its path segment and redirect this
    // authenticated, service-account-privileged request elsewhere.
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${encodeURIComponent(this.packageName)}/purchases/subscriptions/` +
      `${encodeURIComponent(input.productId)}/tokens/${encodeURIComponent(input.purchaseToken)}`;
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });
    if (!response.ok) {
      throw new Error(`Google Play verification failed: ${response.status} ${await response.text()}`);
    }
    const data = (await response.json()) as SubscriptionPurchaseResponse;
    const expiryTimeMillis = data.expiryTimeMillis ? Number(data.expiryTimeMillis) : null;
    const isActive = expiryTimeMillis !== null && expiryTimeMillis > Date.now();
    return {
      isActive,
      expiresAt: expiryTimeMillis ? new Date(expiryTimeMillis).toISOString() : null,
      raw: data,
    };
  }
}
