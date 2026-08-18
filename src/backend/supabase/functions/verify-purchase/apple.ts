import type { PurchaseVerifier, VerificationResult, VerifyPurchaseInput } from "./types.ts";
import { decodeJwsPayloadUnverified, importPkcs8Key, signJwt } from "./jwt.ts";

// See google_play.ts's FETCH_TIMEOUT_MS doc comment — same reasoning here.
const FETCH_TIMEOUT_MS = 10_000;

export interface AppleCredentials {
  keyId: string;
  issuerId: string;
  /** PEM contents of the .p8 App Store Connect API key. */
  privateKey: string;
  bundleId: string;
  environment: "sandbox" | "production";
}

async function signAppStoreConnectJwt(credentials: AppleCredentials): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const key = await importPkcs8Key(credentials.privateKey, { name: "ECDSA", namedCurve: "P-256" });
  return signJwt(
    { alg: "ES256", kid: credentials.keyId, typ: "JWT" },
    {
      iss: credentials.issuerId,
      iat: now,
      exp: now + 60 * 10, // Apple caps this at 60 min; 10 is plenty for one request.
      aud: "appstoreconnect-v1",
      bid: credentials.bundleId,
    },
    key,
    { name: "ECDSA", hash: "SHA-256" },
  );
}

interface TransactionResponse {
  signedTransactionInfo: string;
}

interface DecodedTransaction {
  expiresDate?: number;
  revocationDate?: number;
}

/**
 * Verifies an iOS subscription transaction server-to-server against Apple's
 * App Store Server API (https://developer.apple.com/documentation/appstoreserverapi).
 *
 * Known gap: this decodes Apple's `signedTransactionInfo` JWS payload
 * without verifying its signature chain (the `x5c` header) against Apple's
 * root CA. That's an accepted defense-in-depth gap here — not a "this is
 * forgeable" gap — because we fetch this value ourselves, over TLS,
 * directly from Apple's API; an attacker would need to compromise Apple's
 * API or the TLS connection to inject a fake payload, not just guess a
 * signature. It stops being safe to skip if this code is ever reused to
 * verify a JWS handed to us by the client or by Apple's server-to-server
 * notifications webhook (a different trust boundary). Apple's official
 * `app-store-server-library` (Node/Swift/Java/Python — no first-party Deno
 * build) does full chain verification if this needs hardening later.
 */
export class AppleVerifier implements PurchaseVerifier {
  constructor(private readonly credentials: AppleCredentials) {}

  async verify(input: VerifyPurchaseInput): Promise<VerificationResult> {
    const token = await signAppStoreConnectJwt(this.credentials);
    const base = this.credentials.environment === "production"
      ? "https://api.storekit.itunes.apple.com"
      : "https://api.storekit-sandbox.itunes.apple.com";
    // `purchaseToken` carries the App Store transaction id for iOS inputs —
    // validated by VerifyPurchaseInputSchema but still untrusted wire input,
    // so it's encoded here to keep it confined to its path segment.
    const response = await fetch(
      `${base}/inApps/v1/transactions/${encodeURIComponent(input.purchaseToken)}`,
      { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) },
    );
    if (!response.ok) {
      throw new Error(`Apple verification failed: ${response.status} ${await response.text()}`);
    }
    const data = (await response.json()) as TransactionResponse;
    const payload = decodeJwsPayloadUnverified(data.signedTransactionInfo) as DecodedTransaction;

    const revoked = typeof payload.revocationDate === "number";
    const expiresAt = typeof payload.expiresDate === "number" ? payload.expiresDate : null;
    const isActive = !revoked && expiresAt !== null && expiresAt > Date.now();

    return {
      isActive,
      expiresAt: expiresAt ? new Date(expiresAt).toISOString() : null,
      raw: payload,
    };
  }
}
