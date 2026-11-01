<?php
declare(strict_types=1);

header_remove('X-Powered-By');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

function respond(int $status, array $body, array $extraHeaders = []): never
{
    http_response_code($status);
    foreach ($extraHeaders as $name => $value) {
        header($name . ': ' . $value);
    }
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

$remoteAddress = $_SERVER['REMOTE_ADDR'] ?? '';
$host = $_SERVER['HTTP_HOST'] ?? '';
$hostName = explode(':', $host, 2)[0];
if ($remoteAddress !== '127.0.0.1' || $hostName !== '127.0.0.1') {
    respond(403, ['ok' => false, 'error' => 'Este laboratorio solo acepta el host 127.0.0.1.']);
}

$method = $_SERVER['REQUEST_METHOD'] ?? '';
$allowed = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
if (!in_array($method, $allowed, true)) {
    respond(405, ['ok' => false, 'error' => 'Método no permitido.'],
        ['Allow' => implode(', ', $allowed)]);
}

$source = '$_GET';
$received = $_GET;
if ($method === 'POST') {
    $source = '$_POST';
    $received = $_POST;
} elseif ($method === 'PUT' || $method === 'PATCH') {
    $contentType = strtolower(trim(explode(';', $_SERVER['CONTENT_TYPE'] ?? '', 2)[0]));
    if ($contentType !== 'application/json') {
        respond(415, ['ok' => false, 'error' => 'Usa Content-Type: application/json.']);
    }
    $source = 'php://input + json_decode';
    $received = json_decode(file_get_contents('php://input'), true);
    if (!is_array($received) || json_last_error() !== JSON_ERROR_NONE) {
        respond(400, ['ok' => false, 'error' => 'El cuerpo no contiene JSON válido.']);
    }
}

$response = [
    'ok' => true,
    'method' => $method,
    'source' => $source,
    'received' => $received,
    'saved' => false,
];
if ($method === 'DELETE') {
    $response['simulation'] = 'No se eliminó ningún dato.';
}
respond(200, $response);
