# HopAlong — Play Store publish checklist

Tick each item off as you go. Anything marked **Sree** needs you, on your
own machine — the signing key in particular must never be committed to git.

## App identity

- [ ] App name: **HopAlong**
- [ ] Android package: `com.hopalong.app`
- [ ] Version in `pubspec.yaml`: `0.1.0+1` (bump `+1` build number on every
      release; bump `0.1.0` when the app meaningfully changes)
- [ ] App icon: replace the placeholder launcher icon with the real HopAlong
      icon (all `android/app/src/main/res/mipmap-*` folders)
- [ ] Feature graphic + screenshots: take them from a real phone running the
      release build (home/rides list, ride detail, request flow, chat)

## Release signing — Sree, on your machine

- [ ] Create a release keystore (once, keep it forever):
      `keytool -genkey -v -keystore ~/hopalong-release.keystore -alias hopalong -keyalg RSA -keysize 2048 -validity 10000`
- [ ] Store the keystore passwords in a password manager — losing the
      keystore means you can never update this app listing again.
- [ ] Create `android/key.properties` on your machine with the keystore path
      and passwords. **Never commit it** (it is git-ignored) and never send
      the keystore or passwords in chat.
- [ ] Build the release bundle: `flutter build appbundle --release`
      (or download the release bundle from a CI run once release signing is
      wired into the workflow)

## Play Console

- [ ] Create a Google Play developer account ($25 one-time) if you don't
      have one, then **Create app** → name HopAlong, category, free app.
- [ ] **Closed testing**: add at least 12 testers and run the closed test
      for 14 days before production (Play requires this for new personal
      accounts).
- [ ] Upload the `.aab` from `build/app/outputs/bundle/release/` to the
      closed-testing track; fix any pre-launch report issues.
- [ ] **Data safety form**: HopAlong collects account data (name, date of
      birth, phone, photo) and ride/chat data for the app to work. It does
      NOT collect location, and has NO payments. Fill the form to match —
      say what is collected, why, and that data is not sold or shared with
      third parties for advertising.
- [ ] **Privacy policy**: publish a privacy-policy page (your own site or a
      hosted doc) and paste its URL in Play Console. Required before the
      app can go live.
- [ ] **Content rating**: complete the questionnaire (ride-sharing / chat
      with strangers — answer honestly about user-generated content and
      reporting/blocking, which the app has).
- [ ] Store listing: short + full description, icon, feature graphic,
      at least 2 screenshots (phone), category, contact email.
- [ ] Target API: the app targets the Flutter SDK default (API 36 with
      Flutter 3.50.0). Confirm the target API level shown in Play Console
      meets Google's current requirement at submission time.

## Before you press "Go live"

- [ ] Install the release bundle on your own phone from closed testing and
      run the full flow: sign up → complete profile → post a ride →
      request it from a second account → accept → chat.
- [ ] Confirm demo mode still works with no keys (fresh install, no login
      needed for browsing sample rides).
- [ ] Delete the sample seed data from your production Supabase project
      (or use a separate project for production).
- [ ] Confirm "Confirm email" is ON in Supabase Auth for production.
