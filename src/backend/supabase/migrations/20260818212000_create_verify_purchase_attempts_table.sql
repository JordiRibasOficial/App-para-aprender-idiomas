-- Backs rate limiting for the verify-purchase Edge Function: one row per
-- verification attempt (accepted or rejected), so the function can count
-- how many a user made in a recent window before deciding to serve or
-- reject the next one. Written only by the Edge Function (service role) —
-- same trust model as subscriptions.

create table if not exists public.verify_purchase_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Supports "count rows for this user since <window start>" efficiently.
create index if not exists verify_purchase_attempts_user_id_created_at_idx
  on public.verify_purchase_attempts (user_id, created_at);

alter table public.verify_purchase_attempts enable row level security;

-- No policies for the authenticated/anon roles: clients can neither read
-- nor write this table directly. Only the Edge Function's service-role
-- client (which bypasses RLS) touches it.
