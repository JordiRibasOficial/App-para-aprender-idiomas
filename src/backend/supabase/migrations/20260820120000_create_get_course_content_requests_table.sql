-- Backs rate limiting for the get-course-content Edge Function: one row per
-- request (served or rejected), so the function can count how many a user
-- made in a recent window before deciding to serve the next one. Written
-- only by the Edge Function (service role) — same trust model as
-- verify_purchase_attempts.

create table if not exists public.get_course_content_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Supports "count rows for this user since <window start>" efficiently.
create index if not exists get_course_content_requests_user_id_created_at_idx
  on public.get_course_content_requests (user_id, created_at);

alter table public.get_course_content_requests enable row level security;

-- No policies for the authenticated/anon roles: clients can neither read
-- nor write this table directly. Only the Edge Function's service-role
-- client (which bypasses RLS) touches it.
