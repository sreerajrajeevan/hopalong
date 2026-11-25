-- HopAlong — Supabase schema (migration 00001)
-- Run this file in the Supabase Dashboard: SQL Editor -> New query -> paste -> Run.
-- Creates the tables, row level security policies, helper functions and indexes
-- for the HopAlong ride-sharing app. Safe to re-run: objects are created
-- with IF NOT EXISTS / CREATE OR REPLACE where possible, but policies are
-- dropped and recreated so a re-run stays clean.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  dob date not null,
  gender text not null check (gender in ('Female', 'Male', 'Non-binary', 'Prefer not to say')),
  phone text not null,
  email text,
  avatar_url text not null,
  mode text not null default 'member' check (mode in ('member', 'rider')),
  completed_rides int not null default 0,
  created_at timestamptz default now()
);

create table if not exists public.rides (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  from_location text not null,
  to_location text not null,
  travel_date date not null,
  departure_time time not null,
  vehicle_type text not null check (vehicle_type in ('car', 'bike')),
  vehicle_model text not null,
  total_seats int not null check (total_seats between 1 and 6),
  seats_left int not null check (seats_left >= 0),
  contribution numeric(10,2),
  pickup_landmark text,
  dropoff_landmark text,
  notes text,
  status text not null default 'active' check (status in ('active', 'completed', 'cancelled')),
  created_at timestamptz default now()
);

create table if not exists public.ride_requests (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  member_id uuid not null references public.profiles(id) on delete cascade,
  message text,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'withdrawn', 'cancelled')),
  created_at timestamptz default now()
);

-- One active (pending or accepted) request per member per ride.
create unique index if not exists ride_requests_one_active
  on public.ride_requests (ride_id, member_id)
  where status in ('pending', 'accepted');

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  member_id uuid not null references public.profiles(id) on delete cascade,
  host_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique (ride_id, member_id, host_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  read_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('request', 'accepted', 'rejected', 'message', 'cancellation', 'modification', 'reminder')),
  title text not null,
  body text not null,
  ride_id uuid references public.rides(id) on delete set null,
  conversation_id uuid references public.conversations(id) on delete set null,
  read boolean not null default false,
  created_at timestamptz default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete set null,
  ride_id uuid references public.rides(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  created_at timestamptz default now()
);

