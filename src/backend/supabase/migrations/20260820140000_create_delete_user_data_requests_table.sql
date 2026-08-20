-- Backs rate limiting for the delete-user-data Edge Function — same shape
-- and reasoning as export_user_data_requests (its own table, not shared,
-- so "how many times you asked to delete your data" never has to be
-- reasoned about as part of another function's behavior). In practice this
-- row is almost always cascade-deleted along with everything else the
-- moment the request it's rate-limiting succeeds (see delete-user-data's
-- handler.ts) — it only matters for the case where the caller retries
-- rapidly after an error and never actually gets deleted.

create table if not exists public.delete_user_data_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists delete_user_data_requests_user_id_created_at_idx
  on public.delete_user_data_requests (user_id, created_at);

alter table public.delete_user_data_requests enable row level security;

-- No policies for the authenticated/anon roles: clients can neither read
-- nor write this table directly. Only the Edge Function's service-role
-- client (which bypasses RLS) touches it.
