# Semana 3 · Clase 1: constantes, operadores y datos {#semana3-clase1-constantes-operadores}

Esta unidad separa dos alcances que se complementan, pero no son equivalentes.
El alcance principal compara **constantes y operadores en PHP y C#**. Después,
un complemento distinto explica cómo PHP puede comunicarse con MySQL. Esta
separación evita presentar PDO o MySQLi como si fueran características paralelas
de C# o como si una consulta demostrara por sí sola una aplicación completa.

## Objetivos y prerrequisitos {#s3c1-objetivos}

Al terminar podrás:

- distinguir valores constantes de datos que cambian durante una ejecución;
- predecir expresiones usando precedencia, paréntesis e igualdad apropiada;
- explicar la diferencia entre `const` y `readonly` en C# sin prometer
  inmutabilidad profunda;
- calcular un precio ficticio con enteros que representan centavos;
- reconocer, de forma conceptual, qué resuelven PDO y MySQLi;
- separar parámetros de valores, identificadores SQL, manejo de errores y
  escape de salida HTML.

Conviene haber estudiado tipos, conversiones e igualdad. Puedes repasar
[tipos y conversiones](subjects/aplicaciones-web/semana-02/01-tipos-cliente.html#semana2-clase1-tipos-cliente).
Las reglas de lenguaje se contrastan con el [manual oficial de constantes de
PHP](https://www.php.net/manual/en/language.constants.php), la
[referencia oficial de operadores de PHP](https://www.php.net/manual/en/language.operators.php)
y la [documentación oficial de constantes de C#](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/const)
[@php-manual; @microsoft-csharp].

## Alcance principal: constantes y operadores en PHP y C# {#s3c1-lenguajes}

Una constante comunica que un nombre no se reasignará durante el alcance que
permite el lenguaje. Esa decisión mejora la lectura: quien revisa el cálculo
puede distinguir una regla fija de un dato que varía, como la cantidad comprada.
No convierte automáticamente un objeto completo en inmutable ni valida que el
valor sea correcto para el negocio.

### Constantes en PHP: `const` y `define` {#s3c1-php-constantes}

PHP ofrece dos formas comunes de declarar constantes. `const` usa sintaxis del
lenguaje y resulta clara cuando el nombre y el valor se conocen al escribir el
programa. `define` crea una constante mediante una llamada y permite construir
el nombre en tiempo de ejecución, aunque hacerlo sin necesidad puede dificultar
la lectura.

```text
const MONEDA = 'USD';
define('DESCUENTO_CENTAVOS', 250);
```

Las constantes no llevan `$`. Intentar asignar otro valor a `MONEDA` no es la
forma de cambiar una política: la regla debe modificarse donde se define y sus
usos deben revisarse. Para conocer detalles y restricciones por versión,
consulta [`const`](https://www.php.net/manual/en/language.constants.syntax.php)
y [`define`](https://www.php.net/manual/en/function.define.php).

Una constante también puede contener un arreglo. Eso no significa que todo
valor relacionado quede congelado: las variables que usan el arreglo todavía
pueden cambiar. La pregunta crítica es qué nombre representa una regla y qué
nombre representa el estado de una operación concreta.

### Constantes en C#: `const` y `readonly` no significan lo mismo {#s3c1-csharp-constantes}

En C#, `const` se usa para valores conocidos en compilación, como un entero, un
booleano o una cadena literal. Un campo `readonly` puede recibir su valor al
declararse o dentro del constructor. Por eso sirve para datos que se fijan al
crear cada instancia, aunque no sean constantes de compilación.

```text
const string Moneda = "USD";
public readonly int DescuentoCentavos;
```

`readonly` impide reasignar el campo fuera de los lugares permitidos; **no
produce inmutabilidad profunda**. Si el campo guarda una referencia a una lista,
la referencia puede quedar fija y el contenido de la lista todavía podría
cambiar. La documentación oficial distingue
[`const`](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/const)
de [`readonly`](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/readonly).

| Intención | PHP | C# | Pregunta de revisión |
|---|---|---|---|
| regla literal conocida al escribir | `const` | `const` | ¿el valor puede expresarse en compilación? |
| nombre creado mediante llamada | `define(...)` | no es el equivalente de `readonly` | ¿el nombre dinámico aporta claridad real? |
| valor fijado al construir un objeto | propiedad controlada por la clase | campo `readonly` | ¿queda fija la referencia o también su contenido? |
| dato de una compra | variable | variable | ¿debe cambiar entre operaciones? |

La tabla compara intenciones de aprendizaje, no declara una paridad oficial
entre todas las características de ambos lenguajes.

## Operadores: primero la intención, después la abreviatura {#s3c1-operadores}

Los operadores aritméticos (`+`, `-`, `*`, `/`, `%`) construyen cálculos. Los
relacionales (`<`, `<=`, `>`, `>=`) comparan valores. Los lógicos combinan
condiciones. Una expresión corta no siempre es una expresión clara: los
paréntesis hacen visible la regla que se quiere aplicar.

```text
$total = $precioCentavos * $cantidad - $descuentoCentavos;
$aplica = ($cantidad >= 2) && ($total > 20000);
```

La multiplicación ocurre antes que la resta, pero los paréntesis siguen siendo
útiles cuando agrupan una decisión. No memorices una expresión ambigua: divide
el cálculo en nombres como `subtotal`, `descuento` y `total`, y comprueba cada
paso. La precedencia oficial está documentada para
[PHP](https://www.php.net/manual/en/language.operators.precedence.php) y
[C#](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/).

### Igualdad flexible, igualdad estricta y comparación tipada {#s3c1-igualdad}

PHP dispone de `==` y `===`. La comparación flexible puede convertir tipos;
la estricta exige el mismo tipo y el mismo valor. Si los datos ya fueron
normalizados a un tipo esperado, `===` suele comunicar mejor la intención.

```text
'25' == 25   // true en PHP
'25' === 25  // false en PHP
```

C# no ofrece esos dos operadores con la misma semántica de conversión. Para
comparar un texto y un entero primero se decide si corresponde analizar el
texto, rechazarlo o comparar representaciones textuales. Convertir sin una regla
de entrada solo desplaza el problema.

Los operadores `&&` y `||` usan cortocircuito: la segunda condición puede no
evaluarse si la primera ya determina el resultado. Eso ayuda a proteger una
operación posterior, pero no justifica esconder efectos secundarios dentro de
una condición difícil de seguir.

## Ejemplo PHP ejecutable y autocontenido {#s3c1-ejemplo-php}

El siguiente programa usa valores ficticios. Los enteros representan centavos
para que la representación del dinero sea explícita; no expresa impuestos,
IVA ni una regla legal de precios.

```php
<?php
declare(strict_types=1);

const MONEDA = 'USD';
define('DESCUENTO_CENTAVOS', 250);

$precioCentavos = 12500;
$cantidad = 2;
$subtotalCentavos = $precioCentavos * $cantidad;
$totalCentavos = $subtotalCentavos - DESCUENTO_CENTAVOS;
$esElegible = ($cantidad >= 2) && ($totalCentavos > 20000);

echo "Moneda: " . MONEDA . PHP_EOL;
echo "Subtotal: {$subtotalCentavos}" . PHP_EOL;
echo "Descuento: " . DESCUENTO_CENTAVOS . PHP_EOL;
echo "Total: {$totalCentavos}" . PHP_EOL;
echo "Elegible: " . ($esElegible ? 'si' : 'no') . PHP_EOL;
```

**Salida esperada literal:**

```text
Moneda: USD
Subtotal: 25000
Descuento: 250
Total: 24750
Elegible: si
```

La ejecución comprueba solamente este cálculo puro. No verifica formularios,
persistencia, seguridad, conexión a MySQL ni cumplimiento de reglas externas.

## Ejemplo C# ejecutable y autocontenido {#s3c1-ejemplo-csharp}

Este ejemplo expresa el mismo cálculo observable, pero conserva la diferencia
propia de C#: `const` representa literales de compilación y el descuento se fija
en un campo `readonly` al construir la política.

```csharp
const string Moneda = "USD";
const int PrecioCentavos = 12500;

var politica = new PoliticaPrecio(250);
var cantidad = 2;
var subtotalCentavos = PrecioCentavos * cantidad;
var totalCentavos = subtotalCentavos - politica.DescuentoCentavos;
var esElegible = cantidad >= 2 && totalCentavos > 20000;

Console.WriteLine($"Moneda: {Moneda}");
Console.WriteLine($"Subtotal: {subtotalCentavos}");
Console.WriteLine($"Descuento: {politica.DescuentoCentavos}");
Console.WriteLine($"Total: {totalCentavos}");
Console.WriteLine($"Elegible: {(esElegible ? "si" : "no")}");

sealed class PoliticaPrecio
{
    public readonly int DescuentoCentavos;

    public PoliticaPrecio(int descuentoCentavos)
    {
        DescuentoCentavos = descuentoCentavos;
    }
}
```

**Salida esperada literal:**

```text
Moneda: USD
Subtotal: 25000
Descuento: 250
Total: 24750
Elegible: si
```

Que ambos programas produzcan la misma salida no vuelve idénticas sus reglas de
lenguaje. La evidencia verificada se limita al resultado literal de estos dos
ejemplos puros.

## Complemento distinto: PHP y MySQL {#s3c1-complemento-mysql}

Esta sección no amplía la comparación PHP–C#. Resume otro alcance de la clase:
el acceso conceptual desde PHP a MySQL. No incluye código ejecutable de base de
datos, credenciales, esquema, contenedores ni operaciones CRUD.

PDO ofrece una interfaz para varios controladores de bases de datos; MySQLi se
orienta a MySQL. Elegir entre ellos depende del contexto del proyecto. Ninguno
hace segura o correcta una consulta por el solo hecho de abrir una conexión.
Consulta las referencias oficiales de
[PDO](https://www.php.net/manual/en/book.pdo.php),
[MySQLi](https://www.php.net/manual/en/book.mysqli.php) y
[MySQL](https://dev.mysql.com/doc/refman/8.4/en/).

### Los parámetros representan valores, no identificadores {#s3c1-valores-identificadores}

Una consulta preparada separa la plantilla SQL de los **valores** proporcionados
después. Es apropiada para datos como un correo, un id o una fecha. Un parámetro
no representa normalmente un nombre de tabla, una columna ni una palabra clave
como `ASC`.

```text
SELECT nombre FROM clientes WHERE correo = :correo
```

En ese texto, `:correo` ocupa la posición de un valor. Si una interfaz permite
ordenar por `nombre` o `fecha_registro`, el identificador se elige mediante una
lista cerrada mantenida por la aplicación; no se copia una cadena arbitraria en
la consulta. Preparar valores y permitir identificadores son problemas
diferentes. La documentación oficial explica los
[marcadores de PDO](https://www.php.net/manual/en/pdo.prepare.php) y las
[sentencias preparadas de MySQLi](https://www.php.net/manual/en/mysqli.quickstart.prepared-statements.php).

### Errores: informar sin exponer detalles internos {#s3c1-errores}

Una operación de datos puede fallar por conexión, permisos, sintaxis, tipos o
restricciones. El programa necesita distinguir el camino exitoso del fallido,
registrar el detalle en un canal apropiado para desarrollo u operación y mostrar
al usuario un mensaje comprensible. Imprimir una excepción completa, la cadena
de conexión o una consulta con datos reales puede revelar información interna.

Esta unidad solo razona sobre esa responsabilidad. No configura registros, no
lee variables privadas y no prueba una política de producción. Para PDO, el
[modo de errores](https://www.php.net/manual/en/pdo.error-handling.php) define
cómo se notifican los fallos; la aplicación todavía debe decidir qué registra y
qué comunica.

### Guardar no es mostrar: escape HTML al final {#s3c1-escape-html}

Una consulta preparada protege la estructura SQL al enlazar valores; no prepara
un texto para insertarlo en HTML. Cuando un nombre recuperado se muestra en una
página PHP, se escapa para el contexto de salida, por ejemplo con
`htmlspecialchars`. Escapar al mostrar no valida el dato, no modifica la base y
no reemplaza una consulta preparada.

```text
htmlspecialchars($nombre, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8')
```

La referencia oficial de
[`htmlspecialchars`](https://www.php.net/manual/en/function.htmlspecialchars.php)
describe la conversión. Otros contextos —una URL, JavaScript o un encabezado—
requieren decisiones propias; no existe un escape universal para toda salida.

## Errores frecuentes y preguntas críticas {#s3c1-pitfalls}

| Afirmación | Revisión crítica |
|---|---|
| “Es `const`, así que el dato es correcto.” | La no reasignación no valida el valor elegido. |
| “`readonly` vuelve inmutable todo el objeto.” | Solo restringe la asignación del campo; una referencia puede apuntar a contenido mutable. |
| “La precedencia hará lo que quise.” | El lenguaje aplica sus reglas, no una intención no escrita; usa nombres y paréntesis. |
| “`==` y `===` son intercambiables.” | En PHP pueden producir resultados distintos por tipo y conversión. |
| “Un marcador sirve para el nombre de una columna.” | Los parámetros enlazan valores; los identificadores requieren una selección controlada. |
| “La consulta preparada ya protege el HTML.” | SQL y HTML son contextos distintos; el escape se aplica al renderizar. |
| “Mostrar la excepción ayuda siempre.” | Puede revelar detalles internos; separa diagnóstico de mensaje al usuario. |
| “La salida esperada demuestra persistencia.” | Los ejemplos ejecutados no usan base de datos ni conservan estado. |

## Síntesis y siguiente paso {#s3c1-sintesis}

1. Usa constantes para comunicar reglas que no se reasignan, sin confundir esa
   propiedad con validación o inmutabilidad profunda.
2. Haz visible la intención de una expresión mediante variables intermedias y
   paréntesis; comprueba tipos antes de elegir la igualdad.
3. Trata `const`/`define` de PHP y `const`/`readonly` de C# según las reglas de
   cada lenguaje, no como equivalencias automáticas.
4. Mantén separado el complemento PHP/MySQL: parámetros para valores,
   identificadores seleccionados de forma controlada, errores gestionados y
   salida HTML escapada en su contexto.
5. Distingue conocimiento explicado, ejecución verificada de ejemplos puros y
   persistencia SQL no ejecutada en esta unidad.

Como continuación, repasa
[formularios, GET y POST](subjects/aplicaciones-web/semana-02/02-formularios-get-post.html#semana2-clase2-formularios-get-post)
para reconocer cómo llegan valores externos antes de convertirlos, validarlos o
mostrarlos.

## Autoevaluación de opción múltiple {#s3c1-autoevaluacion}

Elige una alternativa en cada caso. La retroalimentación está emparejada con la
misma posición de la opción seleccionada; no se requieren respuestas abiertas.

### 1. Regla fija y dato variable {#s3c1-ej-1}
<!-- quiz: web-w3c1-const-variable -->

### 2. Alcance de `readonly` {#s3c1-ej-2}
<!-- quiz: web-w3c1-readonly-depth -->

### 3. Precedencia y claridad {#s3c1-ej-3}
<!-- quiz: web-w3c1-precedence -->

### 4. Igualdad en PHP {#s3c1-ej-4}
<!-- quiz: web-w3c1-strict-equality -->

### 5. Cálculo ficticio {#s3c1-ej-5}
<!-- quiz: web-w3c1-pricing -->

### 6. Dos alcances de la unidad {#s3c1-ej-6}
<!-- quiz: web-w3c1-scope-separation -->

### 7. Valores e identificadores SQL {#s3c1-ej-7}
<!-- quiz: web-w3c1-prepared-values -->

### 8. Manejo de errores {#s3c1-ej-8}
<!-- quiz: web-w3c1-errors -->

### 9. Salida HTML {#s3c1-ej-9}
<!-- quiz: web-w3c1-html-escape -->
