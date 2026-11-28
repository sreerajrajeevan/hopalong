-- 00005_hopalong_service_role_grants.sql
-- Grant the service role (Edge Functions) table access.
--
-- The manage-users Edge Function runs as service_role. Migrations
-- 00001/00002/00004 only ever granted tables to `authenticated`, so the
-- function could not read profiles or write admins at all — every data
-- call failed with 42501 "permission denied". (Found 2026-11-28 while
-- setting the first admin's password: direct-bootstrap returned
-- "permission denied for table profiles".)
--
-- Idempotent: GRANT is safe to re-run.
grant select, insert, update, delete on public.profiles to service_role;
grant select, insert, update, delete on public.admins to service_role;
-- The function only touches profiles + admins today, but grant the rest
-- too so future function work does not hit the same wall.
grant select, insert, update, delete on public.rides to service_role;
grant select, insert, update, delete on public.ride_requests to service_role;
grant select, insert, update, delete on public.conversations to service_role;
grant select, insert, update, delete on public.messages to service_role;
grant select, insert, update, delete on public.notifications to service_role;
grant select, insert, update, delete on public.reports to service_role;
grant select, insert, update, delete on public.blocked_users to service_role;

-- Verification (read-only): service_role must now hold CRUD on all 8 tables.
select table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee = 'service_role'
  and privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
order by table_name, privilege_type;
