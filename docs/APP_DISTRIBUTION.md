# Firebase App Distribution

Get release builds to testers' phones **without the Play Store or any review** —
they get an email and install via a link / the "Firebase App Tester" app. Good
for beta testing before a public store release.

The Firebase project (`sudoku-a0bba`) and Android app are already set up (the
same project used for push notifications).

## One-time setup

1. **Enable it:** Firebase console → *Release & Monitor → App Distribution →
   Get started*. (The first upload can also enable it.)
2. **Add testers:** add tester emails individually, or create a **group** (the
   `distribute.bat` script defaults to the group alias `tester`). Each tester
   gets an invite email; they accept once, then install each new build from the
   App Tester app or a direct link. Note the group **alias** (shown by
   `firebase appdistribution:group:list`) — that's what `--groups` needs, and it
   can differ from the display name.
3. **Firebase CLI** (already installed + logged in as `trippme@whimsicle.net`):
   ```
   npm install -g firebase-tools   # if not installed
   firebase login                  # if not logged in
   ```

## Distributing a build

One command — builds a release APK (signed with your upload keystore) and
uploads it:

```bat
distribute.bat                 REM build + upload to the "tester" group
distribute.bat beta            REM upload to a different group
distribute.bat tester --no-pull    REM skip the git sync, build local code
```

Under the hood it runs:

```
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app 1:186440557207:android:cde025183a562c667e7fd2 \
  --groups <group> \
  --release-notes "<last commit subject> (<git sha>)"
```

Notes:
- Distribute the **APK**, not the AAB — testers install it directly. (AAB is only
  for Play Store test tracks.)
- The build is signed with the upload keystore (`android/key.properties`), so it
  installs like any sideloaded app — no Play app-signing involved.
- The in-app version footer shows the git sha + build time, so testers can tell
  you exactly which build they're on.

## iOS

iOS distribution through Firebase additionally needs an Apple Developer account,
an ad-hoc/development provisioning profile (with each tester device's UDID
registered), and an `.ipa` built on a Mac/cloud-Mac. The Android flow above is
self-contained; iOS is a follow-up when the iOS build is set up.
