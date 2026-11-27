-- 00003_hopalong_optional_dob.sql
--
-- Covers: make profiles.dob optional (DOB is no longer required at signup).
-- Paste-and-run: Supabase dashboard -> SQL Editor -> New query -> paste
-- this whole file -> Run. Safe to re-run after a partial failure.
--
-- avatar_url stays NOT NULL: the app stores '' for "no photo" and the
-- avatar widget falls back to initials, so no change is needed there.

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'dob'
      and is_nullable = 'NO'
  ) then
    alter table public.profiles
      alter column dob drop not null;
  end if;
end $$;

-- Verification: this should show one row with is_nullable = 'YES'.
select column_name, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name = 'dob';
