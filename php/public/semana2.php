<?php
declare(strict_types=1);
require_once __DIR__ . '/../src/semana2-formulario.php';

$metodo = $_SERVER['REQUEST_METHOD'];
$soloPost = basename($_SERVER['SCRIPT_NAME']) === 'semana2-registro.php';
if (!in_array($metodo, $soloPost ? ['POST'] : ['GET', 'POST'], true)) {
    header('Allow: ' . ($soloPost ? 'POST' : 'GET, POST'));
    http_response_code(405);
    exit('Acceso no válido');
}
session_start(['cookie_httponly' => true, 'cookie_samesite' => 'Lax']);
$_SESSION['csrf'] ??= bin2hex(random_bytes(32));
$_SESSION['clientes'] ??= [];
$valores = ['nombre' => '', 'correo' => '', 'edad' => '', 'carrera' => 'SOF', 'intereses' => []];
$errores = [];
$consulta = $_GET['q'] ?? '';
if (!is_string($consulta)) {
    http_response_code(422);
    $errores['q'] = 'La búsqueda debe ser texto.';
    $consulta = '';
}
if ($metodo === 'POST') {
    $token = $_POST['csrf'] ?? null;
    if (!is_string($token) || !hash_equals($_SESSION['csrf'], $token)) {
        http_response_code(403);
        exit('Formulario no válido. Vuelva a abrir la página.');
    }
    [$valores, $errores, $edad] = validarRegistro($_POST);
    if ($errores) {
        http_response_code(422);
    } else {
        // Store only validated new records. No database or existing invoice data is used.
        $id = count($_SESSION['clientes']) + 1;
        $cliente = new Cliente($id, $valores['nombre'], $valores['correo']);
        $_SESSION['clientes'][] = [
            'id' => $cliente->id, 'nombre' => $cliente->nombre, 'correo' => $cliente->correo,
            'edad' => $edad, 'carrera' => $valores['carrera'], 'intereses' => $valores['intereses'],
        ];
        $_SESSION['mensaje'] = 'Registro correcto';
        header('Location: semana2.php', true, 303);
        exit;
    }
}
$mensaje = $_SESSION['mensaje'] ?? '';
unset($_SESSION['mensaje']);
header('Content-Type: text/html; charset=UTF-8');
?>
<!doctype html>
<html lang="es">
<head><meta charset="UTF-8"><title>Semana 2 — Formularios GET y POST</title></head>
<body>
<nav><a href="index.php">Inicio</a> · <a href="semana2-tipos.php">Clase 1</a></nav>
<h1>Clase 2 — Formularios GET y POST</h1>
<p>GET consulta sin modificar datos. POST registra; no cifra: para datos reales se necesita HTTPS.</p>
<?php if ($mensaje !== ''): ?><p role="status"><?= escapar($mensaje) ?></p><?php endif ?>
<?php if ($errores): ?>
<section role="alert"><h2>Revise los datos</h2>
<?php foreach ($errores as $error): ?><p><?= escapar($error) ?></p><?php endforeach ?>
</section>
<?php endif ?>
<h2>Registrar cliente</h2>
<p>Se conservan datos solo en esta sesión de práctica, no en MySQL.
La edad es opcional; si se indica, debe estar entre 16 y 99.</p>
<form action="semana2-registro.php" method="post">
<input type="hidden" name="csrf" value="<?= escapar($_SESSION['csrf']) ?>">
<label>Nombre <input name="nombre" required maxlength="80" value="<?= escapar($valores['nombre']) ?>"></label>
<label>Correo <input type="email" name="correo" required value="<?= escapar($valores['correo']) ?>"></label>
<label>Edad <input type="number" name="edad" min="16" max="99" value="<?= escapar($valores['edad']) ?>"></label>
<label>Carrera <select name="carrera">
<?php foreach (['SOF' => 'Software', 'SIS' => 'Sistemas'] as $codigo => $nombre): ?>
<option value="<?= $codigo ?>" <?= $valores['carrera'] === $codigo ? 'selected' : '' ?>><?= $nombre ?></option>
<?php endforeach ?>
</select></label>
<fieldset><legend>Intereses</legend>
<?php foreach (['web' => 'Web', 'movil' => 'Móvil', 'datos' => 'Datos'] as $codigo => $nombre): ?>
<label><input type="checkbox" name="intereses[]" value="<?= $codigo ?>" <?= in_array($codigo, $valores['intereses'], true) ? 'checked' : '' ?>><?= $nombre ?></label>
<?php endforeach ?>
</fieldset>
<button type="submit">Enviar a otro archivo</button>
<button type="submit" formaction="semana2.php">Procesar en esta página</button>
</form>
<h2>Consultar clientes con GET</h2>
<form action="semana2.php" method="get">
<label>Nombre o correo <input type="search" name="q" value="<?= escapar($consulta) ?>"></label>
<button>Buscar</button>
</form>
<p>Clientes registrados: <?= count($_SESSION['clientes']) ?></p>
<ul>
<?php foreach ($_SESSION['clientes'] as $cliente):
    if ($consulta !== '' && stripos($cliente['nombre'] . ' ' . $cliente['correo'], $consulta) === false) continue;
?>
<li>#<?= $cliente['id'] ?> — <?= escapar($cliente['nombre']) ?> —
<?= escapar($cliente['correo']) ?> — Edad: <?= $cliente['edad'] ?? 'sin indicar' ?> —
<?= escapar($cliente['carrera']) ?> — <?= escapar(implode(', ', $cliente['intereses'])) ?></li>
<?php endforeach ?>
</ul>
<p>La validación rechaza entradas incorrectas; trim normaliza los espacios.
htmlspecialchars escapa la salida, sin alterar los datos guardados.
Tras registrar, una redirección 303 aplica Post/Redirect/Get: recargar no repite el POST.</p>
</body>
</html>
