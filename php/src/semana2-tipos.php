<?php
declare(strict_types=1);

// ============================================================
// Demo S2C1 — Tipos de datos simples, conversión, modo estricto,
// declaraciones de tipo y variables de variables.
// Basado en semana2.md (material proporcionado por el usuario/docente)
// ============================================================

// --- Tipos simples (scalars) ---
$cantidad = 3;                 // int
$precio   = 12.50;             // float
$producto = "Teclado USB";     // string
$enStock  = true;              // bool
$descuento = null;             // null

$subtotal = $cantidad * $precio;          // int * float = float (type juggling)

// Funciones de verificación
$esInt     = is_int($cantidad);
$esFloat   = is_float($precio);
$esString  = is_string($producto);
$esBool    = is_bool($enStock);
$esNull    = is_null($descuento);

// --- Conversión de tipos ---
// Conversión automática (type juggling)
$convAuto1 = "10" + 5;        // int(15)
$convAuto2 = "3.5" * 2;       // float(7)
$convAuto3 = 10 . "";         // string "10"

// Conversión explícita (cast)
$textoCast = "125abc";
$castInt    = (int) $textoCast;      // int(125)
$castFloat  = (float) "8,5";         // float(8): la coma no es separador decimal
$castBool   = (bool) "0";            // bool(false)
$castString = (string) 3.0;          // string "3"

// Valores que se consideran false
$boolZero   = (bool) 0;
$boolEmpty  = (bool) "";
$boolArray  = (bool) [];
$boolNull   = (bool) null;

// Comparación flexible (==) vs estricta (===)
$cmp1 = (0 == "a");       // false en PHP 8
$cmp2 = ("1" == "01");    // true  (compara como números)
$cmp3 = ("1" === "01");   // false (mismo tipo y valor exigidos)

// --- Declaraciones de tipo y modo estricto ---
function calcularTotal(int $cantidad, float $precio, ?float $descuento = null): float
{
    $total = $cantidad * $precio;
    if ($descuento !== null) {
        $total -= $total * $descuento;
    }
    return round($total, 2);
}

$totalSinDesc  = calcularTotal(3, 12.5);
$totalConDesc  = calcularTotal(3, 12.5, 0.10);

// Tipos unión (PHP 8.0+)
function buscarCliente(int|string $clave): string {
    return is_int($clave) ? "Buscar por id $clave" : "Buscar por cédula $clave";
}

$buscarPorId     = buscarCliente(123);
$buscarPorCedula = buscarCliente("0101234567");

// --- Variables de variables ---
$campo = "ciudad";
$$campo = "Ambato";          // crea la variable $ciudad dinámicamente
$valorCiudad = $ciudad;
$valorCiudadLlaves = ${$campo};

// Construir nombres dinámicos
for ($i = 1; $i <= 3; $i++) {
    ${"nota$i"} = $i * 3;     // crea $nota1, $nota2, $nota3
}
$sumaNotas = $nota1 + $nota2 + $nota3;

// Propiedades dinámicas en objetos
$obj = new stdClass();
$propiedad = "telefono";
$obj->$propiedad = "0991234567";
$telefonoObj = $obj->telefono;

// Alternativa recomendada: arreglo asociativo
$datos = [];
$datos[$campo] = "Ambato";
$ciudadArray = $datos['ciudad'];

