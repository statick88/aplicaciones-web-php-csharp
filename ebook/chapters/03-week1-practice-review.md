# Práctica y repaso de la Semana 1 {#practica-semana1}

Esta práctica no añade una aplicación nueva: organiza lo que ya se estudió para
que puedas explicar una decisión antes de escribirla. El objetivo compartido es
leer una necesidad pequeña, reconocer sus entradas y resultados, y contrastar
cómo PHP y C# expresan la misma idea. PHP y C# no son tareas distintas aquí.

## Punto de partida verificable

Una entrega previa contiene un sitio HTML/CSS con una calculadora PHP. No la
copies ni la sustituyas: úsala como evidencia de práctica para observar las
cuatro operaciones. Los ejemplos locales de variables en PHP y C# son material
de comparación, no una afirmación de que ya existe una calculadora C# equivalente.

La consigna de la primera semana pide una página personal HTML/CSS y una
calculadora PHP integrada y publicada en control de versiones [@blackboard-task1].
Esa es una cita breve del requisito; no se reproduce el material docente.

## Un ciclo para resolver, no para adivinar

Aplica esta secuencia en cada caso. Es útil tanto en el editor como al leer un
programa ajeno.

1. **Planifica.** Escribe una frase de propósito: “calcular un resultado a
   partir de dos números y una operación”.
2. **Predice.** Antes de ejecutar, anota qué valor y qué tipo esperas ver.
3. **Separa.** Identifica entrada, procesamiento y salida.
4. **Ejecuta.** Corre solo el ejemplo o la entrega que estás revisando.
5. **Comprueba.** Contrasta el resultado observado con tu predicción.
6. **Explica.** Si no coincide, describe qué dato, operador o conversión puede
   justificar la diferencia antes de modificar código.

| Parte | Pregunta guía | Ejemplo de calculadora |
|---|---|---|
| Entrada | ¿Qué llega al programa? | dos cantidades y la operación elegida |
| Procesamiento | ¿Qué regla transforma los datos? | `+`, `-`, `*` o `/` |
| Salida | ¿Qué debe poder observarse? | resultado o aviso de caso no calculable |

Este esquema no reemplaza el razonamiento sobre HTTP: en una página dinámica,
una solicitud llega al servidor y este construye una respuesta. La página
estática no necesita calcular con datos de la solicitud; la dinámica sí puede
hacerlo [@blackboard-task1].

## Recorrido manual de la entrega existente

Abre la entrega personal y conserva una pequeña tabla de observación. No des
por hecho que “se ve bien” equivale a que cada operación fue revisada.

| Caso declarado | Predicción que anotas | Qué comprobar |
|---|---|---|
| `8 + 2` | `10` | que la suma no concatene texto |
| `8 - 2` | `6` | que se aplique la resta |
| `8 * 2` | `16` | que se aplique la multiplicación |
| `8 / 2` | `4` | que el cociente sea el esperado |
| divisor `0` | no hay división válida | que el caso sea distinguible y explicable |
| entrada no numérica | no hay cálculo aritmético fiable | qué muestra la entrega y por qué |

Los dos últimos casos son **observaciones de la práctica declarada**, no un
encargo para construir ahora un marco completo de validación. Si un resultado
difiere, registra entrada exacta, salida exacta y el paso de procesamiento que
investigarías. Esa nota vale más que ocultar el caso con una corrección rápida.

::: {.callout-tip}
## Consejo de comparación

Primero formula el algoritmo en lenguaje cotidiano. Después mira cómo cada
lenguaje declara sus variables y muestra el resultado. Así evitas confundir la
sintaxis con el problema que se desea resolver.
:::

## Misma intención, dos lecturas

En PHP una variable comienza con `$`; en C# su declaración comunica un tipo
explícito o permite inferirlo con `var` cuando el valor inicial lo hace claro.
Ambos lenguajes permiten componer texto con valores, pero sus reglas concretas
no son intercambiables. Consulta las referencias del lenguaje antes de inferir
una conversión [@php-manual; @microsoft-csharp].

