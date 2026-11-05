# Semana 2 · Clase 1: tipos, conversiones y Cliente {#semana2-clase1-tipos-cliente}

Esta clase conecta valores simples con decisiones observables en código: qué tipo
llega, qué conversión se hace y qué ocurre al gestionar un cliente. Los ejemplos
comparan PHP y C# sin suponer que sus reglas son idénticas. Para referencias de
lenguaje, consulta el manual de PHP y la referencia de C# [@php-manual;
@microsoft-csharp].

El alcance sigue el material de clase aportado como `semana2.md`, contrastado con
las prácticas locales de PHP y C#; no implica acceso nuevo a Blackboard [@course-web-week2-class1].

## 1. Valores simples y ausencia de valor {#s2c1-tipos-simples}

Un escalar contiene un valor: `int` (entero), `float`/`double` (decimal),
`string` (texto) o `bool` (verdadero/falso). `null` no es un quinto escalar:
representa la ausencia de valor. PHP infiere estos tipos desde el valor; C# los
declara o los infiere con `var` y distingue una referencia opcional con `string?`.

```php
$cantidad = 3;        // int
$precio = 12.50;      // float
$producto = "Teclado USB"; // string
$enStock = true;      // bool
$descuento = null;    // ausencia de valor
$subtotal = $cantidad * $precio;
```

**Esperado:** `subtotal` vale `37.5` y es decimal porque interviene `float`.
**Observado en el ejemplo:** las comprobaciones `is_int`, `is_float`, `is_string`,
`is_bool` e `is_null` corresponden a esos cinco valores. Para mostrar dinero se
puede formatear o redondear; no se debe asumir precisión binaria exacta para
operaciones como `0.1 + 0.2`.

En la demostración C#, `int cantidad`, `double precio`, `string producto`,
`bool enStock` y `string? descuento` expresan la misma intención. El cálculo
produce `37.5`; el tipo decimal de punto flotante tampoco convierte una suma en
una regla de validación.

```csharp
using System.Globalization;

var datos = new Dictionary<string, string> { ["ciudad"] = "Ambato" };
double precio = double.Parse("8.5", CultureInfo.InvariantCulture);
bool numerosIguales = int.Parse("1") == int.Parse("01");
bool textosIguales = string.Equals("1", "01", StringComparison.Ordinal);

Console.WriteLine($"{precio}; {numerosIguales}; {textosIguales}; {datos["ciudad"]}");
Console.WriteLine(Busqueda.BuscarCliente(15));
Console.WriteLine(Busqueda.BuscarCliente("0102"));

static class Busqueda
{
    public static string BuscarCliente(int id) => $"BuscarPorId({id})";
    public static string BuscarCliente(string cedula) => $"BuscarPorCedula(\"{cedula}\")";
}
```

**Esperado:** `precio` es `8.5`, `numerosIguales` es `true`,
`textosIguales` es `false` y el diccionario entrega `Ambato` para `"ciudad"`.
Las dos sobrecargas conservan separado buscar por id de buscar por cédula.

## 2. Convertir no es validar {#s2c1-conversiones}

PHP puede convertir implícitamente cuando una operación lo requiere y permite
casts explícitos. Un cast intenta interpretar un valor; no confirma que el texto
completo tenga el formato permitido.

```php
var_dump("10" + 5);          // int(15)
var_dump((int) "125abc");    // int(125)
var_dump((float) "8,5");     // float(8)
var_dump((bool) "0");        // bool(false)
```

**Esperado:** el cast conserva el prefijo numérico de `"125abc"`, la coma no es
separador decimal para ese cast y `"0"` se vuelve `false`. **Observado:** esos
son precisamente los valores comprobados en `php/tests/semana2-tipos.php`.
Por eso aceptar `125abc` o `8,5` como entrada numérica válida sería un error de
validación, aunque el cast devuelva algo. En C#, la demostración analiza `"8.5"`
con `double.Parse` y cultura invariante; para una entrada externa se decide y
verifica el formato antes de usar el número.

