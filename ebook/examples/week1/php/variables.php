<?php
declare(strict_types=1);

/** Demostración de Semana 1: ejecutar con `php variables.php`. */
const CURSO = 'PHP-CSharp';
define('ETIQUETA', 'Semana 1');

function assertSameValue(mixed $expected, mixed $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException("Fallo en {$label}");
    }
}

function contadorDeEstaPeticion(): int
{
    static $contador = 0;
    $contador++;
    return $contador;
}

$exterior = 10;
{
    // PHP no crea un ámbito nuevo para este bloque.
    $localDeBloque = 7;
}

$nombre = 'Ada';
$saludo = "Hola {$nombre}";
$suma = '3' + 3;
$primeraCuenta = contadorDeEstaPeticion();
$segundaCuenta = contadorDeEstaPeticion();

assertSameValue('PHP-CSharp', CURSO, 'constante');
assertSameValue('Semana 1', ETIQUETA, 'define');
assertSameValue(7, $localDeBloque, 'ámbito de bloque PHP');
assertSameValue(6, $suma, 'suma numérica PHP');
assertSameValue(1, $primeraCuenta, 'primer contador');
assertSameValue(2, $segundaCuenta, 'segundo contador');

printf("CONST|curso=%s|etiqueta=%s\n", CURSO, ETIQUETA);
printf("SCOPE|bloque=%d|exterior=%d|static=%d,%d\n", $localDeBloque, $exterior, $primeraCuenta, $segundaCuenta);
printf("STRING|interpolacion=%s|suma=%d\n", $saludo, $suma);
