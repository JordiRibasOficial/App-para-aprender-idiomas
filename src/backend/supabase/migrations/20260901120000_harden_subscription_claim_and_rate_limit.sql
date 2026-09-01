-- Security hardening, two independent fixes.
--
-- 1. `claim_subscription` closes a purchase-token replay hole. The previous
--    upsert in verify-purchase/index.ts was
--      upsert(row, { onConflict: "platform,store_transaction_id" })
--    which, when a *different* account submitted an already-claimed store
--    token, resolved the conflict by UPDATEing the existing row — including
--    its `user_id`. A genuine, currently-active purchase token (readable on
--    the buyer's own device, or simply shared) could therefore be replayed by
--    any number of free accounts: each replay passed the real Google/Apple
--    check (the purchase *is* real), took the entitlement for itself, and
--    silently stripped it from the account that actually paid.
--
--    A store transaction now belongs permanently to the first account that
--    claims it. Re-verification by that same account still updates the row
--    (status/expiry refresh on restore, renewal, expiry). Any other account
--    gets no row written and a false return, which the Edge Function turns
--    into a 409.
--
--    The `where s.user_id = excluded.user_id` on the ON CONFLICT path is what
--    enforces this, and it is atomic: a single statement, serialized by the
--    row lock the unique index on (platform, store_transaction_id) already
--    takes, so two concurrent claims cannot both win.
--
-- 2. `record_and_check_rate_limit` makes rate limiting atomic. The previous
--    TypeScript implementation did SELECT count(*) then INSERT as two
--    separate round trips, so N concurrent requests all observed the same
--    pre-insert count and all passed the cap. On verify-purchase that cap is
--    the only thing bounding how many real Google Play API calls (billed
--    against our service-account quota) one account can trigger.

-- A subscription that is 'active' must always say when it stops being active.
-- Without this, a row with status='active' and expires_at=null reads as
-- "Premium forever" to every entitlement check.
alter table public.subscriptions
  add constraint subscriptions_active_requires_expiry
  check (status <> 'active' or expires_at is not null);

create or replace function public.claim_subscription(
  p_user_id uuid,
  p_platform text,
  p_product_id text,
  p_store_transaction_id text,
  p_status text,
  p_expires_at timestamptz,
  p_raw_response jsonb
)
returns boolean
language plpgsql
security definer
-- Pinned so a caller cannot shadow `subscriptions` with a same-named object
-- in an earlier schema and redirect this definer-privileged write.
set search_path = public, pg_temp
as $$
declare
  v_claimed boolean;
begin
  insert into public.subscriptions as s (
    user_id, platform, product_id, store_transaction_id,
    status, expires_at, raw_response, verified_at
  )
  values (
    p_user_id, p_platform, p_product_id, p_store_transaction_id,
    p_status, p_expires_at, p_raw_response, now()
  )
  on conflict (platform, store_transaction_id) do update
    set product_id   = excluded.product_id,
        status       = excluded.status,
        expires_at   = excluded.expires_at,
        raw_response = excluded.raw_response,
        verified_at  = excluded.verified_at
    -- The whole fix: only the account that first claimed this store
    -- transaction may ever update it. For anyone else the UPDATE is skipped,
    -- RETURNING yields no row, and v_claimed stays null -> false.
    where s.user_id = excluded.user_id
  returning true into v_claimed;

  return coalesce(v_claimed, false);
end;
$$;

-- SECURITY DEFINER functions are granted to PUBLIC by default. This one
-- writes entitlement rows, so it must be callable only by the service role
-- the Edge Functions run as — never by a client holding the publishable key.
revoke all on function public.claim_subscription(
  uuid, text, text, text, text, timestamptz, jsonb
) from public, anon, authenticated;
grant execute on function public.claim_subscription(
  uuid, text, text, text, text, timestamptz, jsonb
) to service_role;

create or replace function public.record_and_check_rate_limit(
  p_table text,
  p_user_id uuid,
  p_max_attempts integer,
  p_window_ms bigint
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_window_start timestamptz := now() - make_interval(secs => p_window_ms / 1000.0);
  v_inserted boolean;
begin
  -- Allowlist: p_table is interpolated as an identifier below. It comes from
  -- our own Edge Function config today, never from request input, but this
  -- keeps that true even if a future caller is careless.
  if p_table not in (
    'verify_purchase_attempts',
    'get_course_content_requests',
    'export_user_data_requests',
    'delete_user_data_requests',
    'marketing_contact_requests'
  ) then
    raise exception 'Unknown rate limit table: %', p_table;
  end if;

  -- Serializes concurrent checks for this (table, user) pair only, for the
  -- rest of the transaction. This is what makes the count-then-insert below
  -- actually atomic instead of a TOCTOU window.
  perform pg_advisory_xact_lock(hashtext(p_table || ':' || p_user_id::text));

  execute format(
    'with recent as (
       select count(*) as n from %1$I
       where user_id = $1 and created_at >= $2
     ), ins as (
       insert into %1$I (user_id)
       select $1 from recent where recent.n < $3
       returning 1
     )
     select exists (select 1 from ins)',
    p_table
  )
  into v_inserted
  using p_user_id, v_window_start, p_max_attempts;

  -- Inserted => under the cap => not rate limited.
  return not v_inserted;
end;
$$;

revoke all on function public.record_and_check_rate_limit(
  text, uuid, integer, bigint
) from public, anon, authenticated;
grant execute on function public.record_and_check_rate_limit(
  text, uuid, integer, bigint
) to service_role;
