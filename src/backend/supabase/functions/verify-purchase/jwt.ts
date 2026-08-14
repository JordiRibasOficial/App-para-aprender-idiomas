// Minimal JWT signing shared by the Google Play (RS256) and Apple App Store
// Server API (ES256) verifiers — both need "sign a claims object with a
// service credential's private key" and nothing else from a JWT library, so
// a small hand-rolled helper avoids pulling in a full npm JWT package for
// two call sites.

function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function decodeBase64Pem(pem: string): ArrayBuffer {
  const body = pem.replace(/-----BEGIN [^-]+-----/, "").replace(/-----END [^-]+-----/, "").replace(
    /\s+/g,
    "",
  );
  const binary = atob(body);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

export function importPkcs8Key(
  pem: string,
  algorithm: RsaHashedImportParams | EcKeyImportParams,
): Promise<CryptoKey> {
  return crypto.subtle.importKey("pkcs8", decodeBase64Pem(pem), algorithm, false, ["sign"]);
}

/** Signs `claims` as a compact JWS using `key`/`signAlgorithm`, with `header` merged in. */
export async function signJwt(
  header: Record<string, unknown>,
  claims: Record<string, unknown>,
  key: CryptoKey,
  signAlgorithm: AlgorithmIdentifier | RsaPssParams | EcdsaParams,
): Promise<string> {
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const signature = await crypto.subtle.sign(
    signAlgorithm,
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64url(new Uint8Array(signature))}`;
}

/** Decodes a JWS payload without verifying its signature — see call sites for why that's safe there. */
export function decodeJwsPayloadUnverified(jws: string): Record<string, unknown> {
  const [, payload] = jws.split(".");
  if (!payload) throw new Error("Malformed JWS: no payload segment");
  const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(normalized.length + ((4 - (normalized.length % 4)) % 4), "=");
  return JSON.parse(atob(padded));
}
