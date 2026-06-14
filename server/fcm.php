<?php
// =============================================================================
// Firebase Cloud Messaging (HTTP v1) sender.
//
// Sends a push to a player's registered device tokens. Auth is OAuth2 via the
// service-account key (a signed JWT exchanged for a short-lived access token,
// cached on disk). Everything here is best-effort: if FCM isn't configured, or
// a network call fails, it quietly does nothing and the app's polling still
// covers delivery. See config.php (FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT).
// =============================================================================

declare(strict_types=1);

// Read config constants defensively: an older config.php (pre-FCM) won't define
// them, and uploading the new index.php must never fatal-error a live server.
function fcm_project_id(): string
{
    return defined('FCM_PROJECT_ID') ? (string)FCM_PROJECT_ID : '';
}

function fcm_service_account_path(): string
{
    return defined('FCM_SERVICE_ACCOUNT') ? (string)FCM_SERVICE_ACCOUNT : '';
}

function fcm_enabled(): bool
{
    $path = fcm_service_account_path();
    return fcm_project_id() !== '' && $path !== '' && is_readable($path);
}

function fcm_b64url(string $s): string
{
    return rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
}

/** POST and return ['code'=>int,'body'=>string], or null on transport failure. */
function fcm_http_post(string $url, string $body, array $headers): ?array
{
    if (!function_exists('curl_init')) {
        return null;
    }
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $body,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 10,
    ]);
    $out = curl_exec($ch);
    if ($out === false) {
        curl_close($ch);
        return null;
    }
    $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'body' => (string)$out];
}

/** A cached OAuth2 access token for the messaging scope, or null. */
function fcm_access_token(): ?string
{
    if (!fcm_enabled()) {
        return null;
    }
    $cacheFile = dirname(fcm_service_account_path()) . '/fcm-access-token.json';
    if (is_readable($cacheFile)) {
        $c = json_decode((string)file_get_contents($cacheFile), true);
        if (is_array($c) && !empty($c['access_token']) && ($c['exp'] ?? 0) - 60 > time()) {
            return (string)$c['access_token'];
        }
    }

    $sa = json_decode((string)@file_get_contents(fcm_service_account_path()), true);
    if (!is_array($sa) || empty($sa['client_email']) || empty($sa['private_key'])) {
        return null;
    }

    $now    = time();
    $header = ['alg' => 'RS256', 'typ' => 'JWT'];
    $claims = [
        'iss'   => $sa['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud'   => 'https://oauth2.googleapis.com/token',
        'iat'   => $now,
        'exp'   => $now + 3600,
    ];
    $signingInput = fcm_b64url((string)json_encode($header)) . '.' .
                    fcm_b64url((string)json_encode($claims));
    $sig = '';
    if (!openssl_sign($signingInput, $sig, $sa['private_key'], 'sha256')) {
        return null;
    }
    $assertion = $signingInput . '.' . fcm_b64url($sig);

    $resp = fcm_http_post(
        'https://oauth2.googleapis.com/token',
        http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $assertion,
        ]),
        ['Content-Type: application/x-www-form-urlencoded']
    );
    if ($resp === null || $resp['code'] < 200 || $resp['code'] >= 300) {
        return null;
    }
    $tok = json_decode($resp['body'], true);
    if (!is_array($tok) || empty($tok['access_token'])) {
        return null;
    }
    @file_put_contents($cacheFile, json_encode([
        'access_token' => $tok['access_token'],
        'exp'          => $now + (int)($tok['expires_in'] ?? 3600),
    ]));
    return (string)$tok['access_token'];
}

/** Send one message. Returns the HTTP status (0 on transport failure). */
function fcm_send_one(string $accessToken, string $deviceToken, string $title, string $body, array $data): int
{
    $payload = [
        'message' => [
            'token'        => $deviceToken,
            'notification' => ['title' => $title, 'body' => $body],
            'data'         => array_map('strval', $data),
            'android'      => [
                'priority'     => 'HIGH',
                'notification' => ['channel_id' => 'sudoku_challenges'],
            ],
        ],
    ];
    $resp = fcm_http_post(
        'https://fcm.googleapis.com/v1/projects/' . fcm_project_id() . '/messages:send',
        (string)json_encode($payload),
        ['Content-Type: application/json', 'Authorization: Bearer ' . $accessToken]
    );
    return $resp === null ? 0 : $resp['code'];
}

/**
 * Push to every device registered for [email]. Best-effort: prunes tokens the
 * server reports as dead (404 UNREGISTERED / 400 invalid). Never throws.
 */
function fcm_push_to_email(PDO $pdo, string $email, string $title, string $body, array $data): void
{
    try {
        if (!fcm_enabled()) {
            return;
        }
        $accessToken = fcm_access_token();
        if ($accessToken === null) {
            return;
        }
        $stmt = $pdo->prepare('SELECT token FROM tokens WHERE email = ?');
        $stmt->execute([$email]);
        $tokens = $stmt->fetchAll(PDO::FETCH_COLUMN);
        foreach ($tokens as $t) {
            $code = fcm_send_one($accessToken, (string)$t, $title, $body, $data);
            if ($code === 404 || $code === 400) {
                $del = $pdo->prepare('DELETE FROM tokens WHERE token = ?');
                $del->execute([(string)$t]);
            }
        }
    } catch (Throwable $e) {
        // best-effort: never let a push failure break the API request
    }
}
