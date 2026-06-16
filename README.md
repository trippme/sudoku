# Sudoku

A modern rewrite of an old web Sudoku — *"Enjoy Sudoku for the Web"* (2010) — as
a cross-platform **Flutter** app for Android & iOS (also runs on web, Windows,
macOS, Linux). All game logic — puzzle generation, solving, difficulty rating,
and hints — runs **entirely on-device**, so the app works fully offline. The
original server code was lost; everything it did has been rebuilt locally.

Repo: https://github.com/trippme/sudoku

## Layout

```
.
├── app/                      # The Flutter app
│   ├── lib/
│   │   ├── engine/
│   │   │   ├── sudoku_engine.dart   # solver, uniqueness, generator, rater
│   │   │   └── hint_engine.dart     # progressive human-technique hints
│   │   ├── models/
│   │   │   ├── game_state.dart      # play state, input model, persistence
│   │   │   ├── settings.dart        # user settings, incl. theme + daily diff.
│   │   │   ├── profile.dart         # name/email identity + friends
│   │   │   └── stats.dart           # stats + daily streak (persisted)
│   │   ├── services/
│   │   │   ├── storage.dart         # shared_preferences wrapper
│   │   │   ├── game_catalog.dart    # game# → puzzle, daily, difficulty bands
│   │   │   ├── leaderboard.dart     # remote leaderboard / friends / inbox
│   │   │   ├── notifications.dart   # local notifications + new-item dedup
│   │   │   ├── background.dart      # WorkManager background poll (Android)
│   │   │   └── push.dart            # optional Firebase Cloud Messaging
│   │   ├── ui/
│   │   │   ├── home_menu.dart        sudoku_grid.dart      control_pad.dart
│   │   │   ├── game_screen.dart      settings_screen.dart  stats_screen.dart
│   │   │   ├── leaderboard_screen.dart  inbox_screen.dart
│   │   │   └── theme.dart            # light/dark themes + board colour palette
│   │   └── main.dart
│   └── test/                 # engine, input-model, daily, notification tests
├── server/                   # no-auth PHP backend (leaderboard, inbox, push)
│   ├── index.php             # the API (routes, rate limiting, API key)
│   ├── fcm.php               # Firebase Cloud Messaging sender (HTTP v1)
│   ├── config.php            # DB + API key + Firebase config
│   └── data/                 # SQLite DB + secrets (git-ignored, web-blocked)
├── deploy.bat / sideload.bat # Windows: sync + build + install to phones
├── distribute.bat            # Windows: build + push to Firebase App Distribution
├── docs/                     # backend, release, store, push, distribution guides
├── webplay.html  webplay/    # original web UI + minified Sudoku.js (reference)
├── images/                   # original art assets (reference)
└── README.md
```

## Running

```bash
cd app
flutter pub get
flutter run               # pick a device, or:
flutter run -d chrome     # browser
flutter run -d windows    # desktop window
flutter run -d <emulator> # Android emulator / iOS simulator
```

Run the tests:

```bash
cd app
flutter test
```

### Build & deploy to your Android phone(s) (Windows)

With a USB-connected phone that has **USB debugging** enabled, double-click
`deploy.bat` (or run it from a terminal). It does the **complete** flow:

```bat
deploy.bat            REM git pull + RELEASE build + install to all devices
deploy.bat debug      REM same, DEBUG build (faster; keeps app data)
deploy.bat --no-pull  REM skip the git sync (build current local code)
```

`deploy.bat` **syncs the repo first** (`git pull`) so you build what you merged
on GitHub — then builds once and installs + launches on **every** connected
device. `sideload.bat` is the same thing with the git pull skipped.

