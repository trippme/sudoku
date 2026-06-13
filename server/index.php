<?php
// =============================================================================
// Sudoku backend — single-file PHP API (no auth; email is the identity).
//
// Puzzles are deterministic from their game number (seed), so the server never
// stores puzzles or board state — only finished results. One row per
// (game_id, email); we keep each player's best, ranked by fewest hints then
// fastest time.
//
// Routes (all return JSON; pass ?r=<route>):
//   GET  ?r=health
//   POST ?r=result        body: {gameId, email, name, seconds, hints,
//                                 mistakes, difficulty}
//   GET  ?r=leaderboard&game=<id>&limit=<n>        global top times for a game
//   GET  ?r=friends&game=<id>&emails=a@x,b@y        results for specific friends
//   GET  ?r=player&email=<email>&limit=<n>          one player's history
// =============================================================================

declare(strict_types=1);
require __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Api-Key');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ---- helpers ---------------------------------------------------------------

function json_out($data, int $code = 200): void
{
    http_response_code($code);
    echo json_encode($data);
    exit;
}

function fail(string $msg, int $code = 400): void
{
    json_out(['ok' => false, 'error' => $msg], $code);
}

function body_json(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) {
        return [];
    }
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function valid_email(string $e): bool
{
    return $e !== '' && strlen($e) <= 255 && filter_var($e, FILTER_VALIDATE_EMAIL) !== false;
}

function db(): PDO
{
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }
    $pdo = make_pdo();
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    init_schema($pdo);
    return $pdo;
}

