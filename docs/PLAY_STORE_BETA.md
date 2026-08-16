# Play Store beta testing — how-to (Sudoku / Android)

Goal: distribute the Android app for **beta testing through the Google Play Store**
(testers install via the normal Play Store app), instead of the Firebase App
Distribution "app tester" app.

Project facts referenced below:
- Flutter project root is **`app/`** (NOT the repo root — `flutter` commands fail
  from the repo root with "No pubspec.yaml file found").
- Current version: **`1.0.0+2`** in `app/pubspec.yaml` (`versionName+versionCode`).
- Android package name: **`net.whimsicle.sudoku_app`** (permanent once the Play app is created).
- Release signing: upload keystore via `app/android/key.properties` (git-ignored).
- Backend API key: `server/data/api-key.txt` (git-ignored) — must be injected at
  build time or the installed app can't reach the key-protected backend.
- Privacy policy: `server/privacy.html` (host it and use its URL in Play Console).
- Store-listing copy drafted in: `docs/APP_STORE_LISTING.md`.

---

## Key idea
- **The Play Store takes an AAB (`.aab`), not an APK.** (An APK is only for direct
  sideloading onto a phone — see the appendix.)
- **"Beta via Play Store" = a Play testing track.** Start with **Internal testing**:
  up to 100 testers, near-instant, minimal review. Testers join via an opt-in link
  and install from the Play Store.

---

## 1. Build the AAB
From PowerShell:

```powershell
cd app
$key = Get-Content ..\server\data\api-key.txt -Raw
flutter build appbundle --release `
  --dart-define=BACKEND_API_KEY=$key `
  --dart-define=GIT_SHA=$(git rev-parse --short HEAD) `
  --dart-define=BUILD_TIME=$(Get-Date -Format yyyy-MM-dd_HH:mm)
```

Output:
```
app\build\app\outputs\bundle\release\app-release.aab
```

(Optional: a `release.bat` can be added to automate this like `deploy.bat` does
for the APK. Not created yet.)

---

## 2. Play Console — one-time app setup (web UI, your part)
1. **Google Play Console account** — $25 one-time registration, if not already done.
2. **Create app**: name (e.g. "Tripp's Sudoku"), default language English, type App, Free.
3. Work the **Dashboard → "Set up your app"** checklist. Even to test, Google requires:
   - **Privacy policy URL** → the hosted URL of `server/privacy.html`.
   - **Data safety** form.
   - **Content rating** questionnaire.
   - **Target audience & content**.
   - **Ads** declaration = no ads.
   - Store listing (short + full description, icon, screenshots, feature graphic) —
     copy is in `docs/APP_STORE_LISTING.md`.

---

## 3. Push a build to Internal testing (repeat each release)
4. **Testing → Internal testing → Create new release.**
5. First upload prompts **Play App Signing** — **accept it**. Your `key.properties`
   becomes the *upload* key; Google holds the real *app signing* key and re-signs
   each release. (Standard and required. It also means the app's public signing
   cert/SHA on Play differs from your local keystore — matters only if you later add
   services like Google Sign-In.)
6. **Upload** `app-release.aab`.
7. Add release notes → **Review → Roll out to internal testing.**
8. **Testers tab** → create an email list → add testers' Gmail addresses → Save →
   copy the **opt-in URL** → send it to testers. They open it, accept, and install
   from the **Play Store** (no app-tester app).

---

## Gotchas (read before uploading)
- **AAB, not APK** — Play rejects APK uploads for new apps.
- **versionCode must increase on EVERY upload.** Currently `1.0.0+2`. Bump the
  `version:` line in `app/pubspec.yaml` for each new upload (`1.0.0+3`, `+4`, …),
  or pass `--build-number=N`. Play rejects a re-used versionCode.
- **Package name `net.whimsicle.sudoku_app` is permanent** once the Play app exists.
- **Production gate:** personal Play accounts created after ~Nov 2023 must run a
  **closed test with ≥12 testers for 14 days** before publishing to *Production*.
  Does NOT block internal testing, but plan the closed test before public launch.
- **Target API level:** Play requires targetSdk within ~1 year of the latest Android.
  If Play flags it, bump `targetSdkVersion` in `app/android/app/build.gradle`.

---

## Track progression (when you outgrow internal testing)
Internal testing (≤100, instant) → **Closed testing** (bigger groups, needs the full
app setup + review) → **Open testing** (public opt-in) → **Production**.
The 12-testers/14-days rule is satisfied via a **Closed** test.

---

## Appendix — direct install on a phone (no Play, no tester app)
For putting a build straight on YOUR OWN Android phone over USB:

```
.\deploy.bat
```
(from repo root, phone plugged in with USB debugging on). It syncs to `main`, builds
a **release APK** with the API key + stamp injected, and installs + launches it.

Or build just the APK file to copy over:
```powershell
cd app
$key = Get-Content ..\server\data\api-key.txt -Raw
flutter build apk --release --dart-define=BACKEND_API_KEY=$key
# -> app\build\app\outputs\flutter-apk\app-release.apk
```
Note: if a differently-signed build (e.g. an earlier Play/App Distribution build) is
already installed, uninstall it first or the install-over will fail (clears app data).

---

## iOS note (for later)
iOS beta = **TestFlight** (via the existing `ios-testflight` Codemagic workflow),
or direct-install via an **Ad Hoc** build (needs the device UDID registered; the
`ios-adhoc` Codemagic workflow for that was drafted in PR #68, which was closed —
reopen if wanted). iOS push is already working end-to-end.
