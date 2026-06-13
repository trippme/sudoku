# Backend (leaderboard, friend competition, history)

The app is **fully playable offline** — generation, solving, hints, rating,
stats, and the daily puzzle all run on-device. The backend is optional and only
adds **cross-device social features**: a shared leaderboard, friend
competition, sharing a game by number, and per-player history synced by email.

The implementation lives in [`/server`](../server) — a small **no-auth PHP API**
(SQLite by default, MySQL optional) meant to run on ordinary web hosting at no
extra cost. See [`server/README.md`](../server/README.md) for deploy steps.

## Why this is cheap

Puzzles are **deterministic from their game number** (the seed). "Game #1234"
is the same puzzle for everyone and is generated on-device, so the server never
stores puzzles or board state — only finished **results**. That's one small row
per game per player. No Firebase needed.

Ranking everywhere: **fewest hints, then fastest time.**

## Data model (one table)

`results(game_id, email, name, seconds, hints, mistakes, difficulty, tries, finished_at)`
with a unique `(game_id, email)` — each player's best per game.

## API

Base URL is the folder the API lives in, e.g. `https://yourhost/sudoku`.
Routes are passed as `?r=`:

| Route | Method | Params | Purpose |
|---|---|---|---|
| `?r=health` | GET | — | Liveness check |
| `?r=result` | POST | JSON `{gameId,email,name,seconds,hints,mistakes,difficulty}` | Submit a finished game |
| `?r=leaderboard` | GET | `game`, `limit` | Global top times (display names only) |
| `?r=friends` | GET | `game`, `emails` (comma list) | Results for specific friends |
| `?r=player` | GET | `email`, `limit` | One player's history |

The full request/response shapes and `curl` examples are in
[`server/README.md`](../server/README.md).

## Client wiring

`app/lib/services/leaderboard.dart` already speaks this contract:

- `NullLeaderboard` — offline no-op (default; the app runs with no backend).
- `RemoteLeaderboard('https://yourhost/sudoku')` — the live client. Pass an
  `apiKey` too if the server sets one.

Switch the app over by constructing `RemoteLeaderboard(<baseUrl>)` where the app
currently uses `NullLeaderboard`.

## Feature mapping

- **Leaderboard** → `?r=leaderboard&game=<id>`.
- **Save your info (just email)** → results are keyed by email; `?r=player`
  returns your history to sync across devices.
- **Friend competition** → both submit for the same `game_id`; the app calls
  `?r=friends&game=<id>&emails=…` and shows you side by side.
- **Share "I'm stuck on #1234"** → share the number + a deep link; the friend
  opens the same deterministic puzzle and the app can show how each is doing.

## Privacy / auth

No login by design. Emails are never shown on the public leaderboard (display
name only); they're returned only to friend lookups, where both sides already
know each other's address. An optional `API_KEY` (server `config.php`) can gate
submissions behind a shared key if you want to deter random writes.

## Still on the client side (next steps)

To light these features up in the app:
- Capture a display name + email once (no password).
- Count hints and mistakes during a game (for submission/ranking).
- "Play game by number" + "Share game" (the engine already generates by seed).
- A leaderboard / friends screen, and submit-on-completion.
