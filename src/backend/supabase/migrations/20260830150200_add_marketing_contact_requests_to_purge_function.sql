-- Extends purge_stale_request_logs() (see the migration that created it)
-- to also cover marketing_contact_requests, on the same 7-day retention —
-- it's a rate-limit log with the same 10-minute window as the others, so
-- the same reasoning applies.

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
  delete from public.marketing_contact_requests where created_at < now() - interval '7 days';
end;
$$;
