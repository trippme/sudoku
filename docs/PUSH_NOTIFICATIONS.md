# Push notifications (Firebase Cloud Messaging)

Instant notifications when a friend sends you a challenge or finishes a game
you're racing — delivered even when the app is fully closed, with no polling
delay and negligible battery cost.

**It's optional.** With nothing configured, the app still works: it falls back
to the in-app/foreground poll and the ~15-minute background `WorkManager` poll.
FCM just replaces "eventually" with "instantly". Everything below degrades
gracefully — a build with no `google-services.json` compiles and runs, and the
server simply doesn't push if no service-account key is present.

There is still **no push server to run** — Firebase (Google) hosts it. You add a
Firebase project, drop two files in place, and the existing PHP backend makes one
extra HTTP call when it stores a share/result.

## How it works

1. The app registers its FCM device token with the backend (`?r=register_token`,
   keyed by email) whenever you have an identity and notifications are on.
2. When `?r=share` or `?r=finish` inserts a row, the server looks up the
   recipient's token(s) and calls the FCM HTTP v1 API to push.
3. The phone shows the notification (foreground → a local notification; otherwise
   the OS shows it). Tapping it opens the Inbox.

```
app ──register token──▶ backend(tokens table)
friend sends share ──▶ backend ──FCM v1──▶ Google ──push──▶ your phone
```

## One-time setup

### 1. Firebase project + Android app

1. In the [Firebase console](https://console.firebase.google.com/), create a
   project (or reuse one — it can be separate from Moxie's Matches).
2. Add an **Android app** with package name **`net.whimsicle.sudoku_app`**.
3. Download the generated **`google-services.json`** and put it at:
   ```
   app/android/app/google-services.json
   ```
   That's all the client needs — the Gradle plugin auto-activates when the file
   is present (it's git-ignored and stays local). Rebuild and install.

### 2. Server: project id + service-account key

1. Firebase console → **Project settings → General** → copy your **Project ID**
   into `server/config.php`:
   ```php
   const FCM_PROJECT_ID = 'your-project-id';
   ```
2. **Project settings → Service accounts → Generate new private key**. Save the
   downloaded JSON on the949dude.com as:
   ```
   server/data/fcm-service-account.json
   ```
   The `data/` directory is already blocked from the web (`.htaccess`) and
   git-ignored, so the key stays private. **Never commit it.**
3. Upload the updated `server/` (`index.php`, `fcm.php`, `config.php`) to your
   host. The `tokens` table is created automatically on the next request.

Requirements on the host: PHP with `curl` and `openssl` (both standard). The
server caches the OAuth access token in `server/data/fcm-access-token.json`
(also git-ignored) and refreshes it hourly.

## Verifying

1. With both files in place, rebuild + install the app, open it, set your email,
   and allow notifications.
2. Check the token registered:
   `curl "https://the949dude.com/sudoku/index.php?r=health"` should be `ok`, and
   after opening the app the `tokens` table will have a row.
3. From another account/device, send a challenge. The recipient should get a
   notification within a second or two — **even with the app closed**.

If a push doesn't arrive, the app still catches it on next open/resume and via
the background poll, so you never miss it — push just makes it instant.

## iOS

Android works with just `google-services.json`. iOS additionally needs an **APNs
authentication key** uploaded to Firebase (Project settings → Cloud Messaging →
Apple app configuration) and the Push Notifications capability in Xcode. That's
a follow-up when the iOS build is set up; the code path is already cross-platform.
