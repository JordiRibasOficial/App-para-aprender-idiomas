-- Backs rate limiting for the export-user-data Edge Function: one row per
-- request (served or rejected), so the function can count how many a user
-- made in a recent window before deciding to serve the next one. Written
-- only by the Edge Function (service role) — same trust model as
-- verify_purchase_attempts.
--
-- Deliberately a separate table from verify_purchase_attempts, not a
-- shared/generic one: this row itself would otherwise need to be excluded
-- from that table's own RGPD export in export-user-data/index.ts, since
-- "how many times you exported your data" isn't meaningful to hand back as
-- part of the export. Keeping trackers per-function avoids that tangle.

create table if not exists public.export_user_data_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Supports "count rows for this user since <window start>" efficiently.
create index if not exists export_user_data_requests_user_id_created_at_idx
  on public.export_user_data_requests (user_id, created_at);

alter table public.export_user_data_requests enable row level security;

-- No policies for the authenticated/anon roles: clients can neither read
-- nor write this table directly. Only the Edge Function's service-role
-- client (which bypasses RLS) touches it.
