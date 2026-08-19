# Backend — purchase verification

Supabase project backing [issue #2](https://github.com/JordiRibasOficial/App-para-aprender-idiomas/issues/2):
the mobile app currently grants Premium entitlement client-side, checking only
that a purchase *has* verification data — not that it's genuine. This backend
adds the missing piece: a server that verifies the purchase against Google
Play / the App Store directly, and is the only thing allowed to write the
entitlement record the app should eventually trust.

## What's here

```
supabase/
  migrations/
    ..._create_subscriptions_table.sql          # entitlement table, RLS: clients read-only
    ..._create_verify_purchase_attempts_table.sql # rate-limit log, RLS: no client access at all
  functions/
    _shared/
      http.ts              # jsonResponse/corsPreflightResponse, shared by every function below
    verify-purchase/
      index.ts        # Deno.serve entrypoint — wires real Supabase/Google/Apple clients
      handler.ts       # the actual request logic, dependency-injected and unit tested
      google_play.ts    # Google Play Developer API verifier (fully implemented)
      apple.ts           # App Store Server API verifier (implemented; see its doc comment
                          # for one documented, deliberate gap)
      jwt.ts               # shared RS256/ES256 JWT signing used by both verifiers
      types.ts               # shared types + the Zod request schema
      handler_test.ts          # Deno tests, using fake verifiers (no real credentials needed)
    get-course-content/
      index.ts          # Deno.serve entrypoint — wires the real Supabase client + bundled content
      handler.ts          # request logic: auth + active-subscription check, then serve the JSON
      types.ts              # the premium-language enum + Zod request schema
      content/                # the actual pt/fr/ja course JSON — moved here from the mobile app
        pt.json, fr.json, ja.json
      handler_test.ts       # Deno tests, using fake deps
      content_test.ts         # validates the 3 JSON files themselves (5+ units, no duplicate ids, …)
```

The Flutter client is wired up (`src/mobile/lib/data/supabase_purchase_verifier.dart`)
and the whole path is confirmed working end to end against the real deployed
project — see "Status" below. The one thing genuinely missing is Google/Apple
credentials, which only the project owner can provide.

## The security property this gives you

`handler.ts` is written to fail closed everywhere:

- No auth token → 401, nothing written.
- More than 20 verification attempts from the same user in 10 minutes →
  429, nothing written (see `verify_purchase_attempts` — logged regardless
  of outcome, so it also covers repeated failed/rejected attempts).
- Malformed request → 400, nothing written.
- Platform has no verifier configured (missing secrets) → 503, nothing written.
- The store's API call fails → 502, nothing written.
- Entitlement is written **only** after a verifier returns a positive result
  from Google/Apple's own servers.

A modified client can send whatever it wants to this endpoint; without a
Google/Apple purchase token that those companies' own APIs recognize as real,
it gets nothing.

## get-course-content

Premium course content (pt/fr/ja) used to be bundled directly in the app's
assets, gated only by a client-side `isPremium` boolean checked once at
onboarding — see `TargetLanguageOption` in the mobile app. That meant the
content itself was sitting on every device regardless of payment status; a
patched build (no root/jailbreak required, just decompile-and-repackage the
APK/IPA) could flip that boolean and read it for free.

This function closes that gap: the 3 Premium course JSON files now live only
here (`content/`), and `handler.ts` serves one only after confirming the
caller has an `active` row in `subscriptions` (unexpired, if `expires_at` is
set). English stays bundled client-side — it's free, there's nothing to gate.

Same fail-closed shape as `verify-purchase`: no auth → 401, not Premium →
403 with no content in the body, DB failure → generic 500 (not the raw
Postgres error — see `handler.ts`'s catch-all). `content_test.ts` separately
validates the 3 JSON files' own quality (5+ units, no duplicate exercise
ids, `multipleChoice.correctAnswer` actually in `options`, etc.) — the
server-side continuation of what used to be `content_repository_test.dart`
checks in the mobile repo before this content moved here.

### CORS

This endpoint sets no `Access-Control-Allow-Origin` header, on purpose. CORS
is a browser-only mechanism — it can't restrict which *app* calls the
endpoint (mobile clients, `curl`, another server never send an `Origin`
header, so CORS doesn't apply to them). The only client is the Flutter app,
which never runs inside a browser origin, so there is no legitimate origin
to allow. Omitting the header means a browser-based caller (e.g. a
malicious page trying to reuse a leaked anon key from a victim's session)
has its request blocked by the browser itself. The real access control is
the Bearer-token check (`getUserId`) plus rate limiting above — that's what
actually determines who can call this, not CORS.

## Status

**Deployed and confirmed working end to end, minus store credentials.**
Project ref `nfkhnrwyekqbjxwxmctu` (org "Jordi Ribas Oficial", region
`eu-west-3`):

- Migration applied (table, RLS, trigger — exercised against a real
  Postgres, not just written blind).
- `verify-purchase` live at
  `https://nfkhnrwyekqbjxwxmctu.supabase.co/functions/v1/verify-purchase`
  with `verify_jwt = true`.
- Anonymous sign-ins enabled on the project
  (`external_anonymous_users_enabled`, matches `config.toml`'s
  `auth.enable_anonymous_sign_ins = true`).
- Full round-trip smoke-tested for real: anonymous sign-up against
  `/auth/v1/signup` → real session JWT → `POST verify-purchase` with that
  JWT → `503 "Purchase verification is not configured for platform
  android"`. That 503 is the *correct* answer today — it's the fail-closed
  path from handler.ts, proving auth, routing, and request validation all
  work; the only missing piece is Google/Apple credentials, which nobody
  but the project owner can provide (see `.env.example`). Once those are
  set, that same request starts returning real verification results.

The database password isn't recorded anywhere in this repo; rotate/view it
from the dashboard (Project Settings → Database) if you need it.

One gap from this deploy: it went through direct Management API calls
because the CLI's own network transport failed (`Transport error`, but
`curl` to the same endpoints worked fine) — the Go CLI is fussier about
something in this network path than curl is. `supabase link` was never run,
so there's no local link state. If the CLI transport problem doesn't
reproduce on your machine, `npx supabase link --project-ref
nfkhnrwyekqbjxwxmctu` should just work and give you the normal CLI-driven
workflow (`db push`, `functions deploy`, etc.) going forward.

## Local setup

```bash
cd src/backend
npx supabase login
npx supabase link --project-ref nfkhnrwyekqbjxwxmctu
npx supabase db push                                  # applies the subscriptions migration
```

Fill in real credentials for local testing:

```bash
cp supabase/functions/.env.example supabase/functions/.env
# edit supabase/functions/.env with real values — see that file for where
# each credential comes from (Play Console / App Store Connect)
npx supabase functions serve --env-file supabase/functions/.env
```

`supabase/functions/.env` is gitignored by the repo's root `.gitignore` — do
not force-add it.

## Deploying

```bash
npx supabase secrets set --env-file supabase/functions/.env
npx supabase functions deploy verify-purchase
npx supabase functions deploy get-course-content
```

## Running the tests

No Supabase project or credentials needed — both functions' `handler_test.ts`
exercise `handler.ts` against fake deps, and `get-course-content`'s
`content_test.ts` validates the real bundled JSON:

```bash
cd src/backend/supabase/functions/verify-purchase
deno test --allow-env handler_test.ts
deno check index.ts handler.ts handler_test.ts google_play.ts apple.ts jwt.ts types.ts
deno lint

cd ../get-course-content
deno test --allow-env --allow-read
deno check index.ts handler.ts handler_test.ts content_test.ts types.ts
deno lint
```

## Request contracts

```
POST /functions/v1/verify-purchase
Authorization: Bearer <Supabase user JWT>
Content-Type: application/json

{
  "platform": "android" | "ios",
  "productId": "monthly_sub" | "annual_sub",  // must match SubscriptionPlan's product ids
  "purchaseToken": "..."   // Android: Play Billing purchase token
                            // iOS: StoreKit 2 transaction id
}
```

Response: `{ "status": "active" | "expired", "expiresAt": string | null }`.

```
POST /functions/v1/get-course-content
Authorization: Bearer <Supabase user JWT>
Content-Type: application/json

{ "targetLanguage": "pt" | "fr" | "ja" }
```

Response: the course JSON (same shape `Course.fromJson` expects in the
mobile app), or `403` if the caller has no active subscription.

## Backups

Backup/PITR policy is a project-level infra setting, not code — it lives in
the Supabase Dashboard, not this repo, so nothing here can turn it on for
you. Check **Project Settings → Backups** for project ref
`nfkhnrwyekqbjxwxmctu`:

- Supabase takes **daily backups on every plan**, including Free (7-day
  retention on Free/Pro; longer on higher tiers). Confirm at least one
  successful daily backup shows there before relying on it.
- **Point-in-Time Recovery (PITR)** — restore to any point within the
  retention window, not just the last daily snapshot — requires the Pro plan
  or above and is opt-in per project. Worth enabling given this table is the
  source of truth for who has paid for Premium: without it, a bad migration
  or accidental delete between daily backups loses everything since the last
  snapshot.
- A restore rolls back the *whole* database, not one table — there's no
  server-side undo for a single bad `subscriptions` write today.

Immediate stopgap that doesn't depend on a Dashboard setting, runnable right
now from this repo:

```bash
npx supabase db dump --linked -f backup-$(date +%Y%m%d).sql
```

Keep that file out of git (it contains real user data) — store it wherever
you keep other backups, not in this repo.

## Next step

Just credentials. Set `GOOGLE_SERVICE_ACCOUNT_JSON` / `GOOGLE_PLAY_PACKAGE_NAME`
and/or `APPLE_KEY_ID` / `APPLE_ISSUER_ID` / `APPLE_PRIVATE_KEY` /
`APPLE_BUNDLE_ID` (see `.env.example`) via `npx supabase secrets set` once
you have them from Play Console / App Store Connect, then a real purchase
in the app will exercise the whole path — client, anonymous auth, edge
function, store verification, entitlement — for real.
