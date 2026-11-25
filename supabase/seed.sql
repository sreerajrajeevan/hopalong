-- HopAlong — sample data (seed.sql)
-- Run AFTER creating the tables; sample profile ids are placeholders —
-- replace with real auth user ids or delete before launch. For local demo,
-- these rows match lib/data/sample_data.dart.
--
-- How to run: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Safe to re-run: inserts use ON CONFLICT DO NOTHING on the fixed ids.
-- NOTE: profiles reference auth.users(id) in the real schema, so these
-- placeholder rows only insert cleanly if the foreign key allows them.
-- In practice: create the 8 auth users first (or temporarily seed into a
-- demo database), then run this file. Delete all 8 profiles before launch.

-- ---------------------------------------------------------------------------
-- Profiles (8)
-- Ages are as of 2026; DOBs below give those ages.
-- ---------------------------------------------------------------------------

insert into public.profiles (id, full_name, dob, gender, phone, email, avatar_url, mode, completed_rides)
values
  ('11111111-1111-1111-1111-111111111111', 'Meera Nair',    DATE '2002-03-14', 'Female', '+91 98765 43211', 'meera.nair@hopalong.demo',    'https://randomuser.me/api/portraits/women/44.jpg', 'rider', 5),
  ('22222222-2222-2222-2222-222222222222', 'Arjun Pillai',  DATE '1999-06-22', 'Male',   '+91 98765 43212', 'arjun.pillai@hopalong.demo',  'https://randomuser.me/api/portraits/men/32.jpg',   'rider', 3),
  ('33333333-3333-3333-3333-333333333333', 'Lakshmi S',     DATE '1995-01-08', 'Female', '+91 98765 43213', 'lakshmi.s@hopalong.demo',     'https://randomuser.me/api/portraits/women/68.jpg', 'rider', 9),
  ('44444444-4444-4444-4444-444444444444', 'Rohit Kumar',   DATE '2003-09-30', 'Male',   '+91 98765 43214', 'rohit.kumar@hopalong.demo',   'https://randomuser.me/api/portraits/men/75.jpg',   'rider', 2),
  ('55555555-5555-5555-5555-555555555555', 'Divya Menon',   DATE '1997-04-17', 'Female', '+91 98765 43215', 'divya.menon@hopalong.demo',   'https://randomuser.me/api/portraits/women/12.jpg', 'rider', 7),
  ('66666666-6666-6666-6666-666666666666', 'Anand Raj',     DATE '1992-11-05', 'Male',   '+91 98765 43216', 'anand.raj@hopalong.demo',     'https://randomuser.me/api/portraits/men/22.jpg',   'rider', 8),
  ('77777777-7777-7777-7777-777777777777', 'Priya Thomas',  DATE '2005-02-19', 'Female', '+91 98765 43217', 'priya.thomas@hopalong.demo',  'https://randomuser.me/api/portraits/women/33.jpg', 'rider', 4),
  ('88888888-8888-8888-8888-888888888888', 'Vikram Nair',   DATE '2000-08-11', 'Male',   '+91 98765 43218', 'vikram.nair@hopalong.demo',   'https://randomuser.me/api/portraits/men/45.jpg',   'rider', 6)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Rides (8 — one per host; travel dates stay upcoming relative to today)
-- ---------------------------------------------------------------------------

insert into public.rides (id, host_id, from_location, to_location, travel_date, departure_time, vehicle_type, vehicle_model, total_seats, seats_left, contribution, pickup_landmark, dropoff_landmark, notes, status)
values
  ('10000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Kakkanad',   'Infopark',   CURRENT_DATE + 1, TIME '08:30', 'car',  'Maruti Swift',      3, 2, 100.00, 'Near Kakkanad junction', 'Infopark main gate', 'Daily office run — on time, no smoking please.', 'active'),
  ('10000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Ernakulam',  'Kakkanad',   CURRENT_DATE + 2, TIME '09:00', 'bike', 'Honda Activa',      2, 1,  50.00, 'Marine Drive walkway', 'Kakkanad bus stop',    'Quick morning ride, light luggage only.', 'active'),
  ('10000000-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 'Thrissur',   'Guruvayur',  CURRENT_DATE + 3, TIME '07:45', 'car',  'Hyundai i20',       4, 0, 120.00, 'Sakthan bus stand',    'Guruvayur temple east gate', 'Temple visit trip — fully booked, join the waitlist vibe!', 'active'),
  ('10000000-0000-0000-0000-000000000004', '44444444-4444-4444-4444-444444444444', 'Calicut',    'Kalpetta',   CURRENT_DATE + 4, TIME '06:30', 'bike', 'Royal Enfield Classic 350', 2, 1, 80.00, 'Calicut beach road', 'Kalpetta town square', 'Early ride through the ghats — helmet provided.', 'active'),
  ('10000000-0000-0000-0000-000000000005', '55555555-5555-5555-5555-555555555555', 'Trivandrum', 'Kovalam',    CURRENT_DATE + 5, TIME '10:00', 'car',  'Tata Nexon',        3, 2, 150.00, 'Technopark phase 1', 'Kovalam beach entrance', 'Weekend beach run — music on, good vibes.', 'active'),
  ('10000000-0000-0000-0000-000000000006', '66666666-6666-6666-6666-666666666666', 'Kottayam',   'Kochi',      CURRENT_DATE + 6, TIME '08:00', 'car',  'Toyota Innova',     4, 3,    NULL, 'Kottayam boat jetty', 'Ernakulam south station', 'Comfortable family car, room for bags.', 'active'),
  ('10000000-0000-0000-0000-000000000007', '77777777-7777-7777-7777-777777777777', 'Palakkad',   'Coimbatore', CURRENT_DATE + 7, TIME '07:00', 'bike', 'TVS Jupiter',       2, 2,   0.00, 'Palakkad fort gate',  'Gandhipuram bus stand', 'Free ride — just good company needed!', 'active'),
  ('10000000-0000-0000-0000-000000000008', '88888888-8888-8888-8888-888888888888', 'Alappuzha',  'Kochi',      CURRENT_DATE + 2, TIME '09:30', 'car',  'Maruti Baleno',     3, 2, 100.00, 'Alappuzha beach',     'Vytilla hub', 'Morning commute, AC on.', 'active')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Expected result: 8 profiles, 8 rides.
-- Ride requests, conversations, messages and notifications are NOT seeded —
-- they are created by the app flows (request -> accept -> chat).
-- ---------------------------------------------------------------------------
