<?php
declare(strict_types=1);
require __DIR__ . '/../src/semana2-tipos.php';
require __DIR__ . '/../src/semana2-cliente.php';

$estricto = 'No se produjo TypeError';
try {
    calcularTotal("3", 12.5);
} catch (TypeError) {
    $estricto = 'TypeError: el modo estricto rechaza una cantidad string.';
}
$repo = new ClienteRepositorioMemoria();
$repo->registrar(new Cliente(1, 'Ana Pérez', 'ana@correo.com'));
$repo->registrar(new Cliente(2, 'Luis Torres', 'luis@correo.com', telefono: '0987654321'));
$repo->actualizarCorreo(1, 'ana.perez@correo.com');
$ana = $repo->consultar(1);
$eliminado = $repo->eliminar(2);
$ejemplos = [
    'Tipos simples y null' => [$cantidad, $precio, $producto, $enStock, $descuento],
    'Verificaciones de tipos' => [$esInt, $esFloat, $esString, $esBool, $esNull],
    'Subtotal (float)' => $subtotal,
    'Conversión automática' => [$convAuto1, $convAuto2, $convAuto3],
    'Conversión explícita' => [$castInt, $castFloat, $castBool, $castString],
    'Valores falsy' => [$boolZero, $boolEmpty, $boolArray, $boolNull],
    'Comparaciones == y ===' => [$cmp1, $cmp2, $cmp3],
    'Total sin descuento / con 10%' => [$totalSinDesc, $totalConDesc],
    'Modo estricto' => $estricto,
    'Tipos unión' => [$buscarPorId, $buscarPorCedula],
    'Variables de variables / llaves / arreglo' => [$valorCiudad, $valorCiudadLlaves, $ciudadArray],
    'Notas dinámicas (suma)' => $sumaNotas,
    'Propiedad dinámica en stdClass' => $telefonoObj,
    'Cliente consultado tras actualizar' => $ana,
    'Listado tras eliminar a Luis' => $repo->listar(),
];
?>
<!doctype html>
<html lang="es">
<head><meta charset="UTF-8"><title>Semana 2 — Tipos y Cliente</title></head>
<body>
<nav><a href="index.php">Inicio</a> · <a href="semana2.php">Clase 2</a></nav>
<h1>Clase 1 — Tipos simples, variables de variables y Cliente</h1>
<p>PHP tiene cuatro tipos escalares: int, float, string y bool. null representa ausencia de valor.
Los float tienen precisión limitada; para dinero se puede trabajar con centavos enteros.</p>
<p>Los casts convierten, no validan: (int) "125abc" produce 125 y (float) "8,5" produce 8.
Prefiera === para comparar también el tipo.</p>
<p>strict_types controla los argumentos escalares desde el archivo que hace la llamada;
un int sí puede aceptarse donde se espera float.</p>
<p>Las variables de variables se muestran solo con nombres controlados.
No use nombres recibidos del usuario: prefiera arreglos asociativos.</p>
<?php foreach ($ejemplos as $titulo => $valor): ?>
<h2><?= htmlspecialchars($titulo, ENT_QUOTES, 'UTF-8') ?></h2>
<pre><?= htmlspecialchars(var_export($valor, true), ENT_QUOTES, 'UTF-8') ?></pre>
<?php endforeach ?>
<p>Eliminado: <?= $eliminado ? 'sí' : 'no' ?>. El repositorio es en memoria y se reinicia en cada petición.</p>
</body>
</html>
