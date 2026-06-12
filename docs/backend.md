# Optional thin backend (daily leaderboard + feedback)

The app is **fully playable offline** — generation, solving, hints, rating,
stats, and the daily puzzle all run on-device. This backend is optional and only
adds **cross-device features**: a shared daily leaderboard and feedback.

The client already speaks to it through `lib/services/leaderboard.dart`
(`RemoteLeaderboard`). To turn it on, construct `RemoteLeaderboard('<baseUrl>')`
and provide it where `NullLeaderboard` is used today.

## API contract

The daily puzzle is **deterministic by date** (same puzzle for everyone), so the
backend only needs to store and rank times — it never generates puzzles.

### `POST /daily`
Submit a completed daily time.

```json
// request body
{ "name": "Tripp", "seconds": 312, "difficulty": 2, "date": "2026-06-11" }
```
Response: `200/201` on success. Server should validate `seconds > 0` and a
sane date, and may rate-limit by IP/device.

### `GET /daily?date=YYYY-MM-DD&limit=20`
Return the fastest times for that date, ascending by `seconds`.

```json
[
  { "name": "Ana",   "seconds": 188, "date": "2026-06-11" },
  { "name": "Tripp", "seconds": 312, "date": "2026-06-11" }
]
```

### `POST /feedback` (optional, replaces the old feedback form)
```json
{ "text": "Love the app!", "version": "1.0.0" }
```

## Suggested implementations

Any of these satisfies the contract; pick what you already use:

- **Supabase** — a `daily_times` table (`name, seconds, difficulty, date`) plus
  two PostgREST/Edge-Function routes. Fastest to stand up; has a free tier.
- **Firebase** — Firestore collection `daily/{date}/times` + a Cloud Function,
  or Firestore security rules enforcing the shape.
- **Cloudflare Workers + D1 / KV** — a tiny Worker implementing the two routes;
  cheap and globally fast.
- **A 50-line Node/Express + SQLite service** — if you want to self-host.

## Why not recreate the original 2010 server?

The original server also generated puzzles, served puzzle-of-the-day, and ran
the hint/solver brain (see the protocol table in the root `README.md`). All of
that is now on-device, so the backend's remaining job is just shared
leaderboards/feedback — a much smaller, stateless surface.