```php
<?php
$nombre = "Ana";
$intentos = 2;
echo "$nombre tiene $intentos intentos.";
```

```csharp
string nombre = "Ana";
int intentos = 2;
Console.WriteLine($"{nombre} tiene {intentos} intentos.");
```

Predice primero: ambos fragmentos comunican que Ana tiene 2 intentos. Luego
identifica lo que cambia: `$` introduce la variable en PHP, mientras que en C#
el `$` pertenece a la cadena interpolada. El ejemplo ilustra variables y
salida; no prueba por sí solo una aplicación web completa.

## Alcance y constantes: una decisión pequeña

Una constante representa un valor que no debe reasignarse durante el programa.
Una variable representa un dato que puede cambiar según el problema. El alcance
indica dónde un nombre es visible. Cuando una función necesita un dato, pasarle
un parámetro hace visible esa dependencia en la llamada; no es necesario usar
un estado global para este ejercicio.

```php
<?php
const TASA = 0.19;
function precioConImpuesto(float $base): float {
    return $base * (1 + TASA);
}
```

```csharp
const decimal Tasa = 0.19m;
static decimal PrecioConImpuesto(decimal baseImponible)
{
    return baseImponible * (1 + Tasa);
}
```

No memorices estos fragmentos como plantilla universal. Señala en ambos la
entrada (`$base`/`baseImponible`), el procesamiento (multiplicar) y la salida
(el valor retornado). En PHP, `const` y `define` tienen reglas de uso distintas;
en C#, `const` declara una constante de compilación. Revísalas en la
referencia oficial antes de generalizar [@php-manual; @microsoft-csharp].

## Organización de prácticas web

MVC es el patrón de organización adoptado para las prácticas web: separa la
representación, el manejo de solicitudes y los datos del dominio para que sea
más fácil localizar responsabilidades [@aspnet-mvc]. No convierte
retroactivamente todo archivo en MVC. En particular, el `php/public/home.php`
actual de las facturas es monolítico; este ebook no lo refactoriza y las
facturas/persistencia no son requisitos oficiales comprobados de Semana 1.

## Autoevaluación de opción múltiple {#autoevaluacion-semana1}

Selecciona una opción para cada tema. Las referencias se conservan como ampliación
conceptual; la retroalimentación de cada alternativa guía qué ejemplo revisar.

1. <span id="p1"></span>[P1: historia y propósito](../answers.md#p1-respuesta)
   <!-- quiz: web-review-p1 -->
2. <span id="p2"></span>[P2: HTTP](../answers.md#p2-respuesta)
   <!-- quiz: web-review-p2 -->
3. <span id="p3"></span>[P3: tipos](../answers.md#p3-respuesta)
   <!-- quiz: web-review-p3 -->
4. <span id="p4"></span>[P4: interpolación](../answers.md#p4-respuesta)
   <!-- quiz: web-review-p4 -->
5. <span id="p5"></span>[P5: constantes](../answers.md#p5-respuesta)
   <!-- quiz: web-review-p5 -->
6. <span id="p6"></span>[P6: alcance](../answers.md#p6-respuesta)
   <!-- quiz: web-review-p6 -->
7. <span id="p7"></span>[P7: depuración](../answers.md#p7-respuesta)
   <!-- quiz: web-review-p7 -->
8. <span id="p8"></span>[P8: comprobación](../answers.md#p8-respuesta)
   <!-- quiz: web-review-p8 -->
9. <span id="p9"></span>[P9: MVC](../answers.md#p9-respuesta)
   <!-- quiz: web-review-p9 -->
10. <span id="p10"></span>[P10: transferencia](../answers.md#p10-respuesta)
    <!-- quiz: web-review-p10 -->

La selección correcta orienta el siguiente repaso; el progreso distingue una respuesta
registrada de un acierto y no sustituye observar las prácticas locales.

## Siguiente paso

Lee las respuestas razonadas en [Respuestas de autoevaluación](../answers.md)
y, si deseas ejecutar los ejemplos sin cambiar el objetivo de aprendizaje,
continúa con [Entorno de desarrollo](04-development-environment.md).
