# Building releases

## App identity
- **Name:** "Sudoku" (Android `android:label`, iOS `CFBundleDisplayName`).
  The *store listing* name can differ — see the notes in `PLAY_STORE.md` /
  `APP_STORE.md` (plain "Sudoku" is heavily used, so pick something
  distinctive for the listing, e.g. "Whimsicle Sudoku").
- **Android applicationId / iOS bundle id:** `net.whimsicle.sudoku_app`.
- **Icon:** generated from `app/assets/icon/icon.png` (+ `icon_foreground.png`
  for Android adaptive) via `flutter_launcher_icons`. To change it, replace
  those images and run `dart run flutter_launcher_icons`.

## Version & build number
Set in `app/pubspec.yaml`:
```
version: 1.0.0+1      # <marketing version>+<build number>
```
Bump the **build number** (`+N`) for every store upload (Play/App Store reject
duplicates). Bump the **version** (1.0.1, 1.1.0, …) for user-facing releases.

## Android — build the Play artifact (App Bundle)
Play wants an **`.aab`** (not an APK):
```bash
cd app
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```
This is signed with your **upload keystore** (`android/upload-keystore.jks`),
configured via `android/key.properties`.

A standalone **APK** (for sideloading / direct download) instead:
```bash
flutter build apk --release
```

### ⚠️ Keystore — back it up
`android/upload-keystore.jks` and `android/key.properties` are **gitignored**
(secrets) and exist only on this machine. **Back them up somewhere safe.**
- With **Play App Signing** (recommended, default for new apps) Google holds the
  real signing key; your upload key is recoverable if lost (request a reset).
- Without it, losing the keystore means you can never update the app.

To recreate `key.properties` on another machine, copy the `.jks` over and fill
in `android/key.properties` from `key.properties.example`.

## iOS
iOS builds require macOS + Xcode (or a cloud Mac / CI). See `APP_STORE.md`.

## Web (your own hosting)
```bash
flutter build web --release
# → build/web/  (upload its contents to e.g. the949dude.com/play)
```

## Windows / desktop (optional)
```bash
flutter build windows --release
```
