# Sudoku

A rewrite of an old web Sudoku ("Enjoy Sudoku for the Web", 2010) as a
cross-platform **Flutter** app for Android & iOS, with all game logic running
on-device (offline). An optional thin backend (leaderboards, daily puzzle,
feedback) can be added later.

## Layout

```
.
├── app/            # The new Flutter app (Android / iOS / web / Windows)
├── webplay.html    # Original web UI (reference)
├── webplay/        # Original Sudoku.js (minified) + Sudoku.css (reference)
├── images/         # Original art assets (reference)
└── README.md
```

## Running the app

```bash
cd app
flutter pub get
flutter run            # pick a device, or:
flutter run -d chrome  # run in the browser
```

## App architecture

- `app/lib/engine/sudoku_engine.dart` — the on-device "server replacement":
  backtracking solver, uniqueness checker, puzzle **generator**, and a
  human-technique **difficulty rater** (naked/hidden singles, locked
  candidates, naked pairs → Easy/Medium/Hard/Expert).
- `app/lib/models/game_state.dart` — play state: moves, pencil marks,
  undo/redo, timer, mistake detection, hints.
- `app/lib/ui/` — the grid and control pad.

## Recovered original server protocol (for reference)

The original 2010 app was a **thin client + server** at `enjoysudoku.com/cgi`.
The server code was lost; this is what the client expected, reconstructed from
the minified JS. We are **not** reproducing this — the new app does it all
locally — but it is documented here so the knowledge is preserved.

| Purpose | Request | Response |
|---|---|---|
| Puzzle of the day | `GET /cgi/q?game=<A–L>` (A–L = the 12 difficulty levels) body `confirm=1` | `<81-char puzzle>` + ` # ` + `<id>` |
| Tutorial/practice boards | `GET /puzzles/V3<letter><day>.txt` | static 81-char board text |
| Hint engine | `POST /cgi/q?hint&nomedusa` body `board=<81 chars>` | `OK-<human-technique hint text>` |
| Completion / stats | `GET /cgi/q?done=<id>&time=<s>&ap=<0/1>&pure=<0/1>&penalty=<s>&incorrect=<n>[&again]` body `confirm=1` | `OK-<your-time-vs-others text>` |
| Feedback | `GET /thanks.html?overall=W2.0&comments=<urlencoded>` | thank-you page |

Puzzle string: 81 chars, row-major, `0`/blank char = empty cell. The original
hint/rating brain lived on the server; in the rewrite it lives in
`sudoku_engine.dart`.

## Status

Playable prototype: generate puzzles at 4 difficulties, place digits, pencil
marks, erase, undo/redo, hint, mistake highlighting, timer, win detection.