function init_schema(PDO $pdo): void
{
    if (DB_DRIVER === 'sqlite') {
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS results (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                game_id INTEGER NOT NULL,
                email TEXT NOT NULL,
                name TEXT NOT NULL DEFAULT "",
                seconds INTEGER NOT NULL,
                hints INTEGER NOT NULL DEFAULT 0,
                mistakes INTEGER NOT NULL DEFAULT 0,
                difficulty INTEGER NOT NULL DEFAULT 0,
                tries INTEGER NOT NULL DEFAULT 1,
                finished_at TEXT NOT NULL,
                UNIQUE(game_id, email)
            )'
        );
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS shares (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                from_email TEXT NOT NULL,
                from_name TEXT NOT NULL DEFAULT "",
                to_email TEXT NOT NULL,
                game_id INTEGER NOT NULL,
                message TEXT NOT NULL DEFAULT "",
                seen INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL
            )'
        );
        $pdo->exec('CREATE INDEX IF NOT EXISTS idx_shares_to ON shares(to_email)');
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS notifications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                to_email TEXT NOT NULL,
                from_email TEXT NOT NULL,
                from_name TEXT NOT NULL DEFAULT "",
                game_id INTEGER NOT NULL,
                seconds INTEGER NOT NULL,
                hints INTEGER NOT NULL DEFAULT 0,
                seen INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL
            )'
        );
        $pdo->exec('CREATE INDEX IF NOT EXISTS idx_notif_to ON notifications(to_email)');
    } else {
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS results (
                id INT AUTO_INCREMENT PRIMARY KEY,
                game_id INT NOT NULL,
                email VARCHAR(255) NOT NULL,
                name VARCHAR(64) NOT NULL DEFAULT "",
                seconds INT NOT NULL,
                hints INT NOT NULL DEFAULT 0,
                mistakes INT NOT NULL DEFAULT 0,
                difficulty INT NOT NULL DEFAULT 0,
                tries INT NOT NULL DEFAULT 1,
                finished_at DATETIME NOT NULL,
                UNIQUE KEY uniq_game_email (game_id, email),
                INDEX idx_game (game_id),
                INDEX idx_email (email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
        );
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS shares (
                id INT AUTO_INCREMENT PRIMARY KEY,
                from_email VARCHAR(255) NOT NULL,
                from_name VARCHAR(64) NOT NULL DEFAULT "",
                to_email VARCHAR(255) NOT NULL,
                game_id INT NOT NULL,
                message VARCHAR(280) NOT NULL DEFAULT "",
                seen TINYINT NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL,
                INDEX idx_shares_to (to_email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
        );
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                to_email VARCHAR(255) NOT NULL,
                from_email VARCHAR(255) NOT NULL,
                from_name VARCHAR(64) NOT NULL DEFAULT "",
                game_id INT NOT NULL,
                seconds INT NOT NULL,
                hints INT NOT NULL DEFAULT 0,
                seen TINYINT NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL,
                INDEX idx_notif_to (to_email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
        );
    }
}

/// A result A is "better" than B when it used fewer hints, or equal hints in
/// less time. This is the ranking the whole app uses.
function is_better(int $hintsA, int $secA, int $hintsB, int $secB): bool
{
    if ($hintsA !== $hintsB) {
        return $hintsA < $hintsB;
    }
    return $secA < $secB;
}

function require_write(): void
{
    if (API_KEY === '') {
        return; // open
    }
    $sent = $_SERVER['HTTP_X_API_KEY'] ?? '';
    if (!hash_equals(API_KEY, $sent)) {
        fail('invalid api key', 401);
    }
}

// ---- routes ----------------------------------------------------------------

function route_result(): void
{
    require_write();
    $in = body_json();

    $gameId = filter_var($in['gameId'] ?? null, FILTER_VALIDATE_INT);
    $email  = strtolower(trim((string)($in['email'] ?? '')));
    $name   = trim((string)($in['name'] ?? ''));
    if (function_exists('mb_substr')) {
        $name = mb_substr($name, 0, 64);
    } else {
        $name = substr($name, 0, 64);
    }
    $seconds    = filter_var($in['seconds'] ?? null, FILTER_VALIDATE_INT);
    $hints      = max(0, (int)($in['hints'] ?? 0));
    $mistakes   = max(0, (int)($in['mistakes'] ?? 0));
    $difficulty = max(0, min(3, (int)($in['difficulty'] ?? 0)));

    if ($gameId === false || $gameId === null) {
        fail('gameId must be an integer');
    }
    if (!valid_email($email)) {
        fail('valid email required');
    }
    if ($seconds === false || $seconds === null || $seconds < 1 || $seconds > 86400) {
        fail('seconds out of range');
    }

    $pdo = db();
    $pdo->beginTransaction();

    $sel = $pdo->prepare('SELECT id, seconds, hints, tries FROM results WHERE game_id = ? AND email = ?');
    $sel->execute([$gameId, $email]);
    $row = $sel->fetch();

    $now = gmdate('Y-m-d H:i:s');

    if ($row === false) {
        $ins = $pdo->prepare(
            'INSERT INTO results
                (game_id, email, name, seconds, hints, mistakes, difficulty, tries, finished_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)'
        );
        $ins->execute([$gameId, $email, $name, $seconds, $hints, $mistakes, $difficulty, $now]);
        $improved = true;
    } else {
        $improved = is_better($hints, $seconds, (int)$row['hints'], (int)$row['seconds']);
        if ($improved) {
            $upd = $pdo->prepare(
                'UPDATE results
                    SET name = ?, seconds = ?, hints = ?, mistakes = ?, difficulty = ?,
                        tries = tries + 1, finished_at = ?
                  WHERE id = ?'
            );
            $upd->execute([$name, $seconds, $hints, $mistakes, $difficulty, $now, $row['id']]);
        } else {
            // Keep the old best, but record the new name and the extra attempt.
            $upd = $pdo->prepare('UPDATE results SET name = ?, tries = tries + 1 WHERE id = ?');
            $upd->execute([$name, $row['id']]);
        }
    }

    // Compute rank (1-based) among this game's stored bests.
    $rankStmt = $pdo->prepare(
        'SELECT COUNT(*) AS c FROM results
          WHERE game_id = ?
            AND (hints < ? OR (hints = ? AND seconds < ?))'
    );
    $best = $pdo->prepare('SELECT seconds, hints FROM results WHERE game_id = ? AND email = ?');
    $best->execute([$gameId, $email]);
    $b = $best->fetch();
    $rankStmt->execute([$gameId, (int)$b['hints'], (int)$b['hints'], (int)$b['seconds']]);
    $rank = ((int)$rankStmt->fetch()['c']) + 1;

    $totalStmt = $pdo->query('SELECT COUNT(*) AS c FROM results WHERE game_id = ' . (int)$gameId);
    $total = (int)$totalStmt->fetch()['c'];

    $pdo->commit();

    json_out([
        'ok'       => true,
        'improved' => $improved,
        'rank'     => $rank,
        'total'    => $total,
    ]);
}

function route_leaderboard(): void
{
    $gameId = filter_var($_GET['game'] ?? null, FILTER_VALIDATE_INT);
    if ($gameId === false || $gameId === null) {
        fail('game must be an integer');
    }
    $limit = (int)($_GET['limit'] ?? 20);
    $limit = max(1, min(100, $limit));

    $pdo = db();
    // Public leaderboard: show display name, not email.
    $stmt = $pdo->prepare(
        'SELECT name, seconds, hints, mistakes, difficulty, finished_at
           FROM results
          WHERE game_id = ?
          ORDER BY hints ASC, seconds ASC
          LIMIT ' . $limit
    );
    $stmt->execute([$gameId]);
    json_out(['ok' => true, 'gameId' => $gameId, 'entries' => $stmt->fetchAll()]);
}

function route_friends(): void
{
    $gameId = filter_var($_GET['game'] ?? null, FILTER_VALIDATE_INT);
    if ($gameId === false || $gameId === null) {
        fail('game must be an integer');
    }
    $emailsRaw = (string)($_GET['emails'] ?? '');
    $emails = array_values(array_filter(array_map(
        static fn($e) => strtolower(trim($e)),
        explode(',', $emailsRaw)
    )));
    if (count($emails) === 0) {
        json_out(['ok' => true, 'gameId' => $gameId, 'entries' => []]);
    }
    $emails = array_slice($emails, 0, 50);

    $pdo = db();
    $place = implode(',', array_fill(0, count($emails), '?'));
    // Friends know each other's emails, so include them here.
    $stmt = $pdo->prepare(
        'SELECT email, name, seconds, hints, mistakes, difficulty, finished_at
           FROM results
          WHERE game_id = ? AND email IN (' . $place . ')
          ORDER BY hints ASC, seconds ASC'
    );
    $stmt->execute(array_merge([$gameId], $emails));
    json_out(['ok' => true, 'gameId' => $gameId, 'entries' => $stmt->fetchAll()]);
}

function route_player(): void
{
    $email = strtolower(trim((string)($_GET['email'] ?? '')));
    if (!valid_email($email)) {
        fail('valid email required');
    }
    $limit = (int)($_GET['limit'] ?? 100);
    $limit = max(1, min(500, $limit));

    $pdo = db();
    $stmt = $pdo->prepare(
        'SELECT game_id, seconds, hints, mistakes, difficulty, finished_at
           FROM results
          WHERE email = ?
          ORDER BY finished_at DESC
          LIMIT ' . $limit
    );
    $stmt->execute([$email]);
    json_out(['ok' => true, 'email' => $email, 'results' => $stmt->fetchAll()]);
}

function route_share(): void
{
    require_write();
    $in = body_json();

    $fromEmail = strtolower(trim((string)($in['fromEmail'] ?? '')));
    $toEmail   = strtolower(trim((string)($in['toEmail'] ?? '')));
    $fromName  = trim((string)($in['fromName'] ?? ''));
    $message   = trim((string)($in['message'] ?? ''));
    $gameId    = filter_var($in['gameId'] ?? null, FILTER_VALIDATE_INT);

    $clip = function (string $s, int $n): string {
        return function_exists('mb_substr') ? mb_substr($s, 0, $n) : substr($s, 0, $n);
    };
    $fromName = $clip($fromName, 64);
    $message  = $clip($message, 280);

    if (!valid_email($fromEmail) || !valid_email($toEmail)) {
        fail('valid fromEmail and toEmail required');
    }
    if ($gameId === false || $gameId === null) {
        fail('gameId must be an integer');
    }

    $pdo = db();
    $stmt = $pdo->prepare(
        'INSERT INTO shares (from_email, from_name, to_email, game_id, message, seen, created_at)
         VALUES (?, ?, ?, ?, ?, 0, ?)'
    );
    $stmt->execute([$fromEmail, $fromName, $toEmail, $gameId, $message, gmdate('Y-m-d H:i:s')]);
    json_out(['ok' => true]);
}

function route_inbox(): void
{
    $email = strtolower(trim((string)($_GET['email'] ?? '')));
    if (!valid_email($email)) {
        fail('valid email required');
    }
    $limit = (int)($_GET['limit'] ?? 50);
    $limit = max(1, min(200, $limit));

    $pdo = db();
    $stmt = $pdo->prepare(
        'SELECT id, from_email, from_name, game_id, message, seen, created_at
           FROM shares
          WHERE to_email = ?
          ORDER BY created_at DESC
          LIMIT ' . $limit
    );
    $stmt->execute([$email]);
    json_out(['ok' => true, 'email' => $email, 'shares' => $stmt->fetchAll()]);
}

function route_seen(): void
{
    require_write();
    $in = body_json();
    $email = strtolower(trim((string)($in['email'] ?? '')));
    $id = filter_var($in['id'] ?? null, FILTER_VALIDATE_INT);
    if (!valid_email($email) || $id === false || $id === null) {
        fail('id and valid email required');
    }
    $pdo = db();
    // Scope by to_email so you can only mark your own shares.
    $stmt = $pdo->prepare('UPDATE shares SET seen = 1 WHERE id = ? AND to_email = ?');
    $stmt->execute([$id, $email]);
    json_out(['ok' => true]);
}

function route_finish(): void
{
    require_write();
    $in = body_json();

    $email   = strtolower(trim((string)($in['email'] ?? '')));
    $name    = trim((string)($in['name'] ?? ''));
    $name    = function_exists('mb_substr') ? mb_substr($name, 0, 64) : substr($name, 0, 64);
    $gameId  = filter_var($in['gameId'] ?? null, FILTER_VALIDATE_INT);
    $seconds = filter_var($in['seconds'] ?? null, FILTER_VALIDATE_INT);
    $hints   = max(0, (int)($in['hints'] ?? 0));

    if (!valid_email($email)) {
        fail('valid email required');
    }
    if ($gameId === false || $gameId === null) {
        fail('gameId must be an integer');
    }
    if ($seconds === false || $seconds === null || $seconds < 1 || $seconds > 86400) {
        fail('seconds out of range');
    }

    $pdo = db();

    // Counterparties: everyone you have a share relationship with on this game.
    $stmt = $pdo->prepare(
        'SELECT from_email AS e FROM shares WHERE game_id = ? AND to_email = ?
         UNION
         SELECT to_email AS e FROM shares WHERE game_id = ? AND from_email = ?'
    );
    $stmt->execute([$gameId, $email, $gameId, $email]);
    $others = [];
    foreach ($stmt->fetchAll() as $row) {
        $e = strtolower(trim((string)$row['e']));
        if ($e !== '' && $e !== $email) {
            $others[$e] = true;
        }
    }

    $now = gmdate('Y-m-d H:i:s');
    // One notification per (recipient, sender, game): replace any prior one.
    $del = $pdo->prepare('DELETE FROM notifications WHERE to_email = ? AND from_email = ? AND game_id = ?');
    $ins = $pdo->prepare(
        'INSERT INTO notifications (to_email, from_email, from_name, game_id, seconds, hints, seen, created_at)
         VALUES (?, ?, ?, ?, ?, ?, 0, ?)'
    );
    $count = 0;
    foreach (array_keys($others) as $cp) {
        $del->execute([$cp, $email, $gameId]);
        $ins->execute([$cp, $email, $name, $gameId, $seconds, $hints, $now]);
        $count++;
    }

    json_out(['ok' => true, 'notified' => $count]);
}

function route_notifications(): void
{
    $email = strtolower(trim((string)($_GET['email'] ?? '')));
    if (!valid_email($email)) {
        fail('valid email required');
    }
    $limit = (int)($_GET['limit'] ?? 50);
    $limit = max(1, min(200, $limit));

    $pdo = db();
    $stmt = $pdo->prepare(
        'SELECT id, from_email, from_name, game_id, seconds, hints, seen, created_at
           FROM notifications
          WHERE to_email = ?
          ORDER BY created_at DESC, id DESC
          LIMIT ' . $limit
    );
    $stmt->execute([$email]);
    json_out(['ok' => true, 'email' => $email, 'notifications' => $stmt->fetchAll()]);
}

function route_notif_seen(): void
{
    require_write();
    $in = body_json();
    $email = strtolower(trim((string)($in['email'] ?? '')));
    $id = filter_var($in['id'] ?? null, FILTER_VALIDATE_INT);
    if (!valid_email($email) || $id === false || $id === null) {
        fail('id and valid email required');
    }
    $pdo = db();
    $stmt = $pdo->prepare('UPDATE notifications SET seen = 1 WHERE id = ? AND to_email = ?');
    $stmt->execute([$id, $email]);
    json_out(['ok' => true]);
}

// ---- dispatch --------------------------------------------------------------

try {
    $r = $_GET['r'] ?? 'health';
    switch ($r) {
        case 'health':
            json_out(['ok' => true, 'service' => 'sudoku', 'driver' => DB_DRIVER, 'time' => gmdate('c')]);
            break;
        case 'result':
            route_result();
            break;
        case 'leaderboard':
            route_leaderboard();
            break;
        case 'friends':
            route_friends();
            break;
        case 'player':
            route_player();
            break;
        case 'share':
            route_share();
            break;
        case 'inbox':
            route_inbox();
            break;
        case 'seen':
            route_seen();
            break;
        case 'finish':
            route_finish();
            break;
        case 'notifications':
            route_notifications();
            break;
        case 'notif_seen':
            route_notif_seen();
            break;
        default:
            fail('unknown route: ' . $r, 404);
    }
} catch (Throwable $e) {
    // Don't leak internals in production; flip to $e->getMessage() while testing.
    fail('server error', 500);
}
