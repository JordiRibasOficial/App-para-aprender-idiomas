-- RGPD data-minimization: verify_purchase_attempts, get_course_content_requests,
-- export_user_data_requests, and delete_user_data_requests exist purely to
-- back each function's rate limiter (see _shared/rate_limit.ts) — the
-- longest rate-limit window in use today is 10 minutes. Nothing reads a row
-- older than that for any real purpose, so keeping them forever is data kept
-- beyond what its stated purpose requires. Retention is set to 7 days, not
-- 10 minutes, to leave comfortable slack for debugging a rate-limit dispute
-- ("why was I blocked?") without the table living forever.
--
-- This function is deliberately NOT scheduled by this migration — pg_cron
-- is a per-project opt-in extension enabled from the Dashboard, not
-- something a migration can turn on. See src/backend/README.md's "Data
-- retention" section for the one-time Dashboard step to schedule this
-- daily; until then it can be run by hand from the SQL Editor.

create or replace function public.purge_stale_request_logs()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.verify_purchase_attempts where created_at < now() - interval '7 days';
  delete from public.get_course_content_requests where created_at < now() - interval '7 days';
  delete from public.export_user_data_requests where created_at < now() - interval '7 days';
  delete from public.delete_user_data_requests where created_at < now() - interval '7 days';
end;
$$;
