-- Backs rate limiting for the save-marketing-contact Edge Function — same
-- shape and trust model as verify_purchase_attempts.

create table if not exists public.marketing_contact_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists marketing_contact_requests_user_id_created_at_idx
  on public.marketing_contact_requests (user_id, created_at);

alter table public.marketing_contact_requests enable row level security;

-- No policies for the authenticated/anon roles: clients can neither read
-- nor write this table directly. Only the Edge Function's service-role
-- client (which bypasses RLS) touches it.
