-- HopAlong — migration 00002: table grants for the authenticated role
-- Run this file in the Supabase Dashboard: SQL Editor -> New query -> paste -> Run.
-- Why: migration 00001 created the tables and RLS policies but never
-- granted table privileges to the `authenticated` role. RLS policies alone
-- do not grant access — without these GRANTs every read/write from the app
-- fails with "permission denied for table ..." (SQLSTATE 42501), including
-- the profile lookup and the "Create my account" upsert.
-- Safe to re-run: GRANT is idempotent.

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.rides to authenticated;
grant select, insert, update, delete on public.ride_requests to authenticated;
grant select, insert, update, delete on public.conversations to authenticated;
grant select, insert, update, delete on public.messages to authenticated;
grant select, insert, update, delete on public.notifications to authenticated;
grant select, insert, update, delete on public.reports to authenticated;
grant select, insert, update, delete on public.blocked_users to authenticated;
