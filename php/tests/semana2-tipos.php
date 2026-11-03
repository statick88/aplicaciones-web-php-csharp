<?php
declare(strict_types=1);

error_reporting(E_ALL);
set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

require __DIR__ . '/../src/semana2-tipos.php';

$checks = [
    // Tipos simples
    is_int($cantidad) && $cantidad === 3,
    is_float($precio) && abs($precio - 12.5) < 0.00001,
    is_string($producto) && $producto === 'Teclado USB',
    is_bool($enStock) && $enStock === true,
    is_null($descuento),
    abs($subtotal - 37.5) < 0.00001,

    // Verificación con funciones
    $esInt === true,
    $esFloat === true,
    $esString === true,
    $esBool === true,
    $esNull === true,

    // Conversión automática
    $convAuto1 === 15 && is_int($convAuto1),
    abs($convAuto2 - 7.0) < 0.00001 && is_float($convAuto2),
    $convAuto3 === '10' && is_string($convAuto3),

    // Conversión explícita
    $castInt === 125 && is_int($castInt),
    $castFloat === 8.0, // cast de "8,5" da float(8) en PHP
    $castBool === false && is_bool($castBool),
    $castString === '3' && is_string($castString),

    // Valores falsy
    $boolZero === false,
    $boolEmpty === false,
    $boolArray === false,
    $boolNull === false,

    // Comparación
    $cmp1 === false,
    $cmp2 === true,
    $cmp3 === false,

    // Modo estricto y declaraciones de tipo
    abs($totalSinDesc - 37.5) < 0.00001,
    abs($totalConDesc - 33.75) < 0.00001,
    $buscarPorId === 'Buscar por id 123',
    $buscarPorCedula === 'Buscar por cédula 0101234567',

    // Variables de variables
    $valorCiudad === 'Ambato',
    $valorCiudadLlaves === 'Ambato',
    $sumaNotas === 18,
    $telefonoObj === '0991234567',
    $ciudadArray === 'Ambato',
];

try {
    calcularTotal("3", 12.5);
    $checks[] = false;
} catch (TypeError) {
    $checks[] = true;
}

foreach ($checks as $index => $passed) {
    if (!$passed) {
        fwrite(STDERR, 'FAIL: semana2-tipos check ' . ($index + 1) . PHP_EOL);
        exit(1);
    }
}
echo "PASS: semana2-tipos (tipos, conversiones, modo estricto, variables de variables)\n";
