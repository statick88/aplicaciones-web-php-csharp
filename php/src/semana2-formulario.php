<?php
declare(strict_types=1);

require_once __DIR__ . '/semana2-cliente.php';

/** Validate shape before trimming: HTTP fields can also be arrays. */
function validarRegistro(array $entrada): array
{
    $valores = [];
    $errores = [];
    foreach (['nombre', 'correo', 'edad', 'carrera'] as $campo) {
        $valor = $entrada[$campo] ?? '';
        if (!is_string($valor)) {
            $errores[$campo] = 'El campo debe ser texto.';
            $valor = '';
        }
        $valores[$campo] = trim($valor);
    }
    $longitud = preg_match_all('/./us', $valores['nombre']);
    if ($longitud === false || $longitud < 1 || $longitud > 80) {
        $errores['nombre'] = 'El nombre es obligatorio (máximo 80 caracteres).';
    }
    if (filter_var($valores['correo'], FILTER_VALIDATE_EMAIL) === false) {
        $errores['correo'] = 'Ingrese un correo válido.';
    }
    $edad = $valores['edad'] === '' ? null : filter_var(
        $valores['edad'], FILTER_VALIDATE_INT,
        ['options' => ['min_range' => 16, 'max_range' => 99]]
    );
    if ($edad === false) {
        $errores['edad'] = 'La edad debe estar entre 16 y 99.';
    }
    if (!in_array($valores['carrera'], ['SOF', 'SIS'], true)) {
        $errores['carrera'] = 'Carrera no válida.';
    }
    $intereses = $entrada['intereses'] ?? [];
    if (!is_array($intereses)) {
        $errores['intereses'] = 'Seleccione intereses válidos.';
        $intereses = [];
    }
    $valores['intereses'] = [];
    foreach ($intereses as $interes) {
        if (!is_string($interes) || !in_array($interes, ['web', 'movil', 'datos'], true)) {
            $errores['intereses'] = 'Seleccione intereses válidos.';
        } else {
            $valores['intereses'][] = $interes;
        }
    }
    return [$valores, $errores, $edad];
}

function escapar(string $texto): string
{
    return htmlspecialchars($texto, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
