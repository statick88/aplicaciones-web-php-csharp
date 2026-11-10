# aplicaciones-web-php-csharp

Repositorio público único de prácticas educativas de Aplicaciones Web, no de producción. Reúne los mismos ejercicios del curso en dos implementaciones por tecnología; el avance real se indica por separado en cada directorio, por lo que no se declara paridad completa.

| Implementación | Directorio | Guía específica |
| --- | --- | --- |
| PHP | [`php/`](php/) | [README de PHP](php/README.md) |
| C# / ASP.NET Core | [`csharp/`](csharp/) | [README de C#](csharp/README.md) |
| Cuaderno de estudio y práctica | [`ebook/`](ebook/) | [README del ebook](ebook/README.md) |

> La entrega pública ya existente es [aplicaciones-web-semana1](https://github.com/statick88/aplicaciones-web-semana1): sitio personal HTML/CSS y calculadora PHP. El commit `ff3d1d7` de esa entrega ya fue comprobado (lint de 3 archivos y 12 pruebas). Estas prácticas son ejercicios adicionales y no duplican esa entrega.

## Equivalencias PHP ↔ C#

Las dos implementaciones recorren los mismos conceptos de la Semana 1, pero no son idénticas: cada directorio conserva su propio avance y **no se declara paridad completa**. Este mapa dice dónde vive cada equivalencia.

| Tema | PHP (`php/`) | C# / ASP.NET Core (`csharp/`) |
| --- | --- | --- |
| Entrada de la demo de variables | `php/public/variables.php` (Apache sirve `public/`) | `csharp/src/Controllers/HomeController.cs`, acción `Variables` (ruta `/Home/Variables`) |
| Lógica de la demo | `php/src/variables.php` | `HomeController.Variables()` en el mismo controlador |
| Presentación | `php/views/variables.php` (plantilla unida con `require`) | `csharp/src/Views/Home/Variables.cshtml` (vista Razor) |
| Constantes | `php/config/config.php` (`const` y `define`) | `public const string` en `HomeController` |
| Nulos e interpolación | `$docente = null`, `??`, `"Estudiante: $curso"` | `string? apellido = null`, `??`, `$"Curso: {estudiante}"` |
| Parámetros frente a `global` | `cursoDe(string $nombre)` | `CursoDe(string nombre)` |
| Pruebas | `php/tests/` (`structure.php`, `variables.php`) | `csharp/tests/` (cobertura estática) + `dotnet build` en contenedor |

Diferencias que sí importan: PHP ejecuta scripts con `require`/`include` sobre Apache, sin framework; C# usa MVC con controladores, vistas Razor y EF Core sobre SQL Server. Las pruebas tampoco son equivalentes: pruebas PHP ejecutadas directamente frente a cobertura estática C# más compilación `Release --warnaserror`. En persistencia, el POST de facturas no valida a nivel de servidor en ninguna de las dos implementaciones y no se presenta como ejemplo de validación robusta.

## Uso local

Ambos compose ocupan `127.0.0.1:8080`; PHP está detenido y C# está activo. Para alternar sin borrar volúmenes, detenga el stack activo con `stop` y luego inicie el otro desde la raíz:

```bash
# PHP
docker compose -f php/compose.yaml up -d --build
docker compose -f php/compose.yaml stop

# C# / ASP.NET Core
docker compose -f csharp/compose.yaml up -d --build
docker compose -f csharp/compose.yaml stop
```

Las instrucciones y comprobaciones propias de cada práctica están en sus README independientes. La comprobación transversal del mapa de equivalencias y de los enlaces locales corre desde la raíz:

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```

## Cuaderno de estudio y práctica

El ebook estático en [`ebook/`](ebook/) crece por asignatura y semana para preparar evaluaciones con teoría, ejemplos resueltos, práctica y autoevaluación. Actualmente incluye Aplicaciones Web con PHP y C#, Semana 1. Su publicación existente permanece en [GitHub Pages](https://statick88.github.io/aplicaciones-web-php-csharp/), con el [PDF descargable](https://statick88.github.io/aplicaciones-web-php-csharp/aplicaciones-web-php-csharp-semana1.pdf) que conserva el nombre técnico `aplicaciones-web-php-csharp-semana1.pdf` por compatibilidad con enlaces públicos heredados.

Esta tarea no publicó cambios. El [flujo de publicación](https://github.com/statick88/aplicaciones-web-php-csharp/actions/workflows/ebook.yml) verifica y genera ambos formatos antes de desplegar. Pages solo sirve el libro estático; los ejercicios PHP y C# se ejecutan en sus entornos de desarrollo.

## Semana 1 — avance verificado

Fuentes oficiales: [Clase 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334077_1?view=content&state=view) y [Clase 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334079_1?view=content&state=view).

### Clase 1 — PHP

- [x] Páginas estáticas y dinámicas: ejemplos PHP ejercitados.
- [x] Petición–respuesta HTTP: ejemplos ejercitados.
- [x] Entorno Docker con PHP 8.5 aceptado para la práctica.
- [ ] Historia de PHP 5 a 8.5: pendiente de practicar/verificar.
- [x] Estructura separada `public/`, `src/`, `views/`, `config/` y ejemplos `require`/`include`: ejercitados en `php/` (entrada `public/variables.php` con `require` de config, lógica y vista); `php/public/home.php` sigue siendo monolítico, no MVC.

### Clase 2 — .NET y variables

- [x] Diferencia .NET/ASP.NET y comparación PHP/C#: ejemplos ejercitados.
- [x] Declaración de variables, tipos e inferencia en PHP/C#: ejemplos ejercitados.
- [x] Ejemplos específicos de valores nulos e interpolación: ejercitados en PHP (`php/tests/variables.php`) y en C# (demo `Home/Variables`).
- [x] Constantes (`const`/`define` en PHP y `const` en C#): ejercitadas en ambos stacks.
- [x] Scope y ejemplo recomendado de pasar parámetros en vez de `global`: ejercitado en ambos stacks (`cursoDe()` / `CursoDe()`).

Las facturas, la base de datos y los experimentos de persistencia son ejercicios adicionales. No son requisitos oficiales comprobados de Semana 1; el formulario POST no se presenta como validación robusta del servidor.

## Semana 2 — plan pendiente

El contenido detallado de Semana 2 no se volvió a leer en esta sesión; se conservan estos encabezados y enlaces oficiales como plan, sin marcar implementación ni verificación.

### Clase 1 — Tipos de datos simples y variables de variables

[Contenido Semana 2 Clase 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334088_1?view=content&state=view)

- [ ] Tipos simples: `int`, `float`, `string`, `bool`.
- [ ] Conversión implícita y explícita de tipos.
- [ ] Declaraciones de tipo y modo estricto.
- [ ] Variables de variables y alternativa con arreglos.
- [ ] Clase `Cliente` y métodos CRUD.

Estos puntos se conservan como plan; los ejemplos aislados existentes no certifican completar Semana 2.

### Clase 2 — Envío de variables por formulario: métodos GET y POST

[Contenido Semana 2 Clase 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334090_1?view=content&state=view)

- [ ] Formularios HTML y campos de entrada.
- [ ] Comparación de métodos GET y POST.
- [ ] Recepción de datos entre archivos PHP.
- [ ] Validación de formato y saneamiento de entradas.
- [ ] Formulario autoprocesado y patrón Post/Redirect/Get.

## Semana 3 en adelante

- [ ] Pendiente de publicación y verificación oficial; no se infiere ni inventa un temario.
