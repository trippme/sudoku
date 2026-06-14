<?php
// Sudoku backend configuration.
//
// Default is SQLite — zero database setup, just a writable file. If your host
// gives you MySQL and you'd rather use it, set DB_DRIVER to 'mysql' and fill in
// the MYSQL_* values below.
declare(strict_types=1);

// 'sqlite' (no setup) or 'mysql'
const DB_DRIVER = 'sqlite';

// --- SQLite (used when DB_DRIVER === 'sqlite') -----------------------------
// The DB file lives next to this script and is blocked from web access by
// .htaccess. Make sure the directory is writable by the web server.
const SQLITE_PATH = __DIR__ . '/data/sudoku.sqlite';

// --- MySQL (used when DB_DRIVER === 'mysql') -------------------------------
const MYSQL_DSN  = 'mysql:host=localhost;dbname=YOUR_DB;charset=utf8mb4';
const MYSQL_USER = 'YOUR_USER';
const MYSQL_PASS = 'YOUR_PASSWORD';

// Shared API key. When non-empty, EVERY request (except health) must send it in
// an "X-Api-Key" header — a deterrent that keeps drive-by scripts and browsers
// out (note: it ships inside the app, so it's not strong auth against someone
// who decompiles the APK). The value lives in data/api-key.txt — git-ignored and
// web-blocked, so it's never committed — and the build scripts inject the same
// value into the app via --dart-define=BACKEND_API_KEY. Empty file / missing
// file => fully open (no key required).
$__apiKeyFile = __DIR__ . '/data/api-key.txt';
define('API_KEY', is_readable($__apiKeyFile) ? trim((string)file_get_contents($__apiKeyFile)) : '');

// --- Firebase Cloud Messaging (optional push notifications) ----------------
// Enables instant push when a friend sends you a game or finishes one you're
// racing. Leave FCM_PROJECT_ID empty (or omit the service-account file) and the
// server simply doesn't push — clients fall back to polling. To enable:
//   1. Firebase console > Project settings > General > your "Project ID"
//      -> put it in FCM_PROJECT_ID below.
//   2. Project settings > Service accounts > "Generate new private key" -> save
//      the downloaded JSON next to this file as data/fcm-service-account.json
//      (the data/ dir is blocked from the web by .htaccess, like the SQLite DB).
const FCM_PROJECT_ID      = 'sudoku-a0bba';
const FCM_SERVICE_ACCOUNT = __DIR__ . '/data/fcm-service-account.json';

function make_pdo(): PDO
{
    if (DB_DRIVER === 'sqlite') {
        $dir = dirname(SQLITE_PATH);
        if (!is_dir($dir)) {
            @mkdir($dir, 0775, true);
        }
        return new PDO('sqlite:' . SQLITE_PATH);
    }
    return new PDO(MYSQL_DSN, MYSQL_USER, MYSQL_PASS);
}
