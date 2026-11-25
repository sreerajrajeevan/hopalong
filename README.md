# HopAlong

HopAlong is a ride-sharing app for Kerala: people travelling the same way
share a car or bike seat instead of travelling alone.

- **Members** browse upcoming rides, request a seat, and chat with the host
  once accepted.
- **Riders (hosts)** post a ride — route, date, time, vehicle, seats and an
  optional cost contribution — then accept or decline requests.
- Everyone gets notifications for requests, acceptances, cancellations and
  messages, and can report or block another user.

## Design language

Clean, friendly and mobile-first: big readable type, rounded cards for rides,
one clear action per screen, and a warm, welcoming feel suited to everyday
Kerala travel (Kakkanad → Infopark, Thrissur → Guruvayur, and so on). The
visual details live in the app code under `lib/`; the backend in `supabase/`
only stores data and enforces the rules.

## Features

| Feature | What it does |
| --- | --- |
| Profiles | Name, date of birth, gender, phone, photo, member/rider mode, completed-ride count |
| Post a ride | Route, date, departure time, car/bike + model, 1–6 seats, optional contribution, pickup/drop-off landmarks, notes |
| Find rides | Browse upcoming rides by route and date |
| Ride requests | Request a seat with a message; one active request per member per ride |
| Accept / decline | Host accepts (seat count drops, chat opens) or declines (polite notification) |
| Cancel a ride | Host cancels; every accepted member is notified and their request is cancelled |
| Chat | One conversation per ride between host and each accepted member, with read receipts |
| Notifications | Request, accepted, rejected, message, cancellation, modification, reminder |
| Safety | Report a user or ride; block a user |
| Avatars | Profile photos stored in the public `avatars` storage bucket |

## Demo mode vs live Supabase mode

**Demo mode (no accounts, no setup)** — the app runs with built-in sample
data (the same 8 people and 8 rides as `supabase/seed.sql`):

```bash
flutter run
```

**Live mode (real accounts, real data)** — set up Supabase once (see
`supabase/README.md`), then run with your project URL and anon key:

```bash
flutter run --dart-define SUPABASE_URL=<your-project-url> --dart-define SUPABASE_ANON_KEY=<your-anon-key>
```

Replace `<your-project-url>` and `<your-anon-key>` with the values from
Project Settings → API in your Supabase project. Never paste the
`service_role` key anywhere — it bypasses all security rules.

## Project structure

```text
hopalong/
├── lib/                          # Flutter app (Dart)
│   └── main.dart                 # App entry point
├── test/
│   └── widget_test.dart          # Widget tests
├── android/                      # Android shell (package com.hopalong.app)
├── supabase/
│   ├── README.md                 # Backend setup steps
│   ├── migrations/
│   │   └── 00001_hopalong_schema.sql   # Tables, RLS policies, functions
│   └── seed.sql                  # Optional sample profiles + rides
├── .github/workflows/
│   └── flutter-ci.yml            # CI: analyze, test, debug APK
├── PLAY_PUBLISH.md               # Play Store checklist
└── README.md                     # This file
```

## What is NOT built

- No maps, GPS tracking, or live location — routes are place names and
  landmarks typed in by the host.
- No payments, wallet, subscriptions, or fare calculation — the
  "contribution" on a ride is an agreed amount between host and member,
  settled between them.
- No route or distance APIs.

## Testing

```bash
flutter analyze
flutter test
```

## CI

Every push and pull request to `main` runs the HopAlong CI workflow
(`.github/workflows/flutter-ci.yml`): `flutter pub get`, `flutter analyze`,
`flutter test`, then a debug APK build. The APK is uploaded as the
`hopalong-debug-apk` artifact — download it from the Actions run to install
on a phone.

## Publishing to the Play Store

See [PLAY_PUBLISH.md](PLAY_PUBLISH.md) for the full checklist: release
signing, app bundle, closed testing, data safety, and store listing.