Release builds are signed with the upload keystore if `android/key.properties`
is present (see below), otherwise debug keys. (Deploying the *server* to your
web host is separate — that's just uploading `server/`.)

### Releasing & distribution

- **Build guide:** [`docs/RELEASE.md`](docs/RELEASE.md) — App Bundle / APK / web
  builds, versioning, and the signing keystore (with backup warning).
- **Beta testing (Firebase App Distribution):**
  [`docs/APP_DISTRIBUTION.md`](docs/APP_DISTRIBUTION.md) — get builds to testers
  with no store/review; `distribute.bat` builds + uploads in one command.
- **Google Play:** [`docs/PLAY_STORE.md`](docs/PLAY_STORE.md) — full submission
  checklist (account, listing, data-safety form, content rating).
- **Apple App Store:** [`docs/APP_STORE.md`](docs/APP_STORE.md) — the path for a
  Windows machine (build on a cloud Mac / Codemagic).
- **Privacy policy:** [`server/privacy.html`](server/privacy.html) — host it
  publicly (both stores require a privacy-policy URL since the app collects an
  email for online play).
- App icon is generated from `app/assets/icon/` via `flutter_launcher_icons`.

## Features

**Gameplay (matches the original "Enjoy Sudoku" feel)**
- Four difficulties — Easy, Medium, Hard, Expert — each rated by the hardest
  human technique required (see *Engine* below).
- **Input model faithful to the original**, selectable in Settings:
  - **Hybrid** (default): tap a digit *or* a cell first; the app follows your
    lead. A selected digit turns green and stays armed so you can fill many
    cells; re-tapping it deselects.
  - **Digit, then cell** / **Cell, then digit** modes.
- Tapping a digit already in a cell **removes it** (toggle). **Erase** is a
  selectable mode (not a one-shot).
- **Pencil marks** (manual) and **Auto** — a toggle that fills every empty
  cell's candidate marks, and clears them again when tapped off.
- **Highlighting** like the original: the active digit's cells glow yellow and
  its pencil-marks glow pink; the selected cell's row/column/box are shaded
  (disabled while placing with an armed digit — it just fills the number).
- **Completed-group flash**: finishing a row, column, or box blinks it twice in
  amber; placing all nine of a single digit blinks them green — so you can see
  at a glance when a number is done.
- **Undo / Redo** with full history.
- **Mistake marking** (Settings): Off, Conflicts only (logical duplicates), or
  Against solution.
- **Dark mode** (Settings → Appearance): Match system (default), Light, or Dark.
  The whole board — grid, keypad, highlights — is theme-aware, not just the
  Material chrome.
- **Timer** and a "🎉 Solved!" finish.

**Progressive hints** (like the original)
- The Hint button reveals in escalating stages with **Back / More / Done**,
  shown in a bottom sheet so the board stays visible:
  1. *"Examine the digit 7."* — every 7 on the board glows.
  2. *"Hidden Single (box): where in box 5 can you put a 7?"* — the region
     shades green.
  3. *"Only R6C4 can be 7."* — the answer cell is highlighted; **Place it** fills
     it, or close it and place it yourself.
- It leads with the **easiest-to-spot** technique (a box-scan hidden single
  before a naked single) and supports Hidden/Naked Single, Locked Candidate
  (pointing), and Naked Pair. Falls back to revealing the selected cell when no
  basic technique applies.

**Daily puzzle**
- A **deterministic puzzle-of-the-day**, seeded by the date, so every device
  gets the same puzzle with no server. Its difficulty is a setting
  (Settings → Daily puzzle): **Match the day** (weekday rotation, Mon/Tue easy →
  weekend expert) or a fixed Easy/Medium/Hard/Expert.
- **Daily streak** tracking with current/longest streak.

**Statistics**
- Per-difficulty games played/won, best time, and average time.
- Daily streak and a list of recent games.

**Persistence** (via `shared_preferences`)
- In-progress games auto-save continuously, one slot per difficulty band plus
  one for the daily, so several games can be mid-flight at once — the home menu
  lists them under **In Progress** to resume or discard. Settings and stats
  persist across launches.

**Online (optional — needs the backend deployed)**
- Every game has a **shareable number** (the seed; it also encodes difficulty),
  shown in the game screen. **Play by Number** opens any game; **Share** copies
  a "beat my time on game #N" challenge.
- A **profile** (display name + email, no password) identifies you; counts of
  **hints and mistakes** are tracked per game.
- On finishing, your result is submitted and your **rank** is shown. A
  **Leaderboard** screen shows the global top times and your **friends'**
  results for that game (ranked fewest hints, then fastest). Add friends by
  email in Settings. All of this fails soft when offline.
- **Proactive notifications:** when a friend sends you a challenge or finishes a
  game you're racing, you get an on-device notification. Toggle it in
  Settings → *Notifications*. Two delivery paths:
  - **Polling (always on, no setup):** the app polls the backend while open (a
    30-second foreground timer, plus launch/resume) and in the background
    (Android `WorkManager`, ~15-min floor), de-duped so each item notifies once.
  - **Push (optional, instant):** wire up Firebase Cloud Messaging and challenges
    arrive within a second or two even with the app closed. No push server to
    run — Google hosts it; the PHP backend just makes one extra call on
    share/finish. Setup: [`docs/PUSH_NOTIFICATIONS.md`](docs/PUSH_NOTIFICATIONS.md).
    The app builds and runs fine without it (falls back to polling).

## Engine (the "server replacement")

`app/lib/engine/sudoku_engine.dart` runs locally what the original needed a
server for:

- **Solver** — backtracking with the minimum-remaining-values heuristic.
- **Uniqueness check** — counts solutions up to 2 to guarantee a single answer.
- **Generator** — builds a full grid, then digs holes (180°-symmetrically)
  while keeping the solution unique, targeting the requested difficulty.
- **Difficulty rater** — a logical solver that applies human techniques in
  order (naked/hidden singles → locked candidates → naked pairs) and grades by
  the hardest one needed: Easy / Medium / Hard / Expert.

`app/lib/engine/hint_engine.dart` reuses the same techniques to produce
explained, structured hints (placements and candidate eliminations).

## Backend (leaderboard, friends, inbox, push)

The app needs no backend to play, but one is **deployed and live** for the
cross-device social features: a shared leaderboard, friend competition on the
same game number, sending games to a friend's in-app inbox, per-player history
synced by email (no login), and push notifications.

A single-file **PHP** API lives in [`server/`](server) (SQLite by default,
MySQL optional — ordinary web hosting). Because puzzles are deterministic from
their game number, the server stores **only results, shares, and device
tokens** — never puzzles or board state — so it stays tiny. The client talks to
it via `lib/services/leaderboard.dart` (`RemoteLeaderboard`) and
`lib/services/push.dart`.

Identity is **email only, no password** — deliberately, for a friends app. To
keep that from being wide open, the API is hardened proportionately:

- **API key** on every route (except `health`) via an `X-Api-Key` header. The
  key lives in `server/data/api-key.txt` (git-ignored, web-blocked) and is
  injected into the app at build time (`--dart-define`), so it's never in the
  repo. A deterrent against drive-by/browser abuse — not strong auth, since it
  ships in the APK.
- **Per-IP rate limiting** (the real anti-abuse protection): a generous overall
  cap plus tighter caps on the write routes most prone to spam.
- **No CORS** advertised — the API is for the mobile app, so a browser on
  another site can't drive it.
- Prepared statements throughout (no SQL injection), input validation, HTTPS
  only, and secrets (`api-key.txt`, the Firebase service-account key, the
  SQLite DB) git-ignored and blocked from the web by `.htaccess`.

See [`server/README.md`](server/README.md) to deploy, [`docs/backend.md`](docs/backend.md)
for the design, and [`docs/PUSH_NOTIFICATIONS.md`](docs/PUSH_NOTIFICATIONS.md)
for the optional Firebase Cloud Messaging setup.

## Recovered original server protocol (reference)

The original 2010 app was a **thin client + server** at `enjoysudoku.com/cgi`.
The server code was lost; this is what the client expected, reconstructed from
the minified JS. We are **not** reproducing it — the new app does everything
locally — but it is preserved here so the knowledge isn't lost again.

| Purpose | Request | Response |
|---|---|---|
| Puzzle of the day | `GET /cgi/q?game=<A–L>` (A–L = the 12 difficulty levels) body `confirm=1` | `<81-char puzzle>` + ` # ` + `<id>` |
| Tutorial/practice boards | `GET /puzzles/V3<letter><day>.txt` | static 81-char board text |
| Hint engine | `POST /cgi/q?hint&nomedusa` body `board=<81 chars>` | `OK-<human-technique hint text>` |
| Completion / stats | `GET /cgi/q?done=<id>&time=<s>&ap=<0/1>&pure=<0/1>&penalty=<s>&incorrect=<n>[&again]` body `confirm=1` | `OK-<your-time-vs-others text>` |
| Feedback | `GET /thanks.html?overall=W2.0&comments=<urlencoded>` | thank-you page |

Puzzle string: 81 chars, row-major, blank char = empty cell. The original
hint/rating brain lived on the server; in the rewrite it lives in
`sudoku_engine.dart` and `hint_engine.dart`.

## Tests

`app/test/` covers the engine and gameplay:
- `engine_test.dart` — generation is unique/solvable per difficulty, solver
  correctness, progressive hints (easiest-first, staged), daily determinism and
  the daily-difficulty override.
- `input_test.dart` — the hybrid/digit/cell input state machine, erase & pencil
  modes, the auto-pencil toggle, armed-placement, and group-completion flash.
- `notification_service_test.dart` — the "what's new since last poll"
  high-water-mark dedup logic.
- `widget_test.dart` — generator/solver smoke tests.

## Status

Playable and **in active beta** on Android, distributed to testers via Firebase
App Distribution (`distribute.bat`). Also runs on iOS, web, and desktop.

Live and verified:
- Full faithful gameplay, progressive hints, dark mode, per-difficulty saves.
- Backend deployed to a PHP host: leaderboard, friends, inbox, history.
- Push notifications via Firebase Cloud Messaging (instant, app-closed) with a
  polling fallback.
- API hardened (key + per-IP rate limiting + locked-down CORS).

### Possible next steps
- **iOS push:** add an APNs key in Firebase + the Push capability (the code path
  is already cross-platform).
- Store submission (Google Play / App Store) — see the `docs/` guides.
- More solving techniques (X-Wing, XY-Wing) for richer hints and finer rating.
