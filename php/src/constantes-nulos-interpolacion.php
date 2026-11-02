<?php
declare(strict_types=1);

// ============================================================
// Demo S1 — const/define, null y interpolación en PHP.
// ============================================================

const VERSION = '1.0';
define('APP_NAME', 'Demo');

$nulo = null;
$nombre = 'Diego';
$usuario = null;
$coalescido = $usuario ?? 'anonimo';

$simpleInterp = 'Hola $nombre';     // comillas simples: no interpola
$dobleInterp = "Hola $nombre";      // comillas dobles: interpola
?>
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>constantes-nulos-interpolacion</title></head>
<body>
<p><?= APP_NAME ?> <?= VERSION ?></p>
<p><?= $coalescido ?></p>
<p><?= $simpleInterp ?> / <?= $dobleInterp ?></p>
</body>
</html>
