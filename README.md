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
│   │   │   └── hint_engine.dart     # explanatory human-technique hints
│   │   ├── models/
│   │   │   ├── game_state.dart      # play state, input model, persistence
│   │   │   ├── settings.dart        # user settings (persisted)
│   │   │   └── stats.dart           # stats + daily streak (persisted)
│   │   ├── services/
│   │   │   ├── storage.dart         # shared_preferences wrapper
│   │   │   ├── daily.dart           # deterministic daily puzzle
│   │   │   └── leaderboard.dart     # pluggable leaderboard (local/remote)
│   │   ├── ui/
│   │   │   ├── home_menu.dart        sudoku_grid.dart   control_pad.dart
│   │   │   ├── game_screen.dart      settings_screen.dart  stats_screen.dart
│   │   └── main.dart
│   └── test/                 # engine, input-model, and daily tests
├── docs/backend.md           # optional thin-backend API spec
├── webplay.html              # original web UI (reference)
├── webplay/                  # original Sudoku.js (minified) + Sudoku.css
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
- **Pencil marks** (manual) and **Auto** (fill all candidate marks).
- **Highlighting** like the original: the active digit's cells glow yellow and
  its pencil-marks glow pink; the selected cell's row/column/box are shaded
  (disabled while placing with an armed digit — it just fills the number).
- **Completed-group flash**: finishing a row, column, or box blinks it twice in
  amber; placing all nine of a single digit blinks them green — so you can see
  at a glance when a number is done.
- **Undo / Redo** with full history.
- **Mistake marking** (Settings): Off, Conflicts only (logical duplicates), or
  Against solution.
- **Timer** and a "🎉 Solved!" finish.

**Explanatory hints**
- The Hint button detects the next logical step — Naked Single, Hidden Single,
  Locked Candidate (pointing), Naked Pair — and **explains the reasoning**
  (e.g. *"R7C1 can only be 7 — every other digit already appears in its row,
  column, or box"*), then offers to place it. Falls back to revealing the
  selected cell when no basic technique applies.

**Daily puzzle**
- A **deterministic puzzle-of-the-day**, seeded by the date, so every device
  gets the same puzzle with no server. Difficulty rotates by weekday
  (Mon/Tue Easy → weekend Expert).
- **Daily streak** tracking with current/longest streak.

**Statistics**
- Per-difficulty games played/won, best time, and average time.
- Daily streak and a list of recent games.

**Persistence** (via `shared_preferences`)
- The in-progress game auto-saves continuously → a **Continue** button on the
  home menu resumes it. Settings and stats persist across launches.

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

## Optional thin backend

The app needs no backend. An **optional** one adds only cross-device features
(a shared daily leaderboard and feedback). The client already speaks to it via
`lib/services/leaderboard.dart` (`RemoteLeaderboard`); today it runs against a
no-op local implementation. The API contract and suggested implementations
(Supabase / Firebase / Cloudflare Workers / a tiny Node service) are documented
in [`docs/backend.md`](docs/backend.md).

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
  correctness, hint-engine progress, daily determinism.
- `input_test.dart` — the hybrid/digit/cell input state machine, erase & pencil
  modes, armed-placement (no cell selection), and group-completion flash.
- `widget_test.dart` — generator/solver smoke tests.

## Status

Playable on Android (verified on a Pixel 5 emulator), iOS, web, and desktop.
Faithful gameplay mechanics with a clean modern look.

### Possible next steps
- Wire a real leaderboard backend (needs a cloud account; see `docs/backend.md`).
- More solving techniques (X-Wing, XY-Wing) for richer hints and finer rating.
- Store-release prep: app icon, launch screen, signing.
