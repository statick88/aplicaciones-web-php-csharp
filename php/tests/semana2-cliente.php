<?php
declare(strict_types=1);

error_reporting(E_ALL);
set_error_handler(static function (int $severity, string $message, string $file, int $line): never {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

require __DIR__ . '/../src/semana2-cliente.php';

$repo = new ClienteRepositorioMemoria();

// Registrar
$repo->registrar(new Cliente(1, "Ana Pérez", "ana@correo.com"));
$repo->registrar(new Cliente(2, "Luis Torres", "luis@correo.com", true, "0987654321"));

$checks = [];

// Consultar
$c1 = $repo->consultar(1);
$checks[] = $c1 instanceof Cliente;
$checks[] = $c1->id === 1;
$checks[] = $c1->nombre === "Ana Pérez";
$checks[] = $c1->correo === "ana@correo.com";
$checks[] = $c1->activo === true;
$checks[] = $c1->telefono === null;

$c2 = $repo->consultar(2);
$checks[] = $c2 instanceof Cliente;
$checks[] = $c2->telefono === "0987654321";

// Consultar inexistente
$checks[] = $repo->consultar(999) === null;

// Listar
$list = $repo->listar();
$checks[] = is_array($list);
$checks[] = count($list) === 2;

// Actualizar correo
$checks[] = $repo->actualizarCorreo(1, "ana.perez@correo.com") === true;
$c1b = $repo->consultar(1);
$checks[] = $c1b->correo === "ana.perez@correo.com";

// Actualizar correo de inexistente
$checks[] = $repo->actualizarCorreo(999, "x@y.com") === false;

// Eliminar
$checks[] = $repo->eliminar(1) === true;
$checks[] = $repo->consultar(1) === null;
$checks[] = count($repo->listar()) === 1;

// Eliminar inexistente
$checks[] = $repo->eliminar(999) === false;

foreach ($checks as $index => $passed) {
    if (!$passed) {
        fwrite(STDERR, 'FAIL: semana2-cliente check ' . ($index + 1) . PHP_EOL);
        exit(1);
    }
}
echo "PASS: semana2-cliente (registrar, consultar, listar, actualizarCorreo, eliminar)\n";
