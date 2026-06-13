# Sudoku backend (PHP)

A tiny, no-auth REST API for the Sudoku app's leaderboard, friend competition,
and per-player history. Email is the identity (no passwords). Puzzles are
deterministic from their game number, so the server stores **only results** —
never puzzles or board state.

Ranking everywhere: **fewest hints, then fastest time.**

## Files

```
server/
├── index.php        # the whole API (single file)
├── config.php       # DB choice + optional API key
├── .htaccess        # blocks web access to *.sqlite
└── data/            # holds the SQLite DB (blocked from the web)
```

## Deploy (SQLite — no database setup)

1. Upload the `server/` folder to your host, e.g. to `…/public_html/sudoku/`.
2. Make sure `server/data/` is writable by the web server (often already is;
   otherwise `chmod 775 data`).
3. Done. Visit `https://yourhost/sudoku/index.php?r=health` — you should see
   `{"ok":true,"service":"sudoku",...}`. The database file is created
   automatically on first use.

That's it — no MySQL, no config. The base URL for the app is the folder URL,
e.g. `https://yourhost/sudoku`.

### Prefer MySQL?

If your host gives you MySQL and you'd rather use it, edit `config.php`:
set `DB_DRIVER` to `'mysql'` and fill in `MYSQL_DSN/USER/PASS`. The table is
created automatically.

### Optional: require a key for submissions

In `config.php`, set `API_KEY` to any secret string. Then the app must send it
as an `X-Api-Key` header when submitting results (reads stay open). Leave it
empty for fully open — fine for a friends leaderboard.

## API

All responses are JSON with an `ok` boolean. Pass the route as `?r=`.

| Route | Method | Params | Purpose |
|---|---|---|---|
| `?r=health` | GET | — | Liveness check |
| `?r=result` | POST | JSON body (below) | Submit a finished game |
| `?r=leaderboard` | GET | `game`, `limit` | Global top times for a game (names only) |
| `?r=friends` | GET | `game`, `emails` (comma list) | Results for specific friends |
| `?r=player` | GET | `email`, `limit` | One player's history (cloud sync) |
| `?r=share` | POST | JSON `{fromEmail,fromName,toEmail,gameId,message}` | Send a game to a friend's inbox |
| `?r=inbox` | GET | `email`, `limit` | Games sent to you (newest first) |
| `?r=seen` | POST | JSON `{id,email}` | Mark a received game as seen |

**POST `?r=result`** body:
```json
{
  "gameId": 1234,
  "email": "you@example.com",
  "name": "Tripp",
  "seconds": 312,
  "hints": 0,
  "mistakes": 1,
  "difficulty": 2
}
```
Keeps one row per `(gameId, email)` — your best, by fewest hints then time.
Returns `{ok, improved, rank, total}`.

**GET `?r=leaderboard&game=1234&limit=20`** →
```json
{ "ok": true, "gameId": 1234, "entries": [
  { "name": "Ana", "seconds": 188, "hints": 0, "mistakes": 0, "difficulty": 2, "finished_at": "2026-06-12 14:02:11" }
]}
```

**GET `?r=friends&game=1234&emails=you@x.com,sam@y.com`** → same shape, but
includes `email` (friends share emails).

**GET `?r=player&email=you@x.com`** → that player's recent results across games.

**POST `?r=share`** body `{fromEmail, fromName, toEmail, gameId, message}` →
`{ok}`. Drops a game into `toEmail`'s inbox.

**GET `?r=inbox&email=you@x.com`** →
```json
{ "ok": true, "email": "you@x.com", "shares": [
  { "id": 7, "from_email": "sam@y.com", "from_name": "Sam", "game_id": 1234,
    "message": "beat this", "seen": 0, "created_at": "2026-06-13 05:00:00" }
]}
```

**POST `?r=seen`** body `{id, email}` → `{ok}`. Marks that received game read.

## Test it (curl)

```bash
BASE="https://yourhost/sudoku/index.php"

curl "$BASE?r=health"

curl -X POST "$BASE?r=result" -H "Content-Type: application/json" -d \
  '{"gameId":1234,"email":"you@example.com","name":"Tripp","seconds":312,"hints":0,"mistakes":1,"difficulty":2}'

curl "$BASE?r=leaderboard&game=1234"
curl "$BASE?r=friends&game=1234&emails=you@example.com"
curl "$BASE?r=player&email=you@example.com"
```

## Run locally (optional)

With PHP installed:
```bash
cd server
php -S localhost:8080
# then BASE="http://localhost:8080/index.php"
```

## Notes / privacy

- No authentication: anyone who knows the URL can submit. With `API_KEY` set,
  submissions need the shared key. Either way, emails are never shown on the
  public leaderboard (display name only) — they're only returned to friend
  lookups, where both sides already know each other's address.
- The whole dataset is small (one row per game per player), so SQLite is plenty.
