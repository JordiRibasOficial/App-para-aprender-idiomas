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
    ..._create_subscriptions_table.sql   # entitlement table, RLS: clients read-only
  functions/
    verify-purchase/
      index.ts        # Deno.serve entrypoint — wires real Supabase/Google/Apple clients
      handler.ts       # the actual request logic, dependency-injected and unit tested
      google_play.ts    # Google Play Developer API verifier (fully implemented)
      apple.ts           # App Store Server API verifier (implemented; see its doc comment
                          # for one documented, deliberate gap)
      jwt.ts               # shared RS256/ES256 JWT signing used by both verifiers
      types.ts               # shared types + the Zod request schema
      handler_test.ts          # Deno tests, using fake verifiers (no real credentials needed)
```

**Not done in this pass**: the Flutter app doesn't call this endpoint yet.
`InAppPurchaseSubscriptionRepository` still grants entitlement from the local
presence check. Wiring the client is the natural next step once this backend
is deployed and you have real credentials to test against — see "Next step"
below.

## The security property this gives you

`handler.ts` is written to fail closed everywhere:

- No auth token → 401, nothing written.
- Malformed request → 400, nothing written.
- Platform has no verifier configured (missing secrets) → 503, nothing written.
- The store's API call fails → 502, nothing written.
- Entitlement is written **only** after a verifier returns a positive result
  from Google/Apple's own servers.

A modified client can send whatever it wants to this endpoint; without a
Google/Apple purchase token that those companies' own APIs recognize as real,
it gets nothing.

## Status

**Deployed.** Project ref `nfkhnrwyekqbjxwxmctu` (org "Jordi Ribas Oficial",
region `eu-west-3`), migration applied, `verify-purchase` is live at
`https://nfkhnrwyekqbjxwxmctu.supabase.co/functions/v1/verify-purchase`
with `verify_jwt = true` — confirmed rejecting unauthenticated requests.
No Google/Apple secrets are set yet, so both platforms currently return 503
(fails closed, as designed) until those are configured — see "Deploying"
below.

The database password isn't recorded anywhere in this repo; rotate/view it
from the dashboard (Project Settings → Database) if you need it.

One gap from this first deploy: it went through direct Management API calls
because the CLI's own network transport failed (`Transport error`, but
`curl` to the same endpoints worked fine) — the Go CLI is fussier about
something in this network path than curl is. `supabase link` was never run,
so there's no local link state. If the CLI transport problem doesn't
reproduce on your machine, `npx supabase link --project-ref
nfkhnrwyekqbjxwxmctu` should just work and give you the normal CLI-driven
workflow (`db push`, `functions deploy`, etc.) going forward. This also
means `config.toml`'s project-level settings (e.g. `auth.enable_anonymous_sign_ins`)
were never pushed — only the migration and the function were applied
directly. Push those once linking works, before wiring up the client's
anonymous sign-in.

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
```

## Running the tests

No Supabase project or credentials needed — `handler_test.ts` exercises
`handler.ts` against fake verifiers and a fake DB write:

```bash
cd src/backend/supabase/functions/verify-purchase
deno test --allow-env handler_test.ts
deno check index.ts handler.ts handler_test.ts google_play.ts apple.ts jwt.ts types.ts
deno lint
```

## Request contract

```
POST /functions/v1/verify-purchase
Authorization: Bearer <Supabase user JWT>
Content-Type: application/json

{
  "platform": "android" | "ios",
  "productId": "premium_monthly" | "premium_annual",
  "purchaseToken": "..."   // Android: Play Billing purchase token
                            // iOS: StoreKit 2 transaction id
}
```

Response: `{ "status": "active" | "expired", "expiresAt": string | null }`.

## Next step

The client isn't wired up yet. When ready: add `supabase_flutter`, sign the
user in anonymously (`supabase.auth.signInAnonymously()` — ties in with the
onboarding screen's existing "no real accounts yet" note, and can be upgraded
to a real account later via identity linking), and call this function from
`InAppPurchaseSubscriptionRepository._onPurchaseUpdate` instead of trusting
the local presence check.
