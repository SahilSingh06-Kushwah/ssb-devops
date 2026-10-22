<?php
declare(strict_types=1);

/**
 * Shared helpers: env loader, PDO connection, escaping, CSRF, flash messages.
 * Database settings are NOT stored in this file. They come from an .env file
 * that lives outside the web root and is never committed to Git.
 */

session_start();

/** Look for the env file in this order: $SSB_ENV_FILE, /etc/ssb-app/.env, <repo>/.env */
function load_env(): array
{
    $candidates = [
        getenv('SSB_ENV_FILE') ?: '',
        '/etc/ssb-app/.env',
        dirname(__DIR__) . '/.env',
    ];

    foreach ($candidates as $path) {
        if ($path === '' || !is_readable($path)) {
            continue;
        }
        $env = [];
        foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || $line[0] === '#' || strpos($line, '=') === false) {
                continue;
            }
            [$key, $value] = explode('=', $line, 2);
            $env[trim($key)] = trim(trim($value), "\"'");
        }
        return $env;
    }

    throw new RuntimeException('Env file not found. Expected /etc/ssb-app/.env (see .env.example).');
}

/** Returns one shared PDO connection. Logs the real error, shows a generic one. */
function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    try {
        $env = load_env();
        foreach (['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASS'] as $required) {
            if (!isset($env[$required])) {
                throw new RuntimeException("Missing config value: $required");
            }
        }
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
            $env['DB_HOST'],
            $env['DB_PORT'] ?? '3306',
            $env['DB_NAME']
        );
        $pdo = new PDO($dsn, $env['DB_USER'], $env['DB_PASS'], [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
        return $pdo;
    } catch (Throwable $e) {
        // Goes to the Apache error log (/var/log/apache2/error.log) for troubleshooting.
        error_log('[ssb-app] DB connection failed: ' . $e->getMessage());
        http_response_code(500);
        exit('<h1>Service unavailable</h1><p>Database connection failed. Check the server logs.</p>');
    }
}

/** Escape output for HTML. */
function e(?string $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

/** CSRF token helpers. */
function csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function csrf_check(): void
{
    $sent = $_POST['csrf'] ?? '';
    if (!is_string($sent) || !hash_equals($_SESSION['csrf'] ?? '', $sent)) {
        http_response_code(400);
        exit('Invalid form token. Go back and try again.');
    }
}

/** One-time messages shown after a redirect. */
function flash(?string $message = null, string $type = 'ok'): ?array
{
    if ($message !== null) {
        $_SESSION['flash'] = ['msg' => $message, 'type' => $type];
        return null;
    }
    $f = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    return $f;
}

/** Shared page header/footer so every page looks the same. */
function page_header(string $title): void
{
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">'
       . '<meta name="viewport" content="width=device-width, initial-scale=1">'
       . '<title>' . e($title) . '</title><style>'
       . 'body{font-family:system-ui,Arial,sans-serif;max-width:760px;margin:2rem auto;padding:0 1rem;color:#222}'
       . 'h1{font-size:1.5rem}form{background:#f5f7fa;padding:1rem;border-radius:8px;margin-bottom:1.5rem}'
       . 'label{display:block;margin:.5rem 0 .2rem;font-weight:600}'
       . 'input[type=text]{width:100%;padding:.5rem;border:1px solid #bbb;border-radius:4px;box-sizing:border-box}'
       . 'button,.btn{margin-top:1rem;padding:.5rem 1rem;background:#0b5ed7;color:#fff;border:0;border-radius:4px;'
       . 'text-decoration:none;cursor:pointer;font-size:1rem}'
       . 'table{width:100%;border-collapse:collapse}th,td{padding:.5rem;border-bottom:1px solid #ddd;text-align:left}'
       . '.ok{background:#d1e7dd;padding:.6rem;border-radius:4px;margin-bottom:1rem}'
       . '.err{background:#f8d7da;padding:.6rem;border-radius:4px;margin-bottom:1rem}'
       . '</style></head><body>';
}

function page_footer(): void
{
    echo '</body></html>';
}
