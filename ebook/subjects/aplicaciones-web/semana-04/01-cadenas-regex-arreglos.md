# Semana 4 · Clase 1: cadenas, expresiones regulares y arreglos {#semana4-clase1-cadenas}

Esta lección transforma texto y colecciones con reglas que se puedan revisar. Los **ejemplos instructivos** predicen resultados; no son una aplicación ejecutada localmente, no abren una base de datos ni validan un sistema completo.

## Objetivos

Al terminar podrás:

- diferenciar caracteres UTF-8 de bytes y elegir una función `mb_*` cuando corresponde;
- interpretar el resultado y los fallos de `preg_match` sin convertir una expresión regular en una garantía de seguridad;
- transformar arreglos indexados, asociativos y de filas con operaciones explícitas;
- contrastar validación PHP con DataAnnotations y transformaciones PHP con LINQ en C#.

Consulta el [manual de cadenas de PHP](https://www.php.net/manual/es/book.strings.php), [PCRE](https://www.php.net/manual/es/book.pcre.php), [arreglos](https://www.php.net/manual/es/language.types.array.php) y las [anotaciones de datos de .NET](https://learn.microsoft.com/en-us/dotnet/api/system.componentmodel.dataannotations).

## 1. Texto UTF-8: carácter no es byte

UTF-8 representa algunos caracteres con más de un byte. Por eso `strlen()` mide bytes, mientras `mb_strlen($texto, 'UTF-8')` mide caracteres según esa codificación. Para `"año"`, la predicción es `strlen` = 4 y `mb_strlen` = 3: `ñ` ocupa dos bytes UTF-8. No supongas que los resultados coinciden para texto con tildes, eñes o emoji.

```php
$nombre = "  maría  ";
$limpio = trim($nombre);
echo mb_strtoupper($limpio, 'UTF-8'); // MARÍA
echo mb_strlen($limpio, 'UTF-8');     // 5
```

**Razón:** `trim` retira espacios de los extremos; la operación multibyte conserva y reconoce `í`. Para presentar entrada no confiable en HTML se escapa al final con `htmlspecialchars`; normalizar texto no sustituye el escape contextual.

## 2. Expresiones regulares: resultado, error y límite

Una regular expression describe un formato. `preg_match` devuelve `1` si hay coincidencia, `0` si no la hay y `false` si el patrón falla. Por ello `=== 1` diferencia con precisión coincidencia de no coincidencia/error. Un formato válido no confirma que una persona, correo o documento exista.

```php
$patron = '/^[a-záéíóúñü ]{2,80}$/iu';
$resultado = preg_match($patron, 'María José');
// Predicción: $resultado === 1 (coincide)

$sinCoincidencia = preg_match('/^09\d{8}$/', '09123');
// Predicción: 0 (no cumple diez dígitos)

$fallo = preg_match('/[abc/', 'Ana');
// Predicción: false; el delimitador/patrón está mal formado.
```

Anclar con `^` y `$` exige cubrir toda la cadena; `i` ignora mayúsculas y `u` trabaja en modo UTF-8. Ante `false`, el programa debe registrar o diagnosticar el patrón de forma apropiada y no aceptar la entrada. Una regex tampoco reemplaza validación de negocio, consultas parametrizadas o codificación HTML.

### Extracción con grupos

```php
if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', '2026-10-26', $m) === 1) {
    echo "$m[3]/$m[2]/$m[1]";
}
// Salida prevista: 26/10/2026
```

Los paréntesis capturan año, mes y día. La coincidencia dice que el texto tiene esa forma; no prueba que una fecha de calendario sea válida.

## 3. Arreglos: representar y transformar datos

Un arreglo puede usar índices numéricos, claves de texto o contener filas. Elegir la forma hace visible qué se consulta.

```php
$lenguajes = ['PHP', 'C#'];
$cliente = ['nombre' => 'Ana', 'activo' => true];
$pedidos = [
    ['cliente' => 'Ana', 'total' => 20],
    ['cliente' => 'Luis', 'total' => 50],
    ['cliente' => 'Ana', 'total' => 10],
];

$grandes = array_filter($pedidos, fn ($p) => $p['total'] >= 20);
$nombres = array_map(fn ($p) => $p['cliente'], $grandes);
$total = array_sum(array_column($pedidos, 'total'));
// Predicción: $nombres es ['Ana', 'Luis']; $total es 80.
```

`array_filter` conserva las claves originales, así que si el índice consecutivo importa puede requerirse `array_values`. `array_map` crea una transformación y `array_column` extrae una columna. No modifiques la colección mientras la recorres sin una regla clara: separa entrada, transformación y resultado.

### Ejercicio resuelto: agrupar antes de mostrar

Para las tres filas anteriores, acumula por cliente: Ana recibe `20 + 10 = 30` y Luis `50`.

```php
$porCliente = [];
foreach ($pedidos as $pedido) {
    $nombre = $pedido['cliente'];
    $porCliente[$nombre] = ($porCliente[$nombre] ?? 0) + $pedido['total'];
}
// Predicción: ['Ana' => 30, 'Luis' => 50]
```

El operador `??` inicializa solo el acumulador inexistente. Si estos datos provinieran de una solicitud, primero se validaría su forma y tipos; el ejemplo no persiste ni acepta entrada web.

## 4. Contraste: PHP, DataAnnotations y LINQ

En PHP, una capa de aplicación puede usar `filter_var`, reglas propias o `preg_match` antes de continuar. En ASP.NET Core, **DataAnnotations** como `[Required]`, `[Length]` o `[EmailAddress]` describen reglas que el modelo debe revisar mediante `ModelState`. Ninguna opción elimina la necesidad de validar en el servidor.

Para colecciones, PHP usa `array_filter`, `array_map` y `usort`; C# suele expresar intención con LINQ:

```csharp
var nombres = pedidos
    .Where(p => p.Total >= 20)
    .Select(p => p.Cliente)
    .OrderBy(nombre => nombre);
// Predicción: Ana, Luis
```

LINQ no es una copia sintáctica de los arreglos PHP: ambas alternativas transforman una colección, pero tipos, evaluación y APIs pertenecen a cada plataforma. Véanse [validación de modelo en ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/mvc/models/validation) y [LINQ](https://learn.microsoft.com/en-us/dotnet/csharp/linq/).

## Práctica y soluciones

1. **Predice:** ¿cuánto devuelve `mb_strlen('niño', 'UTF-8')`? **Solución:** 4 caracteres; `ñ` no cuenta como dos caracteres aunque ocupe más de un byte.
2. **Decide:** una regex devuelve `0`. ¿se guarda el dato? **Solución:** no; no coincide con el formato y se debe comunicar la regla sin tratarlo como éxito.
3. **Transforma:** filtra totales mayores que 40 en `[20, 50, 10]`. **Solución:** `[50]`; después puede sumarse o presentarse según la necesidad.

## Cierre

Las cadenas se miden con la codificación correcta; una regex produce un resultado que hay que interpretar; y los arreglos permiten filtrar, proyectar y acumular sin ocultar la regla. Estos ejemplos instructivos no prueban ejecución local, persistencia ni una aplicación web completa.

## Autoevaluación {#s4c1-autoevaluacion}

### 1. UTF-8 y longitud
<!-- quiz: web-w4c1-utf8 -->

### 2. Resultado de regex
<!-- quiz: web-w4c1-regex-result -->

### 3. Patrón defectuoso
<!-- quiz: web-w4c1-regex-failure -->

### 4. Transformación de arreglos
<!-- quiz: web-w4c1-array-transform -->

### 5. Validación de modelos
<!-- quiz: web-w4c1-dataannotations -->

### 6. Contraste con LINQ
<!-- quiz: web-w4c1-linq -->
