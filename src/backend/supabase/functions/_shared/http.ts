// Shared by every Edge Function in this project — not deployed on its own
// (Supabase's CLI skips directories prefixed with `_`).

export function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      // Most browser-facing security headers (CSP, X-Frame-Options,
      // Referrer-Policy, Permissions-Policy) protect HTML pages from
      // clickjacking/script injection/leaky referrers — these endpoints
      // never serve HTML, so they'd be theater. nosniff is the one
      // exception: it costs nothing and blocks a browser from
      // reinterpreting this JSON body as something executable if it's ever
      // loaded directly (e.g. a phishing page linking straight to the raw
      // endpoint).
      "X-Content-Type-Options": "nosniff",
    },
  });
}

// CORS is a browser-only mechanism — it can't restrict which *app* calls
// these endpoints (mobile clients, curl, another server never send an
// Origin header, so CORS doesn't apply to them at all). The actual access
// control is each function's own Bearer-token check plus rate limiting
// where relevant. Their only client is the Flutter app, which never runs
// inside a browser origin, so there is no legitimate Origin to allow —
// omitting Access-Control-Allow-Origin entirely means any browser-based
// caller (e.g. a malicious page trying to reuse a leaked anon key from a
// victim's session) gets its request blocked by the browser itself before
// this code ever sees the response. Deno.serve's default response to an
// OPTIONS preflight would otherwise fall through to a 405 with no CORS
// headers, which browsers already treat as a deny — this makes that denial
// explicit instead of incidental.
export function corsPreflightResponse(): Response {
  return new Response(null, { status: 204 });
}
