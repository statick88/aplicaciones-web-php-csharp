# Semana 3 · Clase 2: control, ciclos y funciones {#semana3-clase2-control-funciones}

Esta unidad enseña a convertir una regla en un recorrido legible: decidir con
condiciones, repetir solo lo necesario y encapsular cálculos en funciones con
responsabilidades claras. La comparación entre PHP y C# destaca coincidencias
de intención sin afirmar que ambos lenguajes tengan la misma sintaxis.

Al terminar podrás:

- elegir entre `if`, `switch` y `match` según la regla que debes expresar;
- recorrer rangos y colecciones sin perder los límites ni el caso vacío;
- declarar parámetros y retornos que hagan visible el contrato de una función;
- distinguir paso por valor, referencias y cierres sin ocultar cambios de estado;
- separar decisiones, cálculos y presentación en funciones pequeñas.

**Prerrequisito:** reconocer tipos, conversiones y comparaciones. Si necesitas
repasarlos, vuelve a [tipos, conversiones y Cliente](../semana-02/01-tipos-cliente.md#semana2-clase1-tipos-cliente).

Las reglas se contrastan con el
[manual de estructuras de control de PHP](https://www.php.net/manual/en/language.control-structures.php),
la [documentación de funciones de PHP](https://www.php.net/manual/en/language.functions.php)
y la [referencia de instrucciones de selección de C#](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/selection-statements).
Los resultados marcados como ejecutados corresponden únicamente a los dos
programas autónomos de esta página: no abren archivos, no usan red y no guardan
datos.

## 1. Elegir una rama con intención {#s3c2-condiciones}

Una condición no es solo sintaxis: documenta qué casos reconoce el programa.
Antes de escribirla, define los límites. Por ejemplo, si `90` inicia el nivel
alto y `70` el medio, entonces `89`, `90`, `69` y `70` son casos distintos que
conviene predecir.

### `if` para rangos y reglas heterogéneas {#s3c2-if}

`if` funciona bien cuando cada rama evalúa una expresión diferente o un rango.
El orden importa: primero se comprueba el límite más exigente. Si se preguntara
primero por `>= 70`, un valor de `95` quedaría clasificado como medio antes de
alcanzar la rama alta.

En PHP y C#, una cadena de `if`/`else if` puede expresar la misma decisión,
pero cada lenguaje conserva sus propias reglas de tipos y comparaciones. No
copies una condición entre lenguajes sin revisar qué valores admite.

### `switch` y `match` no son sinónimos {#s3c2-switch-match}

`switch` organiza casos discretos. En C#, una expresión `switch` puede devolver
un valor y usar patrones como `>= 90`. PHP también tiene `switch`, pero
`match` es una expresión: devuelve un resultado, compara de forma estricta y no
continúa por caída hacia el siguiente brazo. Si ningún brazo coincide y no hay
`default`, PHP lanza `UnhandledMatchError`.

La forma `match (true)` permite escribir rangos porque cada brazo produce un
booleano. Es útil cuando todas las ramas calculan una sola respuesta. No debe
usarse para esconder muchas acciones laterales; en ese caso, una estructura más
explícita suele ser más legible. Consulta la
[referencia oficial de `match`](https://www.php.net/manual/en/control-structures.match.php)
y las [expresiones `switch` de C#](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/switch-expression).

## 2. Repetir con límites visibles {#s3c2-ciclos}

Todo ciclo necesita responder tres preguntas: ¿dónde inicia?, ¿cuándo termina?
y ¿qué cambia en cada vuelta? Una comparación equivocada entre `<` y `<=` puede
agregar una iteración o excluir el último elemento.

| Estructura | Elección habitual | Riesgo que debes revisar |
|---|---|---|
| `for` | conoces el contador o el rango | inicio, límite y actualización |
| `while` | repites mientras una condición siga vigente | condición falsa desde el inicio o ciclo infinito |
| `foreach` | recorres todos los elementos de una colección | colección vacía y cambios accidentales |

### Colecciones vacías {#s3c2-colecciones-vacias}

Un `foreach` sobre una colección vacía ejecuta cero iteraciones; no es un error.
La suma de sus elementos puede conservar el valor inicial `0`, pero ese cero no
prueba que hubiera un elemento cuyo valor fuera cero. Son estados diferentes:
“sin elementos” y “un elemento con cero”.

Un `while` también puede ejecutar cero veces si su condición es falsa desde el
principio. Cuando la acción debe ocurrir al menos una vez, revisa si un
`do`/`while` expresa mejor la intención; aun así, la condición de salida debe
ser comprobable.

### Fronteras e índices {#s3c2-fronteras}

Para una colección de longitud `n`, los índices habituales van de `0` a `n - 1`.
Por eso un `for` basado en índice usa normalmente `i < n`, no `i <= n`.
Cuando solo necesitas cada valor, `foreach` evita administrar ese límite a mano.
La guía oficial de PHP reúne estas estructuras en
[control de flujo](https://www.php.net/manual/en/language.control-structures.php),
y Microsoft documenta las
[instrucciones de iteración de C#](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/iteration-statements).

## 3. Funciones como contratos pequeños {#s3c2-funciones}

Una función recibe entradas, realiza una responsabilidad y entrega un resultado
o un efecto declarado. Los nombres concretos ayudan: `clasificarPuntaje` explica
más que `procesar`, y `sumarPositivos` explica qué valores incluye.

PHP permite declarar tipos de parámetros y retorno. Con
`declare(strict_types=1)`, las llamadas hechas desde ese archivo evitan varias
conversiones escalares silenciosas. C# comprueba sus tipos estáticos al compilar.
En ambos casos, un tipo no reemplaza las reglas de dominio: que un valor sea
`int` no garantiza que pertenezca al rango esperado.

Conviene separar tres responsabilidades:

1. **decidir**, por ejemplo clasificar un puntaje;
2. **calcular**, por ejemplo sumar importes positivos;
3. **presentar**, por ejemplo construir la línea que se imprime.

Así cada función puede comprobarse con entradas normales, límites y colecciones
vacías. Una función que decide, imprime, modifica una colección y además guarda
datos mezcla evidencias difíciles de interpretar. Esta unidad no agrega
servidores, persistencia ni operaciones CRUD.

## 4. Valores, referencias y cambios observables {#s3c2-valor-referencia}

En PHP, los argumentos se pasan por valor de forma predeterminada. Para arreglos,
la función recibe un valor que puede modificar localmente sin cambiar la variable
del llamador. El operador `&` en la firma declara paso por referencia y permite
cambiar esa variable original. Ese efecto debe ser excepcional y visible en el
nombre y la documentación de la función.

En C#, los parámetros también se pasan por valor de forma predeterminada. En una
referencia a un objeto, se copia la referencia: el objeto puede seguir siendo
mutable, aunque reasignar el parámetro local no reasigne la variable externa.
La palabra `ref` permite trabajar con la ubicación de la variable del llamador
y debe aparecer tanto en la firma como en la llamada. Consulta
[referencias en PHP](https://www.php.net/manual/en/language.references.pass.php)
y [parámetros de método en C#](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/method-parameters).

Usa un retorno cuando la transformación puede expresarse como un nuevo valor.
Reserva una referencia para una intención concreta que no resulte más clara con
un retorno. Esta elección reduce cambios ocultos y facilita razonar sobre el
estado anterior y posterior.

## 5. Cierres y funciones flecha en PHP {#s3c2-cierres}

Una función anónima puede guardarse en una variable o entregarse como argumento.
En PHP, un cierre importa variables exteriores con `use`; por defecto captura su
valor en el momento de crear el cierre. Una función flecha usa `fn` y captura
automáticamente por valor las variables utilizadas en su expresión.

Las funciones flecha de PHP contienen una sola expresión. Son adecuadas para una
transformación o predicado breve, como seleccionar importes positivos. Si la
regla necesita varias decisiones, nombres intermedios o efectos, una función
normal o un cierre con bloque suele comunicar mejor la intención. Revisa la
[documentación oficial de funciones anónimas](https://www.php.net/manual/en/functions.anonymous.php)
y de [funciones flecha](https://www.php.net/manual/en/functions.arrow.php).

C# ofrece lambdas y cierres con una intención comparable, pero no se debe inferir
que sus detalles de captura sean idénticos a PHP. En el ejemplo autónomo, la
lambda lee un descuento local para producir un nuevo total; no modifica datos
externos.

## 6. Ejemplo autónomo en PHP {#s3c2-ejemplo-php}

Este programa reúne decisiones, tres formas de ciclo, funciones tipadas, paso
por valor y referencia, un cierre y una función flecha. Los importes son enteros
en centavos; no representan una regla fiscal ni una operación bancaria.

```php
<?php
declare(strict_types=1);

function clasificarPuntaje(int $puntos): string
{
    return match (true) {
        $puntos >= 90 => 'alto',
        $puntos >= 70 => 'medio',
        default => 'inicial',
    };
}

function sumarPositivos(array $importes): int
{
    $total = 0;
    foreach ($importes as $importe) {
        if ($importe > 0) {
            $total += $importe;
        }
    }
    return $total;
}

function agregarPorValor(array $valores): array
{
    $valores[] = 2;
    return $valores;
}

function agregarPorReferencia(array &$valores): void
{
    $valores[] = 2;
}

$importes = [1250, 750, 0];
$indices = [];
for ($i = 0; $i < count($importes); $i++) {
    $indices[] = $i;
}

$pendientes = [];
$vueltas = 0;
while (count($pendientes) > 0) {
    $vueltas++;
    array_shift($pendientes);
}

$original = [1];
$copia = agregarPorValor($original);
agregarPorReferencia($original);

$descuento = 100;
$ajustar = function (int $subtotal) use ($descuento): int {
    return $subtotal - $descuento;
};
$positivos = array_filter($importes, fn (int $valor): bool => $valor > 0);
$total = sumarPositivos($importes);

echo 'nivel=' . clasificarPuntaje(70) . PHP_EOL;
echo 'for=' . implode(',', $indices) . PHP_EOL;
echo 'while=' . ($vueltas === 0 ? 'vacio' : (string) $vueltas) . PHP_EOL;
echo 'foreach=' . $total . PHP_EOL;
echo 'valor=' . count($copia) . '/original=' . count($original) . PHP_EOL;
echo 'closure=' . $ajustar($total) . PHP_EOL;
echo 'arrow=' . count($positivos) . PHP_EOL;
```

**Salida esperada (`stdout`):**

    nivel=medio
    for=0,1,2
    while=vacio
    foreach=2000
    valor=2/original=2
    closure=1900
    arrow=2

**Lectura crítica:** `70` cae exactamente en el límite medio; el `for` no intenta
el índice `3`; el `while` no entra porque la colección está vacía; `foreach`
ignora el cero al sumar positivos. La copia retornada y el arreglo original
terminan con dos elementos por caminos distintos: la primera función devuelve
un valor nuevo y la segunda modifica mediante `&`. La salida confirma el
resultado, no persistencia ni comportamiento web.

## 7. Ejemplo autónomo en C# {#s3c2-ejemplo-csharp}

El programa equivalente conserva los mismos datos y resultados observables.
Usa una expresión `switch`, `for`, `while`, `foreach`, funciones tipadas, un
parámetro `ref` y una lambda. No necesita paquetes externos.

```csharp
using System;
using System.Collections.Generic;
using System.Linq;

var importes = new[] { 1250, 750, 0 };
var indices = new List<int>();
for (var i = 0; i < importes.Length; i++)
{
    indices.Add(i);
}

var pendientes = new Queue<int>();
var vueltas = 0;
while (pendientes.Count > 0)
{
    vueltas++;
    pendientes.Dequeue();
}

var original = new[] { 1 };
var copia = AgregarPorValor(original);
var cantidadOriginal = original.Length;
AgregarPorReferencia(ref cantidadOriginal);

var descuento = 100;
Func<int, int> ajustar = subtotal => subtotal - descuento;
var positivos = importes.Where(valor => valor > 0).ToArray();
var total = SumarPositivos(importes);

Console.WriteLine($"nivel={ClasificarPuntaje(70)}");
Console.WriteLine($"for={string.Join(',', indices)}");
Console.WriteLine($"while={(vueltas == 0 ? "vacio" : vueltas)}");
Console.WriteLine($"foreach={total}");
Console.WriteLine($"valor={copia.Length}/original={cantidadOriginal}");
Console.WriteLine($"closure={ajustar(total)}");
Console.WriteLine($"lambda={positivos.Length}");

static string ClasificarPuntaje(int puntos) => puntos switch
{
    >= 90 => "alto",
    >= 70 => "medio",
    _ => "inicial"
};

static int SumarPositivos(IEnumerable<int> importes)
{
    var total = 0;
    foreach (var importe in importes)
    {
        if (importe > 0)
        {
            total += importe;
        }
    }
    return total;
}

static int[] AgregarPorValor(int[] valores) => valores.Append(2).ToArray();

static void AgregarPorReferencia(ref int cantidad) => cantidad++;
```

**Salida esperada (`stdout`):**

    nivel=medio
    for=0,1,2
    while=vacio
    foreach=2000
    valor=2/original=2
    closure=1900
    lambda=2

**Lectura crítica:** `AgregarPorValor` recibe una referencia por valor y devuelve
un arreglo nuevo; no cambia la longitud del arreglo original. El ejemplo `ref`
trabaja deliberadamente con la variable entera `cantidadOriginal`, por eso la
llamada debe escribir `ref`. Que ambas cantidades terminen en `2` no significa
que los mecanismos sean iguales.

## 8. Predicción y comprobación {#s3c2-practica}

Antes de ejecutar, usa estas variantes como práctica opcional. No necesitas
escribir respuestas: la autoevaluación de esta unidad se responde con opciones.

1. cambia el puntaje a `69`, `70`, `89` y `90`;
2. cambia `importes` por una colección vacía y predice suma y cantidad;
3. prueba un solo importe positivo y comprueba el límite del `for`;
4. elimina la llamada por referencia y distingue el valor original de la copia;
5. cambia el descuento después de crear el cierre y compara las reglas de
   captura de cada lenguaje con su documentación oficial.

Después separa tres afirmaciones:

- **conocimiento:** la documentación define la estructura y sus reglas;
- **ejecución verificada:** el programa produjo exactamente la salida observada;
- **persistencia:** no fue evaluada, porque estos ejemplos no almacenan datos.

No conviertas una compilación correcta en prueba de todos los límites. Los casos
vacío, primero, último y justo fuera del rango aportan evidencia distinta.

## 9. Errores frecuentes {#s3c2-errores}

- usar `<= count(...)` y acceder una posición fuera de la colección;
- asumir que un ciclo siempre se ejecuta al menos una vez;
- confundir una colección vacía con una colección que contiene cero;
- omitir `default` sin decidir qué debe ocurrir ante un caso desconocido;
- usar referencia cuando un retorno haría el cambio más explícito;
- capturar estado mutable en un cierre sin explicar cuándo se lee;
- crear una función que decide, calcula, imprime y persiste a la vez;
- afirmar equivalencia total entre PHP y C# porque una salida coincide.

## 10. Resumen y siguiente paso {#s3c2-resumen}

`if` expresa rangos y condiciones variadas; `switch` y `match` organizan casos,
pero conservan semánticas propias. `for`, `while` y `foreach` deben explicar sus
límites y el caso de cero iteraciones. Los tipos hacen visible parte del contrato
de una función; los retornos, referencias y cierres determinan dónde puede
cambiar el estado. Una responsabilidad pequeña facilita predecir y comprobar.

Continúa con [formularios, GET y POST](../semana-02/02-formularios-get-post.md#semana2-clase2-formularios-get-post)
para recordar cómo una entrada externa llega al programa. También puedes volver a
[constantes, operadores y datos](01-constantes-operadores-datos.md#semana3-clase1-constantes-operadores)
para conectar las expresiones con las decisiones. Esta unidad se limita a reglas
de lenguaje y ejemplos autónomos; no implementa persistencia ni un CRUD.

## Ejercicios de opción múltiple {#s3c2-ejercicios}

Selecciona una alternativa y usa la retroalimentación para regresar al límite,
contrato o ejemplo correspondiente. No se solicita respuesta abierta.

### Ejercicio 1: límite de clasificación {#s3c2-ej-1}
<!-- quiz: web-w3c2-if-boundary -->

### Ejercicio 2: elegir `match` {#s3c2-ej-2}
<!-- quiz: web-w3c2-match -->

### Ejercicio 3: colección vacía {#s3c2-ej-3}
<!-- quiz: web-w3c2-empty -->

### Ejercicio 4: límite del `for` {#s3c2-ej-4}
<!-- quiz: web-w3c2-for-boundary -->

### Ejercicio 5: contrato tipado {#s3c2-ej-5}
<!-- quiz: web-w3c2-typed-function -->

### Ejercicio 6: valor y referencia {#s3c2-ej-6}
<!-- quiz: web-w3c2-reference -->

### Ejercicio 7: captura de cierre {#s3c2-ej-7}
<!-- quiz: web-w3c2-closure -->

### Ejercicio 8: función flecha {#s3c2-ej-8}
<!-- quiz: web-w3c2-arrow -->

### Ejercicio 9: responsabilidad {#s3c2-ej-9}
<!-- quiz: web-w3c2-responsibility -->

## Respuestas razonadas {#s3c2-respuestas}

### Respuesta 1 {#s3c2-r-1}

[Volver al ejercicio](#s3c2-ej-1). El orden comprueba primero el rango alto y
luego el medio. `70` satisface exactamente `>= 70`, mientras `69` llega a la
rama inicial.

### Respuesta 2 {#s3c2-r-2}

[Volver al ejercicio](#s3c2-ej-2). `match` devuelve un valor, compara de forma
estricta y no tiene caída entre brazos. Esas propiedades no deben atribuirse sin
más a todo `switch`.

### Respuesta 3 {#s3c2-r-3}

[Volver al ejercicio](#s3c2-ej-3). Un `foreach` vacío ejecuta cero vueltas. Si
el acumulador empezó en `0`, conserva `0`; eso no inventa un elemento.

### Respuesta 4 {#s3c2-r-4}

[Volver al ejercicio](#s3c2-ej-4). Con tres elementos, los índices válidos son
`0`, `1` y `2`; la condición `i < 3` se detiene antes de `3`.

### Respuesta 5 {#s3c2-r-5}

[Volver al ejercicio](#s3c2-ej-5). Los tipos hacen visible que entra y sale un
entero, pero una regla adicional debe decidir si un negativo es válido.

### Respuesta 6 {#s3c2-r-6}

[Volver al ejercicio](#s3c2-ej-6). Un retorno puede entregar un nuevo valor sin
ocultar el cambio. Una referencia modifica la variable del llamador y debe estar
marcada en la firma y, en C#, también en la llamada.

### Respuesta 7 {#s3c2-r-7}

[Volver al ejercicio](#s3c2-ej-7). El cierre PHP importa `$descuento` con
`use`; el ejemplo lo captura por valor y calcula un total nuevo sin persistirlo.

### Respuesta 8 {#s3c2-r-8}

[Volver al ejercicio](#s3c2-ej-8). `fn` comunica bien un predicado de una sola
expresión. Una regla con varias ramas merece una forma más explícita.

### Respuesta 9 {#s3c2-r-9}

[Volver al ejercicio](#s3c2-ej-9). Separar decisión, cálculo y presentación
permite comprobar cada resultado sin confundirlo con almacenamiento o salida.
