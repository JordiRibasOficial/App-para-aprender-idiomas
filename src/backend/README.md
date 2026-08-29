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

Same fail-closed shape as `verify-purchase`: no auth → 401, more than 30
requests from the same user in 10 minutes → 429 (see
`get_course_content_requests`), not Premium → 403 with no content in the
body, DB failure → generic 500 (not the raw Postgres error — see
`handler.ts`'s catch-all). `content_test.ts` separately
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

## export-user-data

RGPD art. 15/20 (right of access / data portability) — lets the caller pull
everything this backend holds about their own anonymous session identity in
one request: their `subscriptions` row(s) and `verify_purchase_attempts`
timestamps. No input body — there's nothing to specify, `getUserId` already
determines whose data comes back, and every query in `buildExport` is scoped
to that same userId (see `index.ts`).

Deliberately excludes `store_transaction_id` and `raw_response` from the
`subscriptions` rows it returns — those are opaque store-internal
identifiers and the full raw verification payload kept for our own
support/audit trail, not something meaningfully "about" the user beyond
what the other fields already summarize. `[PENDIENTE: confirm this scoping
decision with the data protection advisor.]`

Same fail-closed shape as the other two functions: no auth → 401, more than
10 requests from the same user in 10 minutes → 429 (see
`export_user_data_requests` — deliberately its own table, not
`verify_purchase_attempts`, so exporting isn't itself something the export
has to report on), a query failure → generic 500 (not the raw Postgres
error). The mobile app's "Mis datos" screen
(`presentation/data_export_screen.dart`) calls this and lets the user copy
the resulting JSON to their clipboard.

## delete-user-data

RGPD art. 17 (right to erasure) — the mirror of export-user-data above.
Deletes the caller's Supabase Auth user via the Admin API
(`admin.auth.admin.deleteUser`), which cascades to every table with a
`references auth.users (id) on delete cascade` FK — `subscriptions`,
`verify_purchase_attempts`, and all four rate-limit tracking tables — in
one transaction. No separate per-table deletes to keep in sync as new
tables are added; any future table just needs the same cascade FK.

Same fail-closed shape as the others: no auth → 401, more than 5 requests
from the same user in 10 minutes → 429 (see `delete_user_data_requests`),
a deletion failure → generic 500 (not the raw Admin API error).
Irreversible and immediate: once it succeeds, the caller's anonymous
identity no longer exists, so their existing Bearer token stops working —
the mobile app signs out locally right after a successful call
(`SupabaseUserDataDeletionRepository`) rather than waiting for a token
failure to discover that. The "Eliminar mis datos" button lives on the same
"Mis datos" screen as the export button, behind a confirmation dialog since
this can't be undone.

## Status

**All four functions and every migration are deployed to the live project**,
minus store credentials. Project ref `nfkhnrwyekqbjxwxmctu` (org "Jordi
Ribas Oficial", region `eu-west-3`):

- All migrations applied via `supabase db push` (`subscriptions`,
  `verify_purchase_attempts`, `get_course_content_requests`,
  `export_user_data_requests`, `delete_user_data_requests`,
  `purge_stale_request_logs()`) — exercised against a real Postgres, not
  just written blind.
- `verify-purchase`, `get-course-content`, `export-user-data`, and
  `delete-user-data` all live via `supabase functions deploy`, each with
  `verify_jwt = true`. Deployed from a local machine after `supabase link
  --project-ref nfkhnrwyekqbjxwxmctu` — the CLI transport issue noted below
  didn't reproduce there.
- Anonymous sign-ins enabled on the project
  (`external_anonymous_users_enabled`, matches `config.toml`'s
  `auth.enable_anonymous_sign_ins = true`).
- All four functions smoke-tested end to end for real against the live
  project, via a real anonymous sign-up (`/auth/v1/signup`) → session JWT:
  - `verify-purchase` (android) → initially `503 "Purchase verification is
    not configured for platform android"` — correct fail-closed answer
    before any store credentials existed. **Update:** Google Play
    credentials (`GOOGLE_SERVICE_ACCOUNT_JSON` / `GOOGLE_PLAY_PACKAGE_NAME`)
    are now set (see "Store credentials setup" below) — re-running the same
    smoke test with a real product id and a made-up purchase token now
    returns `502 "Verification request to the store failed"`, confirming
    the function boots, the platform is configured, and it's making a real
    call to the Google Play Developer API that correctly rejects a token
    Google doesn't recognize. Apple/iOS credentials are still unset, so
    `platform: "ios"` still returns `503`.
  - `get-course-content` → `403 "An active Premium subscription is
    required"`. Correct — this test user never purchased anything.
  - `export-user-data` → `200` with the caller's own (empty)
    subscriptions/verificationAttempts arrays.
  - `delete-user-data` → `200 {"deleted": true}`, then re-using the same
    JWT against `export-user-data` immediately afterward returned `401` —
    confirms the Auth-user deletion (and its cascade to every table
    referencing it) actually took effect, not just a 200 with no real
    effect.
  - One real bug caught by this smoke test, now fixed: the three newer
    functions were deployed *before* their migrations were pushed (a
    deploy-ordering slip during the manual rollout), so `get-course-content`
    and `export-user-data` both 500'd — their rate limiter tried to read/
    write a table that didn't exist yet. Running `supabase db push` to
    apply the four pending migrations resolved it; re-running the same
    smoke test above confirmed the fix.
- `pg_cron` is enabled and `purge_stale_request_logs()` is scheduled
  (`select cron.schedule('purge-stale-request-logs', '0 3 * * *', 'select
  public.purge_stale_request_logs();')`) — confirmed via `select * from
  cron.job;` in the SQL Editor: `jobid 1`, schedule `0 3 * * *`, `active =
  true`. The four rate-limit tracking tables now get purged of rows older
  than 7 days automatically, every day at 03:00.
- `verify-purchase` now also sends a TRLGDCU purchase-confirmation email
  (see "Purchase confirmation email setup" below) — **not yet deployed or
  configured**: needs both a fresh `supabase functions deploy
  verify-purchase` to ship this code and `RESEND_API_KEY`/
  `RESEND_FROM_EMAIL` set before it does anything. Until both, this is a
  silent no-op — `input.email` is accepted by the schema but
  `sendConfirmationEmail` isn't wired to anything live yet, so no request
  fails and nothing is sent.

The database password isn't recorded anywhere in this repo; rotate/view it
from the dashboard (Project Settings → Database) if you need it.

Historical note: the very first deploy (`verify-purchase` + its migration)
went through direct Management API calls because the CLI's network
transport failed inside this session's own sandboxed environment
(`Transport error`, though `curl` to the same endpoints worked fine) — the
Go CLI was fussier about something in that specific network path than curl
was. Every later deploy (`db push` for the remaining migrations, and all
three newer functions) went through the normal CLI (`supabase link` +
`supabase db push` + `supabase functions deploy`) run from the project
owner's own machine, where that transport issue didn't reproduce.

## Store credentials setup

`verify-purchase` needs Google/Apple credentials as Supabase project secrets
before it can do real verification (until then it correctly answers `503`
for both platforms — see "Status" above). Setting a secret takes effect on
the next function invocation; no redeploy needed.

**Do not paste real credential values into a chat session or commit them to
this repo** — a service-account JSON and a `.p8` private key are standing
credentials, not one-time tokens. Run the commands below yourself, from a
terminal you control.

### Android (Google Play) — `verify-purchase` reads `GOOGLE_SERVICE_ACCOUNT_JSON` + `GOOGLE_PLAY_PACKAGE_NAME`

If you already have a Google Cloud service account with Play Console API
access (Play Console → Users and permissions → API access), set both
secrets directly:

```bash
npx supabase secrets set --project-ref nfkhnrwyekqbjxwxmctu \
  GOOGLE_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)" \
  GOOGLE_PLAY_PACKAGE_NAME=com.worldwebapps.app.aprenderidioma
```

If you don't have that service account yet:
1. Play Console → **Users and permissions** → **Invite new users** (or use
   an existing one) → grant **Google Play Android Developer API** access.
2. Google Cloud Console (same project linked to Play Console) → **IAM &
   Admin → Service Accounts** → create one → **Keys** → **Add key → JSON**.
   Downloads the file `GOOGLE_SERVICE_ACCOUNT_JSON` needs.
3. Back in Play Console → **API access**, link that service account and
   grant it at least "View app information" + "View financial data"
   permissions (needed to query subscription status).

### iOS (App Store) — `verify-purchase` reads `APPLE_KEY_ID`, `APPLE_ISSUER_ID`, `APPLE_PRIVATE_KEY`, `APPLE_BUNDLE_ID`

1. [App Store Connect](https://appstoreconnect.apple.com) → **Users and
   Access** → **Integrations** tab → **In-App Purchase** key type (this is
   a different key type than the general App Store Connect API key — it
   must specifically be an In-App Purchase key to call the Server API
   `verify-purchase` uses).
2. Generate the key. Note the **Key ID** and **Issuer ID** shown on that
   page — those become `APPLE_KEY_ID` and `APPLE_ISSUER_ID`.
3. Download the `.p8` file **immediately** — App Store Connect only lets
   you download it once. Its contents (including the `BEGIN/END PRIVATE
   KEY` lines) become `APPLE_PRIVATE_KEY`.
4. `APPLE_BUNDLE_ID` is the app's `CFBundleIdentifier` — currently
   `com.worldwebapps.app.aprenderidioma` (set via `PRODUCT_BUNDLE_IDENTIFIER`
   in `src/mobile/ios/Runner.xcodeproj/project.pbxproj`).

Once you have those four values plus the downloaded `.p8` file:

```bash
npx supabase secrets set --project-ref nfkhnrwyekqbjxwxmctu \
  APPLE_KEY_ID=<key id> \
  APPLE_ISSUER_ID=<issuer id> \
  APPLE_PRIVATE_KEY="$(cat /path/to/AuthKey_XXXXXXXXXX.p8)" \
  APPLE_BUNDLE_ID=<bundle id> \
  APPLE_ENVIRONMENT=sandbox
```

Flip `APPLE_ENVIRONMENT` to `production` once the app is actually live on
the App Store — sandbox receipts are rejected by the production endpoint
and vice versa.

Verify secrets took effect with the live smoke test in "Status" above:
`verify-purchase` should stop returning `503` for whichever platform(s) now
have credentials (it will still need a real purchase token to return
anything other than a 4xx/502 from Google's/Apple's own APIs — that's
expected, since no test double exists for their production verification
endpoints).

## Purchase confirmation email setup

`verify-purchase` sends a purchase-confirmation email — required by TRLGDCU
arts. 98.7/99.2, see `docs/business/terms-of-service-draft.md` §4 for the
legal reasoning — whenever a purchase verifies as active *and* the client
sent an email (only present if the user gave one during onboarding; guest
users send none, and simply don't get this email). It's sent via
`_shared/email.ts`, best-effort: a failed send is logged
(`supabase functions logs verify-purchase`) but never fails the request or
undoes the entitlement grant already made — see that file and
`verify-purchase/handler.ts`'s call site for why.

### Why Resend

Evaluated against Amazon SES, Postmark, and SendGrid for this specific
need — one low-volume transactional email, sent from a Deno Edge Function,
with a preference for EU data residency (consistent with Supabase in
`eu-west-3` and Sentry's EU region):

| Provider | Fit |
|---|---|
| **Resend** | Plain REST API — no SMTP library needed inside a Deno Edge Function. EU region available. Free tier (3,000 emails/month) is far more than this needs. The provider most commonly paired with Supabase Edge Functions in their own examples. |
| Amazon SES | Cheapest at scale, but starts in a "sandbox" that only sends to pre-verified addresses until you request production access — unnecessary friction for one transactional email. |
| Postmark | Excellent deliverability, but no free tier — pays from day one for near-zero volume. |
| SendGrid | Mature, but a heavier setup and a stricter historical free tier than Resend. |

### Setup

1. Create a [Resend](https://resend.com) account.
2. **You need a domain you control DNS for** — Resend rejects sends from
   an unverified domain, and this project's current public site
   (`jordiribasoficial.github.io/...`, GitHub Pages) doesn't give you DNS
   control. Buy a domain (any registrar, ~10-15€/year) if you don't have
   one yet — you'll want one for a professional contact address regardless
   of Resend.
3. In Resend: **Domains → Add Domain** → add the SPF/DKIM DNS records it
   gives you at your registrar → wait for verification (usually minutes,
   can take longer depending on DNS propagation).
4. **API Keys → Create API Key** → copy it (shown once).
5. Set both secrets:

```bash
npx supabase secrets set --project-ref nfkhnrwyekqbjxwxmctu \
  RESEND_API_KEY=<api key> \
  RESEND_FROM_EMAIL=confirmaciones@tu-dominio.example
```

`RESEND_FROM_EMAIL` must be an address on the domain you just verified —
Resend rejects sends from any other domain. Until both secrets are set,
`sendPurchaseConfirmationEmail` throws immediately (caught by
`handler.ts`'s best-effort wrapper, so `verify-purchase` itself keeps
working normally) — see `_shared/email.ts`.

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
npx supabase functions deploy export-user-data
npx supabase functions deploy delete-user-data
```

## Running the tests

No Supabase project or credentials needed — every function's `handler_test.ts`
exercises `handler.ts` against fake deps, and `get-course-content`'s
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

cd ../export-user-data
deno test --allow-env handler_test.ts
deno check index.ts handler.ts handler_test.ts types.ts
deno lint

cd ../delete-user-data
deno test --allow-env handler_test.ts
deno check index.ts handler.ts handler_test.ts
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

```
POST /functions/v1/export-user-data
Authorization: Bearer <Supabase user JWT>
```

No body. Response: `{ "userId", "exportedAt", "subscriptions": [...], "verificationAttempts": [...] }`.

```
POST /functions/v1/delete-user-data
Authorization: Bearer <Supabase user JWT>
```

No body. Response: `{ "deleted": true }`. Irreversible — see "delete-user-data" above.

## Data retention

`verify_purchase_attempts`, `get_course_content_requests`,
`export_user_data_requests`, and `delete_user_data_requests` exist purely
to back each function's rate limiter — the longest window in use is 10
minutes, so nothing reads a row older than that for any real purpose.
`purge_stale_request_logs()` (added by migration
`20260820140100_create_purge_stale_request_logs_function.sql`) deletes rows
older than 7 days from all four, giving comfortable slack for debugging a
rate-limit dispute without keeping the tables forever — RGPD data
minimization (store only what the stated purpose needs).

The migration only creates the function; scheduling it required enabling
`pg_cron` — a per-project opt-in extension only turned on from **Dashboard
→ Database → Extensions**, not something a migration file can do — and then
running this once from the SQL Editor:

```sql
select cron.schedule('purge-stale-request-logs', '0 3 * * *', 'select public.purge_stale_request_logs();');
```

**Done.** `pg_cron` is enabled and the job is active — confirmed via
`select * from cron.job;` (`jobid 1`, schedule `0 3 * * *`, `active =
true`). The four rate-limit tables now purge automatically every day at
03:00; no more manual `select public.purge_stale_request_logs();` needed.

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

## Encryption at rest

Also a platform-level property, not something this repo's code controls —
documenting it here so it's answered once instead of re-investigated every
time it comes up.

Per Supabase's own security page (supabase.com/security): **"All customer
data is encrypted at rest with AES-256 and in transit via TLS."** This is a
platform default applied to every project on AWS (where this project is
hosted, project ref `nfkhnrwyekqbjxwxmctu`) — it is not a paid add-on and
is not something to configure here; it covers the Postgres database (the
`subscriptions` / `verify_purchase_attempts` tables), Auth, and Storage.
This is separate from **Point-in-Time Recovery** above, which *is*
Pro-plan-and-up and opt-in — encryption at rest applies regardless of plan.

`[PENDIENTE: si el asesor de protección de datos necesita esto por escrito
para el registro de actividades de tratamiento (RGPD), pedir confirmación
directa a Supabase (son "encargado del tratamiento" — ver
docs/business/privacy-policy-draft.md sección 5) en vez de citar solo la
página pública de marketing.]`

## Monitoring & alerts

Every failure path in both functions already logs server-side via
`console.error` before returning a generic error to the client (see
`handleVerifyPurchase`'s and `handleGetCourseContent`'s top-level
catch-all, plus the verifier/upsert-specific catches) — that's what shows
up in:

```bash
npx supabase functions logs verify-purchase
npx supabase functions logs get-course-content
npx supabase functions logs export-user-data
```

or **Dashboard → Edge Functions → \<function\> → Logs** for project ref
`nfkhnrwyekqbjxwxmctu`. There's no gap in *what* gets logged; the gap is
that nobody gets notified when it happens — today you'd only find out by
going and looking.

**Log-based alerts** (Dashboard → Logs & Analytics → Alerts, availability
depends on plan) can close that: worth setting up an alert on a spike in
5xx responses from either function (real bugs — Postgres down, a bad
deploy) and, separately, a spike in 401/403/429 responses on
`verify-purchase` (repeated failed verification attempts from one caller
looks like someone probing for a way to fake Premium, not normal usage —
`verify_purchase_attempts` already has the timestamps to build that alert
condition on). This is Dashboard configuration, not code — nothing here
can turn it on for you.

**Crash reporting for the mobile app**: wired up — Sentry, release builds
only. `main.dart`'s global handlers (`FlutterError.onError`,
`PlatformDispatcher.instance.onError`, `runZonedGuarded`) chain through
Sentry's own integrations rather than replacing them, so every error
reaches Sentry once; `lib/error_reporting.dart`'s `reportError` stays the
local-log funnel it always was. See
`docs/business/crash-reporting-review.md` for the vendor decision and
`src/mobile/lib/data/sentry_config.dart` for the DSN. This backend has no
equivalent yet — its own failures are still `console.error`-only (see
above), not sent anywhere automatically.

## Next step

Google Play credentials are set (see "Store credentials setup" above) and
confirmed live via a real Google Play Developer API call. Two things left:

1. Apple/iOS: set `APPLE_KEY_ID` / `APPLE_ISSUER_ID` / `APPLE_PRIVATE_KEY` /
   `APPLE_BUNDLE_ID` via `npx supabase secrets set` once you have them from
   App Store Connect.
2. `RESEND_API_KEY` / `RESEND_FROM_EMAIL` (see "Purchase confirmation
   email setup" above) — needs a domain you control DNS for, which this
   project doesn't have yet.

Once those are done, a real purchase in the app on either platform will
exercise the whole path — client, anonymous auth, edge function, store
verification, entitlement, confirmation email — for real.

One thing worth knowing if you ever regenerate the Google secret by hand
from PowerShell: `Get-Content -Raw file.json | ConvertFrom-Json |
ConvertTo-Json -Compress` is the reliable way to get a single-line, valid
JSON string into a `.env` value — a raw copy/paste corrupted the JSON once
during setup and made the whole function crash at boot (`JSON.parse` throws
inside `buildVerifiers()`, which Supabase surfaces as a generic
`WORKER_ERROR`, not a helpful message). If `verify-purchase` ever returns
that error for every platform at once, suspect the secret's JSON validity
first.
