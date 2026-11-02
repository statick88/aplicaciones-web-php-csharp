<?php
declare(strict_types=1);

// Structural check for the official Week 1 PHP project layout:
// public/ (Apache docroot) + src/ (logic) + views/ (templates) + config/
// (settings), connected with require/include. Fails while the layout is absent.

error_reporting(E_ALL);

$root = dirname(__DIR__);

$files = [
    'public/index.php' => $root . '/public/index.php',
    'public/variables.php' => $root . '/public/variables.php',
    'public/home.php' => $root . '/public/home.php',
    'src/variables.php' => $root . '/src/variables.php',
    'views/variables.php' => $root . '/views/variables.php',
    'config/config.php' => $root . '/config/config.php',
];

$checks = [];
foreach ($files as $label => $path) {
    $checks["existe $label"] = is_file($path);
}

$entry = $root . '/public/variables.php';
$checks['public/variables.php usa require (>=3)'] = is_file($entry)
    && substr_count((string) file_get_contents($entry), 'require') >= 3;

$config = $root . '/config/config.php';
$checks['config/config.php declara const y define'] = is_file($config)
    && str_contains((string) file_get_contents($config), 'const ')
    && str_contains((string) file_get_contents($config), 'define(');

$compose = $root . '/compose.yaml';
$checks['compose monta la raíz del proyecto en /var/www/html'] = is_file($compose)
    && str_contains((string) file_get_contents($compose), '.:/var/www/html');

$dockerfile = $root . '/Dockerfile';
$checks['Dockerfile publica solo public/ como DocumentRoot'] = is_file($dockerfile)
    && str_contains((string) file_get_contents($dockerfile), 'DocumentRoot /var/www/html/public');

$failed = 0;
foreach ($checks as $label => $passed) {
    if (!$passed) {
        fwrite(STDERR, "FAIL: $label" . PHP_EOL);
        $failed++;
    }
}
if ($failed > 0) {
    fwrite(STDERR, $failed . " structural check(s) failed" . PHP_EOL);
    exit(1);
}
echo 'PASS: ' . count($checks) . " layout checks (public/src/views/config + require)\n";
