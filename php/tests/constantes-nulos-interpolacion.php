<?php
declare(strict_types=1);

error_reporting(E_ALL);
set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

ob_start();
require __DIR__ . '/../src/constantes-nulos-interpolacion.php';
$html = ob_get_clean();

$checks = [
    defined('APP_NAME') && APP_NAME === 'Demo',
    VERSION === '1.0',
    $nulo === null,
    !isset($nulo),
    ($usuario ?? 'anonimo') === 'anonimo',
    $coalescido === 'anonimo',
    $simpleInterp === 'Hola $nombre',
    $dobleInterp === 'Hola Diego',
    str_contains($html, 'constantes-nulos-interpolacion'),
];
foreach ($checks as $index => $passed) {
    if (!$passed) {
        fwrite(STDERR, 'FAIL: const/null/interp check ' . ($index + 1) . PHP_EOL);
        exit(1);
    }
}
echo "PASS: const, define, null and interpolation without warnings\n";
