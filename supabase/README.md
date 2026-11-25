# HopAlong — Supabase backend setup

Follow these steps in order. Everything is copy-paste safe: paste the files
as-is, and only replace the values marked `<...>` with your own.

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in (or create a free account).
2. Click **New project**.
3. Pick any project name (e.g. `hopalong`), set a database password, and choose
   region **ap-south-1 (Mumbai)** — closest to Kerala, so the app feels faster.
4. Wait for the project to finish provisioning (a minute or two).

Free-tier note: the free tier includes a 500 MB database, 1 GB file storage,
50,000 monthly active users and 2 GB bandwidth — plenty for testing and a
small launch. The project pauses after 7 days of inactivity on the free tier;
just resume it from the dashboard if that happens.

## 2. Create the tables

1. In the Supabase Dashboard, open **SQL Editor** (left sidebar).
2. Click **New query**.
3. Open the file `supabase/migrations/00001_hopalong_schema.sql` in this repo,
   select all of it, and paste it into the query box.
4. Click **Run**. You should see "Success. No rows returned."
5. Check it worked: open **Table Editor** — you should see 8 tables:
   `profiles`, `rides`, `ride_requests`, `conversations`, `messages`,
   `notifications`, `reports`, `blocked_users`.

This file creates the tables, the row level security (RLS) policies that keep
each user to their own data, and three database functions
(`accept_ride_request`, `reject_ride_request`, `cancel_ride`) that safely
update seats and send notifications.

## 3. Create the avatars bucket

1. Open **Storage** (left sidebar) and click **Create a new bucket**.
2. Name it exactly `avatars` and turn **Public bucket** ON, then create it.
3. Back in **SQL Editor**, open a **New query** and paste the storage-policy
   SQL from the commented block in `migrations/00001_hopalong_schema.sql`
   (the section headed "Storage: avatars bucket" — remove the `--` at the
   start of each line first), then click **Run**.

   This lets signed-in users upload a photo only into their own folder
   (`avatars/<their-user-id>/...`) and lets anyone view avatars.

## 4. (Optional) Load sample rides

For demo data — 8 sample people and 8 upcoming Kerala rides:

1. Open **SQL Editor** → **New query**.
2. Paste the contents of `supabase/seed.sql` and click **Run**.
3. You should get 8 profiles and 8 rides.

Note: the sample profile ids are placeholders, and `profiles.id`
references `auth.users(id)` — so the insert fails unless those 8 auth
users already exist. Create the 8 accounts first and replace the
placeholder ids with their real auth user ids, or skip this step: demo
mode already shows the same 8 rides. Delete the sample rows before
launch (see the header comment in `seed.sql`).

## 5. Set up sign-in

1. Open **Authentication** → **Providers** → **Email**.
2. For testing, turn **Confirm email** OFF so you can sign up instantly.
   For production, turn it back ON.
3. Enable **Email OTP** while you are there (used for email-code sign-in).
4. Phone sign-in is optional and needs a Twilio or MessageBird account —
   skip it unless you need SMS login.

## 6. Copy the API keys

1. Open **Project Settings** (gear icon) → **API**.
2. Copy the **Project URL** and the **anon public** key.
3. Keep them safe. The anon key is safe to ship in the app; never share the
   **service_role** key — it bypasses all security rules.

## 7. Run the app against Supabase

```bash
flutter run --dart-define SUPABASE_URL=<your-project-url> --dart-define SUPABASE_ANON_KEY=<your-anon-key>
```

Replace `<your-project-url>` and `<your-anon-key>` with the two values from
step 6. Without these flags the app runs in **demo mode** with built-in
sample data and no account needed — see the project README.

## 8. Verify it works

1. Run the app, sign up with an email and password, and complete the profile.
2. In the Supabase Dashboard, open **Table Editor** → `profiles` — you
   should see one new row for your account.
3. Create a ride as a rider, then request it from a second account to see
   the request → accept → chat flow working end to end.

## Files in this folder

| File | What it is |
| --- | --- |
| `migrations/00001_hopalong_schema.sql` | All tables, RLS policies, functions, indexes |
| `seed.sql` | Optional sample profiles + rides for demo |
| `README.md` | This file |
