<?php
declare(strict_types=1);

// ============================================================
// Demo S1C2 — Variables en PHP: declaración, tipos y ámbito.
// Par en C#: /Home/Variables del stack csharp/.
// Lógica de la demo: la entrada es public/variables.php y la
// presentación vive en views/variables.php (require/include).
// ============================================================

// --- Declaración y asignación: sin tipo declarado, el valor define el tipo ---
$curso = "Aplicaciones Web";   // string  (convención de nombres: $snake_case)
$nota = 9.5;                   // float
$inscrito = true;              // bool

// --- Conversiones ---
$sumaImplicita = "3" + 3;      // Una cadena numérica se convierte a int sin warnings: 6.
$edadTexto = (string) 25;      // explícita (casting)

// --- Ámbito 1: global (nivel archivo) ---
function sinGlobal()
{
    // Una función NO hereda el ámbito exterior
    return isset($curso) ? "sí ve: $curso" : "no ve la variable global";
}

function conGlobal()
{
    global $curso;             // acceso explícito al ámbito global
    return $curso;
}

// --- Ámbito 2: "bloque" (PHP no tiene ámbito de bloque) ---
$recorrido = 0;
foreach ([10, 20, 30] as $valor) {
    $recorrido += $valor;
}
// En C# '$valor' ya no existiría aquí; en PHP sigue valiendo 30
$valorTrasElBucle = $valor;

// --- Constantes: llegan desde config/config.php vía require en public/variables.php ---
// CURSO se declara con const; ETIQUETA con define(). Ambas ya están disponibles aquí.

// --- Nulos e interpolación ---
$docente = null;                       // sin valor asignado: tipo Null
$saludo = "Estudiante: $curso";        // interpolación entre comillas dobles
$notaFinal = $docente ?? 'sin nota';   // ?? sustituye null por un valor por defecto

// --- Parámetros en vez de global ---
function cursoDe(string $nombre): string
{
    return "Curso: $nombre";
}
