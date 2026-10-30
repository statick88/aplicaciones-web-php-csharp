<?php
declare(strict_types=1);

error_reporting(E_ALL);
set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

ob_start();
require __DIR__ . '/../src/variables.php';
$html = ob_get_clean();

$checks = [
    $sumaImplicita === 6,
    $edadTexto === '25',
    sinGlobal() === 'no ve la variable global',
    conGlobal() === 'Aplicaciones Web',
    $valorTrasElBucle === 30,
    $recorrido === 60,
    str_contains($html, '$sumaImplicita = "3" + 3;'),
    !str_contains($html, '"3a"'),
];
foreach ($checks as $index => $passed) {
    if (!$passed) {
        fwrite(STDERR, 'FAIL: variables check ' . ($index + 1) . PHP_EOL);
        exit(1);
    }
}
echo "PASS: variables, conversions and scope without warnings\n";