También son falsos al convertir a booleano `0`, `""`, `[]` y `null`. No los
uses como sustituto de una regla de negocio: una regla debe decir qué ausencia,
texto o número acepta.

### Igualdad: valor y tipo {#s2c1-igualdad}

En PHP 8, `0 == "a"` es `false`; `"1" == "01"` es `true` por comparación
numérica, mientras `"1" === "01"` es `false` porque exige tipo y valor.
Prefiere `===` cuando comparas datos que ya tienen tipo conocido. C# no hace ese
*type juggling*: el ejemplo convierte ambos textos a entero para comparar sus
números y usa `string.Equals(..., StringComparison.Ordinal)` para contrastar
los textos.

## 3. Contratos de tipo {#s2c1-contratos-tipo}

`declare(strict_types=1);` cambia cómo PHP trata llamadas hechas desde ese
archivo: una cadena como `"3"` no se acepta silenciosamente por un parámetro
`int`. No impide que un `int` se use donde el parámetro declara `float`.

```php
<?php
declare(strict_types=1);

function calcularTotal(int $cantidad, float $precio,
    ?float $descuento = null): float {
    $total = $cantidad * $precio;
    if ($descuento !== null) {
        $total -= $total * $descuento;
    }
    return round($total, 2);
}
```

**Esperado:** `calcularTotal(3, 12.5)` resulta `37.5` y, con `0.10`, `33.75`.
**Observado:** ambas llamadas pasan en la prueba; `calcularTotal("3", 12.5)`
lanza `TypeError` desde la llamada estricta. `?float` permite un `float` o
`null`. PHP además declara `int|string` para una clave de búsqueda; C# no tiene
ese parámetro unión: dos sobrecargas, una para `int` y otra para `string`,
conservan la intención de cada entrada.

## 4. Nombres dinámicos bajo control {#s2c1-nombres-dinamicos}

PHP permite que una variable determine el nombre de otra. Es útil para entender
el lenguaje, pero no debe construirse desde datos de usuario.

```php
$campo = "ciudad";
$$campo = "Ambato";
$suma = 0;
for ($i = 1; $i <= 3; $i++) {
    ${"nota$i"} = $i * 3;
    $suma += ${"nota$i"};
}
$datos = [$campo => "Ambato"];
```

**Esperado:** existe `$ciudad` con `Ambato` y la suma de las notas es `18`.
**Observado:** el ejemplo comprueba ambos resultados. El arreglo asociativo
`$datos['ciudad']` logra la misma consulta de manera visible y recorrible. C#
no tiene `$$campo`; usa `Dictionary<string, string>` para una clave dinámica
controlada, también con `ciudad = Ambato`.

## 5. Cliente tipado y operaciones en memoria {#s2c1-cliente-crud}

`Cliente` reúne un `id` entero, nombre y correo de texto, `activo` booleano y
teléfono opcional. El repositorio usa el id como clave de un arreglo PHP o un
`Dictionary<int, Cliente>` C#. Sus operaciones son:

| Operación | Efecto observado | Id inexistente |
|---|---|---|
| registrar | guarda por id; registrar el mismo id **reemplaza** el cliente anterior | no aplica |
| consultar | devuelve el cliente o `null` | `null` |
| listar | devuelve los clientes guardados | lista vacía si no había datos |
| actualizarCorreo | cambia el correo y devuelve `true` | no cambia datos; devuelve `false` |
| eliminar | quita el cliente y devuelve `true` | no cambia datos; devuelve `false` |

El siguiente es un extracto: presupone que ya se cargaron las clases
`Cliente` y `ClienteRepositorioMemoria` de `php/src/semana2-cliente.php`.

```php
$repo = new ClienteRepositorioMemoria();
$repo->registrar(new Cliente(1, "Ana Pérez", "ana@correo.com"));
$repo->actualizarCorreo(1, "ana.perez@correo.com");
$noExiste = $repo->consultar(999); // null
```

