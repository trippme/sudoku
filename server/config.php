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

// Optional shared key. If non-empty, submitting a result requires the client
// to send this value in an "X-Api-Key" header. Leave empty for fully open
// (no auth), which is fine for a friends leaderboard.
const API_KEY = '';

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
