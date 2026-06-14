# Google Play submission checklist

A practical, ordered checklist to get this app onto Google Play. The build side
is mostly done (signing, icon, name, App Bundle); the rest is account setup,
the listing, and required forms.

## 1. Account (one-time)
- Create a **Google Play Console** account at https://play.google.com/console
  — **$25 one-time** fee.
- Choose a developer name (shown on the listing).

## 2. Create the app
- Play Console → **Create app**.
- App name (the listing title — **pick something distinctive**; plain "Sudoku"
  is crowded, e.g. "Whimsicle Sudoku").
- Default language, app/game, free.

## 3. Upload the build
- Build it: `cd app && flutter build appbundle --release`
  → `build/app/outputs/bundle/release/app-release.aab`.
- Use a release track: **Internal testing** first (instant, invite testers by
  email), then **Production** when ready.
- **Play App Signing**: accept it when prompted (Google manages the real signing
  key; you upload with your upload key). Recommended.

## 4. Store listing assets
Prepare these (have placeholders ready; you can polish later):
- **App icon:** 512×512 PNG (a high-res version of `app/assets/icon/icon.png`).
- **Feature graphic:** 1024×500 PNG/JPG.
- **Phone screenshots:** 2–8, e.g. 1080×1920 (grab from a device/emulator —
  home menu, a game in play, the completion popup, leaderboard).
- **Short description** (≤80 chars) and **full description**.

## 5. Required forms (Play won't publish without these)
- **Privacy policy URL** — required because the app collects personal data
  (email, name). Host `server/privacy.html` (or the markdown) at a public URL,
  e.g. `https://the949dude.com/sudoku/privacy.html`, and paste the link.
- **Data safety form** — declare what's collected. For this app:
  - **Personal info:** Email address, Name — *collected*, sent off-device.
  - **App activity / other:** game results (times, hints) tied to your email.
  - Data is **encrypted in transit** (HTTPS): Yes.
  - **Data sharing** with third parties: No.
  - **Account/data deletion:** provide a contact email for deletion requests
    (the app has no in-app delete yet — see "Backend & privacy" below).
- **Content rating** questionnaire → this is a puzzle game with no sensitive
  content; it'll come back "Everyone".
- **Target audience & content** → not directed at children (it collects email),
  so set 18+ / general audience to avoid the Families program requirements.
- **Ads:** No ads → declare none.

## 6. Backend & privacy considerations for public release
The backend (`/server`) is **no-auth and open**. Before a public launch:
- Consider setting `API_KEY` in `server/config.php` so only the app can submit
  writes (the app already supports sending it; see `kBackendApiKey`).
- Be ready to honor deletion requests (delete a user's rows from
  `results` / `shares` / `notifications` by email, or wipe
  `server/data/sudoku.sqlite`).
- Emails are never shown on the global leaderboard (display name only).

## 7. Submit
- Complete the release notes, roll out to Internal testing, verify on a device,
  then promote to Production. First review can take hours to a few days.
