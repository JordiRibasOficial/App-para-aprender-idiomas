-- Marketing opt-in (offers, promotions, news by email) — a separate,
-- explicit consent from creating an account, per LSSICE art. 21. Written
-- only by the save-marketing-contact Edge Function (service role, bypasses
-- RLS) after confirming the caller is a real, non-anonymous account and the
-- submitted email matches their own — never by the client directly.

create table if not exists public.marketing_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  email text not null,
  consented_at timestamptz not null default now(),
  -- Set instead of deleting the row: keeps a record that consent was
  -- withdrawn (and when), which is itself something we may need to show
  -- proof of. No unsubscribe flow exists yet — this column exists so one
  -- can be added later without a schema change.
  unsubscribed_at timestamptz
);

create index if not exists marketing_contacts_email_idx on public.marketing_contacts (email);

alter table public.marketing_contacts enable row level security;

-- No client policies at all, not even select — this table exists purely
-- for our own outbound marketing use, not for the user to read back via
-- the app. Access to your own data here is via the existing "Mis datos"
-- export/deletion flow instead (see delete-user-data), same as
-- subscriptions and verification-attempt logs.
