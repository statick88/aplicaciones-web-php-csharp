<?php
declare(strict_types=1);

$rawPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$decodedPath = rawurldecode(is_string($rawPath) ? $rawPath : '/');
$allowedPaths = ['/', '/index.html', '/app.js', '/styles.css', '/api.php', '/README.md'];

if (str_contains($decodedPath, '..') || !in_array($decodedPath, $allowedPaths, true)) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: no-store');
    echo "Recurso no disponible.\n";
    exit;
}

if ($decodedPath === '/api.php') {
    require __DIR__ . '/api.php';
    exit;
}

return false;
