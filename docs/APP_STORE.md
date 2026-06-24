# Apple App Store submission (via Codemagic)

⚠️ **You're on Windows.** iOS apps must be **built and signed on macOS**. We use
**Codemagic** (the same service you use for Moxie's Matches) to build, sign, and
upload to TestFlight from the cloud — there's a committed **`codemagic.yaml`** at
the repo root that drives this.

The app's iOS metadata is already set: display name **"Sudoku"**, bundle id
**`net.whimsicle.sudokuApp`** (note: no underscore — iOS bundle ids disallow it),
deployment target **iOS 13** (Firebase's floor), and the icon is generated into
the iOS asset catalog by `flutter_launcher_icons`.

## One-time account setup

### 1. Apple Developer Program
Already enrolled (Moxie's Matches account). The Sudoku app reuses it.

### 2. Register the bundle id + App Store Connect record
- Certificates, Identifiers & Profiles → **Identifiers** → register
  `net.whimsicle.sudokuApp`. **Enable the Push Notifications capability** on it
  (needed for FCM — see "iOS push" below).
- https://appstoreconnect.apple.com → **My Apps → +** → New App: iOS, a
  distinctive name (plain "Sudoku" is taken many times), bundle id
  `net.whimsicle.sudokuApp`, SKU.

### 3. Wire up Codemagic
`codemagic.yaml` references two things you set in the Codemagic UI:
- **App Store Connect API key** (Team settings → Integrations). Add your key and
  put its **name** into `codemagic.yaml` where it says `<ASC_API_KEY_NAME>`.
  This lets Codemagic auto-manage the distribution certificate + provisioning
  profile and upload to TestFlight.
- **Environment variable group `sudoku`** (mark *Secure*):
  - `BACKEND_API_KEY` = contents of `server/data/api-key.txt`. Without it the
    released app gets HTTP 401 from the key-protected backend.

Then trigger the **`ios-testflight`** workflow. It runs `flutter build ipa` with
a unique `$BUILD_NUMBER`, signs, and submits to TestFlight.

## iOS push notifications (Firebase Cloud Messaging)

Android push already works. iOS needs a few Apple/Firebase steps that only you
can do (the code side — background mode, Podfile, iOS 13 target — is wired up;
the `GoogleService-Info.plist` + entitlement land once you provide the plist):

1. **Firebase Console → project `sudoku-a0bba` → Add app → iOS.** Bundle id
   `net.whimsicle.sudokuApp`. Download the generated **`GoogleService-Info.plist`**
   and hand it over — it gets added to `app/ios/Runner/` and the Xcode project,
   and the `aps-environment` entitlement is wired at the same time.
2. **APNs auth key.** Apple Developer → Keys → create an **APNs key** (.p8),
   then upload it in Firebase → Project settings → Cloud Messaging → Apple app.
   This is what lets FCM deliver to iOS.
3. **Push capability** on the App ID (step 2 of account setup) — Codemagic's
   automatic signing provisions the `aps-environment` entitlement once enabled.

Until those are done, iOS builds still succeed and ship to TestFlight — push just
stays inactive (it degrades gracefully, exactly like an Android build with no
Firebase config).

## Required listing + privacy
- **Screenshots** for the required device sizes (6.9"/6.7" and 6.5" iPhone at
  minimum) — home menu, gameplay, completion popup, leaderboard.
- **App icon** 1024×1024 (generated from `assets/icon/icon.png`).
- **Privacy policy URL** (required) — host `server/privacy.html` publicly, e.g.
  `https://the949dude.com/sudoku/privacy.html`.
- **App Privacy "nutrition labels"** — declare collected data:
  - **Contact info → Email address** (linked to identity).
  - **User content / Identifiers → Name**.
  - **Usage data** → game results tied to your email.
  - Used for **App Functionality** (leaderboard/competition), **not** for
    tracking or ads; **not shared** with third parties.
- **Age rating** questionnaire → puzzle game, no objectionable content.

## TestFlight & review
- `codemagic.yaml` publishes to **TestFlight** automatically
  (`submit_to_testflight: true`). Test with invitees first.
- When ready for public release, submit for App Store review from App Store
  Connect. Apple review is typically a day or two and stricter than Play about
  metadata + privacy accuracy.

## Backend
The `/server` API is **key-protected** (per-IP rate limits + `BACKEND_API_KEY`).
The released iOS app must be built with that key injected (the `sudoku` env group
above). Be ready to honor data-deletion requests by email.
