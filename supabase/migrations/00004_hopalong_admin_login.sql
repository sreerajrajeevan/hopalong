-- 00004_hopalong_admin_login.sql
--
-- Covers: admin-managed password login (replaces Twilio phone OTP).
--   - public.admins: user ids of the admins (Sree + his friend).
--   - profiles.must_reset_password: true when a user must pick a new
--     password at next sign-in (admin-created accounts, admin resets).
-- Paste-and-run: Supabase dashboard -> SQL Editor -> New query -> paste
-- this whole file -> Run. Safe to re-run after a partial failure.
--
-- The admins table is writable ONLY by the service role (the
-- manage-users Edge Function). Authenticated users can read it, so the
-- app can tell whether the signed-in user is an admin. There is
-- deliberately no insert/update/delete policy for normal users.

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now()
);

alter table public.admins enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'admins'
      and policyname = 'admins_read'
  ) then
    create policy admins_read on public.admins
      for select to authenticated using (true);
  end if;
end $$;

-- RLS policies alone do not grant access (see 00002): the SELECT grant
-- is required for authenticated users to read the table at all.
grant select on public.admins to authenticated;

alter table public.profiles
  add column if not exists must_reset_password boolean not null default false;

-- Verification: expect one row per check.
select 'admins table' as check_name,
  (select count(*) from information_schema.tables
    where table_schema = 'public' and table_name = 'admins') as value
union all
select 'must_reset_password column',
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles'
      and column_name = 'must_reset_password');
