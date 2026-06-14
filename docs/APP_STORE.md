# Apple App Store submission

⚠️ **You're on Windows.** iOS apps must be **built and signed on macOS**, or by
a cloud service that provides Macs. You cannot produce an iOS build from this
machine directly. Two viable paths:

- **A cloud CI with macOS** — e.g. **Codemagic** (free tier builds & signs
  Flutter iOS apps with no Mac of your own), Bitrise, or GitHub Actions
  `macos` runners. Recommended for a Windows-only setup.
- **Borrow/rent a Mac** — any Mac with Xcode, or a rented cloud Mac
  (MacStadium, AWS EC2 mac).

The app's iOS metadata is already set: display name **"Sudoku"**, bundle id
**`net.whimsicle.sudoku_app`**, and the icon is generated into the iOS asset
catalog by `flutter_launcher_icons`.

## Steps

### 1. Apple Developer Program
- Enroll at https://developer.apple.com/programs/ — **$99/year**.

### 2. App Store Connect record
- https://appstoreconnect.apple.com → **My Apps → +** → New App.
- Platform iOS, name (distinctive — plain "Sudoku" is taken many times),
  bundle id `net.whimsicle.sudoku_app` (register it under Certificates,
  Identifiers & Profiles first), SKU.

### 3. Build & sign (on macOS or Codemagic)
- `flutter build ipa --release` produces the `.ipa` (needs signing assets).
- Signing needs an **Apple Distribution certificate** + **App Store
  provisioning profile**. Codemagic can manage these automatically if you
  give it your Apple account / API key.
- Upload via Xcode Organizer, `xcrun altool`/`notarytool`, or Codemagic's
  publish step → it appears in App Store Connect.

### 4. Required listing + privacy
- **Screenshots** for the required device sizes (6.7" and 6.5" iPhone at
  minimum) — home menu, gameplay, completion popup, leaderboard.
- **App icon** 1024×1024 (already generated from `assets/icon/icon.png`).
- **Privacy policy URL** (required) — host `server/privacy.html` publicly, e.g.
  `https://the949dude.com/sudoku/privacy.html`.
- **App Privacy "nutrition labels"** — declare collected data:
  - **Contact info → Email address** (linked to identity).
  - **User content / Identifiers → Name**.
  - **Usage data** → game results tied to your email.
  - Used for **App Functionality** (leaderboard/competition), **not** for
    tracking or ads; **not shared** with third parties.
- **Age rating** questionnaire → puzzle game, no objectionable content.

### 5. TestFlight & review
- Push a build to **TestFlight** to test with invitees first.
- Submit for review. Apple review is typically a day or two; they're stricter
  than Play about metadata, privacy accuracy, and "minimum functionality"
  (a complete game like this is fine).

## Note on the backend
Same as Play: the `/server` API is open/no-auth. Consider setting `API_KEY`
before a public launch, and be ready to honor data-deletion requests by email.