**Esperado:** Ana queda con el correo actualizado y `999` no crea ni modifica
un cliente. **Observado:** las pruebas cubren consultar, listar, actualizar y
eliminar, incluidos los id `999`; no hay una regla de rechazo de duplicados: el
registro por la misma clave reemplaza el valor según la fuente.

El repositorio de las demostraciones existe solo en memoria. En una ejecución
PHP termina al acabar la solicitud; crear otro repositorio no conserva sus
clientes. La acción `Tipos` de C# también crea uno nuevo por solicitud. La
aplicación de formularios C# usa una lista serializada en sesión para otro
recorrido, por lo que puede reaparecer durante esa sesión; eso no convierte al
repositorio de la demostración en una base de datos.

## Pasos de práctica {#s2c1-pasos-practica}

1. Predice tipo y valor de cada cast antes de ejecutarlo; separa conversión de
   aceptación de entrada.
2. Ejecuta desde la raíz `php php/tests/semana2-tipos.php` y registra la salida.
3. Ejecuta desde la raíz `php php/tests/semana2-cliente.php`; cambia solo una
   predicción en tus notas, no las reglas del repositorio.
4. Compara el resultado con `Semana2/Tipos` en C#: identifica qué hace el
   cast/parsing y qué dato queda solo en memoria.
5. Continúa con [formularios, GET y POST](02-formularios-get-post.md#semana2-clase2-formularios-get-post) para ver
   cómo un texto llega por una solicitud. La navegación de la asignatura está
   en [Aplicaciones Web](../../aplicaciones-web.md#cobertura-actual).

## Ejercicios y respuestas razonadas {#s2c1-ejercicios}

### Ejercicio 1 {#s2c1-ej-1}

¿Por qué `(int) "125abc"` no valida un id?

### Ejercicio 2 {#s2c1-ej-2}

Predice `calcularTotal(3, 12.5, 0.10)` y explica qué ocurriría con `"3"` como
primer argumento en la llamada estricta.

### Ejercicio 3 {#s2c1-ej-3}

Compara `"1" == "01"` con `"1" === "01"`. ¿Qué información exige la segunda
comparación?

### Ejercicio 4 {#s2c1-ej-4}

Si se registra dos veces el id `2`, ¿qué ocurre? ¿Qué devuelve eliminar `999` y
qué datos cambia?

### Ejercicio 5 {#s2c1-ej-5}

Elige entre `$$campo` y un arreglo/Dictionary para una ciudad que llega de un
formulario. Justifica la elección.

### Respuestas {#s2c1-respuestas}

### Respuesta 1 {#s2c1-r-1}

[Volver al ejercicio](#s2c1-ej-1). El cast toma el prefijo `125` y descarta que
el resto haga inválido el formato; primero debe verificarse que todo el texto
cumpla la regla del id.

### Respuesta 2 {#s2c1-r-2}

[Volver al ejercicio](#s2c1-ej-2). El resultado es `33.75`. Con `"3"`, el modo
estricto de la llamada produce `TypeError`; el contrato detecta la discrepancia,
pero no valida por sí solo una entrada web.

### Respuesta 3 {#s2c1-r-3}

[Volver al ejercicio](#s2c1-ej-3). La primera es verdadera por la comparación
numérica flexible; la segunda es falsa porque también exige que ambos sean el
mismo texto y del mismo tipo.

### Respuesta 4 {#s2c1-r-4}

[Volver al ejercicio](#s2c1-ej-4). El segundo registro reemplaza al valor de la
clave `2`. Eliminar `999` devuelve `false` y no modifica la colección.

### Respuesta 5 {#s2c1-r-5}

[Volver al ejercicio](#s2c1-ej-5). El arreglo o `Dictionary` mantiene las claves
visibles, permite recorrerlas y evita crear nombres de variables desde una
entrada externa; `$$campo` queda para un caso controlado y explícito.
