-- Server-side source of truth for Premium entitlement. Written only by the
-- verify-purchase Edge Function (service role, bypasses RLS) after a
-- successful server-to-server check against Google Play / App Store — never
-- by the client directly, so a modified client can't self-grant Premium.

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  product_id text not null,
  -- Android: purchaseToken. iOS: original transaction id. Together with
  -- platform, uniquely identifies one real-world purchase — re-verifying
  -- the same purchase updates the row instead of creating a duplicate.
  store_transaction_id text not null,
  status text not null check (status in ('active', 'expired', 'revoked')),
  verified_at timestamptz not null default now(),
  expires_at timestamptz,
  -- Raw verification response from the store API, kept for support/audit
  -- (e.g. "why does this user say they paid but aren't Premium").
  raw_response jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, store_transaction_id)
);

create index if not exists subscriptions_user_id_idx on public.subscriptions (user_id);

alter table public.subscriptions enable row level security;

-- Clients may read their own entitlement status...
create policy "Users can read their own subscriptions"
  on public.subscriptions
  for select
  using (auth.uid() = user_id);

-- ...but never write it directly. Only the Edge Function (using the
-- service role key, which bypasses RLS entirely) inserts/updates rows —
-- there is deliberately no insert/update/delete policy for authenticated
-- clients here.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row
  execute function public.set_updated_at();