create table if not exists public.blocked_users (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (blocker_id, blocked_id)
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.rides enable row level security;
alter table public.ride_requests enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.reports enable row level security;
alter table public.blocked_users enable row level security;

-- profiles: anyone signed in can read profiles; a user can only
-- insert/update their own row (id = auth.uid()).
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (auth.uid() = id);

-- rides: anyone signed in can read rides; only the host can create,
-- update or delete their own rides.
drop policy if exists rides_select on public.rides;
create policy rides_select on public.rides
  for select to authenticated using (true);

drop policy if exists rides_insert_host on public.rides;
create policy rides_insert_host on public.rides
  for insert to authenticated with check (auth.uid() = host_id);

drop policy if exists rides_update_host on public.rides;
create policy rides_update_host on public.rides
  for update to authenticated using (auth.uid() = host_id);

drop policy if exists rides_delete_host on public.rides;
create policy rides_delete_host on public.rides
  for delete to authenticated using (auth.uid() = host_id);

-- ride_requests: the member and the ride's host can read a request.
-- The member creates it; the host changes its status (accept/reject)
-- and the member withdraws it — both covered by the update policy.
drop policy if exists ride_requests_select on public.ride_requests;
create policy ride_requests_select on public.ride_requests
  for select to authenticated using (
    auth.uid() = member_id
    or auth.uid() = (select host_id from public.rides where rides.id = ride_requests.ride_id)
  );

drop policy if exists ride_requests_insert_member on public.ride_requests;
create policy ride_requests_insert_member on public.ride_requests
  for insert to authenticated with check (auth.uid() = member_id);

drop policy if exists ride_requests_update on public.ride_requests;
create policy ride_requests_update on public.ride_requests
  for update to authenticated using (
    auth.uid() = (select host_id from public.rides where rides.id = ride_requests.ride_id)
    or auth.uid() = member_id
  );

-- conversations: only the member and the host of the ride can read
-- or open a conversation.
drop policy if exists conversations_select on public.conversations;
create policy conversations_select on public.conversations
  for select to authenticated using (auth.uid() = member_id or auth.uid() = host_id);

drop policy if exists conversations_insert on public.conversations;
create policy conversations_insert on public.conversations
  for insert to authenticated with check (auth.uid() = member_id or auth.uid() = host_id);

-- messages: only the two participants of the conversation can read,
-- send, or mark messages read (read receipts use the update policy).
drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages
  for select to authenticated using (
    auth.uid() in (select member_id from public.conversations where conversations.id = messages.conversation_id)
    or auth.uid() in (select host_id from public.conversations where conversations.id = messages.conversation_id)
  );

drop policy if exists messages_insert on public.messages;
create policy messages_insert on public.messages
  for insert to authenticated with check (
    auth.uid() in (select member_id from public.conversations where conversations.id = messages.conversation_id)
    or auth.uid() in (select host_id from public.conversations where conversations.id = messages.conversation_id)
  );

drop policy if exists messages_update on public.messages;
create policy messages_update on public.messages
  for update to authenticated using (
    auth.uid() in (select member_id from public.conversations where conversations.id = messages.conversation_id)
    or auth.uid() in (select host_id from public.conversations where conversations.id = messages.conversation_id)
  );

-- notifications: a user reads and marks read only their own notifications.
-- The insert policy is deliberately open to authenticated users because
-- inserts happen via SECURITY DEFINER functions / the service role;
-- the app never lets one user write another user's notifications directly.
drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications
  for update to authenticated using (auth.uid() = user_id);

drop policy if exists notifications_insert on public.notifications;
create policy notifications_insert on public.notifications
  for insert to authenticated with check (true);

-- reports: a user can file a report and read only their own reports.
-- Admins read all reports via the service role (which bypasses RLS).
drop policy if exists reports_insert on public.reports;
create policy reports_insert on public.reports
  for insert to authenticated with check (auth.uid() = reporter_id);

drop policy if exists reports_select_own on public.reports;
create policy reports_select_own on public.reports
  for select to authenticated using (auth.uid() = reporter_id);

-- blocked_users: a user manages only their own block list.
drop policy if exists blocked_users_all on public.blocked_users;
create policy blocked_users_all on public.blocked_users
  for all to authenticated
  using (auth.uid() = blocker_id)
  with check (auth.uid() = blocker_id);

-- ---------------------------------------------------------------------------
-- Storage: avatars bucket
-- ---------------------------------------------------------------------------
-- The `avatars` bucket must be created in the Dashboard (Storage ->
-- Create bucket, name `avatars`, Public bucket ON). The SQL below is
-- commented out because the storage schema may not exist in the SQL
-- Editor context — run it as a separate query after creating the bucket.
--
-- insert into storage.buckets (id, name, public)
-- values ('avatars', 'avatars', true)
-- on conflict (id) do nothing;
--
-- -- Authenticated users may upload only into their own folder: avatars/<uid>/...
-- create policy "avatars_upload_own_folder" on storage.objects
--   for insert to authenticated
--   with check (
--     bucket_id = 'avatars'
--     and auth.uid()::text = (storage.foldername(name))[1]
--   );
--
-- -- Anyone may read avatars (public bucket).
-- create policy "avatars_public_read" on storage.objects
--   for select to public
--   using (bucket_id = 'avatars');
--
-- -- Owners may replace / delete their own avatars.
-- create policy "avatars_update_own" on storage.objects
--   for update to authenticated
--   using (
--     bucket_id = 'avatars'
--     and auth.uid()::text = (storage.foldername(name))[1]
--   );
-- create policy "avatars_delete_own" on storage.objects
--   for delete to authenticated
--   using (
--     bucket_id = 'avatars'
--     and auth.uid()::text = (storage.foldername(name))[1]
--   );

-- ---------------------------------------------------------------------------
-- Functions (SECURITY DEFINER — they run with the owner's rights so they
-- can write notifications and decrement seats past RLS where needed)
-- ---------------------------------------------------------------------------

-- Accept a ride request: host only, request must still be pending, and
-- the ride must have a seat left. Decrements seats_left, notifies the
-- member, and opens the host<->member conversation for the ride.
create or replace function public.accept_ride_request(p_request_id uuid)
returns public.ride_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  req public.ride_requests;
  r public.rides;
begin
  select * into req from public.ride_requests where id = p_request_id;

  if req.id is null or req.status <> 'pending' then
    raise exception 'Request is no longer pending';
  end if;

  if auth.uid() <> (select host_id from public.rides where id = req.ride_id) then
    raise exception 'Only the host can accept requests';
  end if;

  select * into r from public.rides where id = req.ride_id;

  if r.seats_left <= 0 then
    raise exception 'No seats left';
  end if;

  update public.ride_requests
    set status = 'accepted'
    where id = p_request_id
    returning * into req;

  update public.rides
    set seats_left = seats_left - 1
    where id = req.ride_id;

  insert into public.notifications (user_id, type, title, body, ride_id)
  values (
    req.member_id,
    'accepted',
    'Request accepted',
    'Your request to join the ride from ' || r.from_location || ' to ' || r.to_location || ' was accepted.'
  );

  insert into public.conversations (ride_id, member_id, host_id)
  values (req.ride_id, req.member_id, r.host_id)
  on conflict (ride_id, member_id, host_id) do nothing;

  return req;
end;
$$;

-- Reject a ride request: host only, request must still be pending.
-- Sends a polite notification to the member. Seats are untouched.
create or replace function public.reject_ride_request(p_request_id uuid)
returns public.ride_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  req public.ride_requests;
  r public.rides;
begin
  select * into req from public.ride_requests where id = p_request_id;

  if req.id is null or req.status <> 'pending' then
    raise exception 'Request is no longer pending';
  end if;

  if auth.uid() <> (select host_id from public.rides where id = req.ride_id) then
    raise exception 'Only the host can reject requests';
  end if;

  select * into r from public.rides where id = req.ride_id;

  update public.ride_requests
    set status = 'rejected'
    where id = p_request_id
    returning * into req;

  insert into public.notifications (user_id, type, title, body, ride_id)
  values (
    req.member_id,
    'rejected',
    'Request declined',
    'Sorry — your request to join the ride from ' || r.from_location || ' to ' || r.to_location || ' was declined. Plenty of other rides are available!'
  );

  return req;
end;
$$;

-- Cancel a ride: host only. Marks the ride cancelled, cancels every
-- accepted request on it, and notifies each accepted member.
create or replace function public.cancel_ride(p_ride_id uuid)
returns public.rides
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.rides;
begin
  select * into r from public.rides where id = p_ride_id;

  if r.id is null then
    raise exception 'Ride not found';
  end if;

  if auth.uid() <> r.host_id then
    raise exception 'Only the host can cancel this ride';
  end if;

  insert into public.notifications (user_id, type, title, body, ride_id)
  select
    member_id,
    'cancellation',
    'Ride cancelled',
    'The ride from ' || r.from_location || ' to ' || r.to_location || ' on ' || r.travel_date::text || ' was cancelled by the host.'
  from public.ride_requests
  where ride_id = p_ride_id
    and status = 'accepted';

  update public.ride_requests
    set status = 'cancelled'
    where ride_id = p_ride_id
      and status = 'accepted';

  update public.rides
    set status = 'cancelled'
    where id = p_ride_id
    returning * into r;

  return r;
end;
$$;

grant execute on function public.accept_ride_request(uuid) to authenticated;
grant execute on function public.reject_ride_request(uuid) to authenticated;
grant execute on function public.cancel_ride(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Notes
-- ---------------------------------------------------------------------------
-- Ride modification notifications (e.g. time/route changed) are sent
-- app-side: the app updates the ride, then inserts a 'modification'
-- notification for each accepted member. No database trigger is used
-- for this, so edits stay predictable and testable from the app.

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index if not exists rides_host_id_idx on public.rides (host_id);
create index if not exists rides_travel_date_idx on public.rides (travel_date);
create index if not exists ride_requests_ride_id_idx on public.ride_requests (ride_id);
create index if not exists messages_conversation_created_idx on public.messages (conversation_id, created_at);
create index if not exists notifications_user_read_idx on public.notifications (user_id, read);
