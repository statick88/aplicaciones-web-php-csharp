# Matriz de trazabilidad — Aplicaciones Web (Semana 1 y Semana 2)

Relación `semana → objetivo oficial → capítulo del ebook → práctica PHP/C# → pruebas → entrega`.
Alcance: **solo Semana 1 y Semana 2** (decisión de alcance). Semana 3 en adelante vive en
el checklist local `.progress` (gitignored), nunca en este archivo.

Leyenda de estado:

- **Verificado**: ejecutado en este lote con evidencia de prueba (comando y resultado).
- **Pendiente**: plan declarado; fuentes oficiales sin confirmar o contenido sin ejecutar.
- **Complementario**: contenido extra del repositorio, fuera de los objetivos oficiales verificados.

Fuentes oficiales de Semana 1: EVA `_334077_1` (Clase 1), `_334079_1` (Clase 2),
`_334154_1` (evaluación). Enlaces en `README.md` y `php/README.md`.

## Semana 1

| # | Objetivo oficial | Capítulo del ebook | Práctica PHP | Práctica C# | Pruebas | Entrega | Estado |
|---|---|---|---|---|---|---|---|
| 1.1 | Páginas estáticas y dinámicas | `chapters/01-web-foundations.qmd`, `chapters/03-week1-practice-review.qmd` | `php/public/index.php` | — (la Clase 1 es PHP) | Smoke HTTP `/` → 200 | `aplicaciones-web-semana1` (sitio personal) | Verificado |
| 1.2 | Petición–respuesta HTTP | `subjects/aplicaciones-web/consulta-http.qmd`, `subjects/aplicaciones-web/laboratorio-http-php.qmd`, `chapters/01-web-foundations.qmd` | Smoke contra Apache (métodos/estados observados) | — | Smoke HTTP: `/config` → 404, traversal → 400 | — | Verificado |
| 1.3 | Historia de PHP 5–8.5 | `chapters/01-web-foundations.qmd` (sección "Una historia breve de PHP") | — (contenido de lectura) | — | Sin prueba ejecutable (lectura) | — | Pendiente de verificación (fila `php/README.md` sin ejecutar) |
| 1.4 | Estructura de proyecto `public/`, `src/`, `views/`, `config/` con `require`/`include` | `chapters/01-web-foundations.qmd` (carpetas + include/require/once) | Entrada `php/public/variables.php` con `require` de `config/`, `src/`, `views/`; `config/config.php` | — | `php tests/structure.php` → 10 PASS (local y en imagen); smoke: `src/`, `views/`, `config/` → 404 | — | Verificado |
| 1.5 | MVC como introducción (no receta) | `chapters/01-web-foundations.qmd`, `chapters/03-week1-practice-review.qmd` | `php/public/home.php` es monolítico (etiquetado honestamente, no MVC) | `csharp/src/Controllers/`, `Views/` (MVC real) | — | — | Complementario (housekeeping honesto) |
| 1.6 | Diferencia .NET/ASP.NET y comparación PHP/C# | `chapters/01-web-foundations.qmd` (PHP y C#: comparación inicial), `chapters/04-development-environment.qmd` | — | `csharp/` stack completo | `dotnet build` (contenedor) → 0W/0E | — | Verificado |
| 1.7 | Variables, tipos escalares e inferencia | `chapters/02-variables-types-scope.qmd` | `php/src/variables.php` + `php/views/variables.php` | `HomeController.cs` demo `Home/Variables` | `php tests/variables.php` → 17 PASS; `python3 -m unittest` → 7 OK | — | Verificado |
| 1.8 | Constantes: `const`/`define` (PHP) y `const` (C#) | `chapters/02-variables-types-scope.qmd` | `php/config/config.php` (`const CURSO`, `define('ETIQUETA')`) | `public const string CursoConst` | Mismas pruebas de 1.7 (checks de constantes) | — | Verificado |
| 1.9 | Valores nulos e interpolación | `chapters/02-variables-types-scope.qmd` | `$docente = null`, `??`, `"Estudiante: $curso"` | `string? apellido`, `??`, `$"Curso: {estudiante}"` | Mismas pruebas de 1.7 (+ test dedicado de interpolación C#) | — | Verificado |
| 1.10 | Ámbito y paso de parámetros frente a `global` | `chapters/02-variables-types-scope.qmd` | `cursoDe(string $nombre)` (sin `global`) | `CursoDe(string nombre)` (estático, no lee estado compartido) | Mismas pruebas de 1.7 | — | Verificado |
| 1.11 | Entrega Semana 1 (sitio personal + calculadora PHP) | — (fuera del ebook) | Repositorio independiente `aplicaciones-web-semana1` | — | `php tests/run.php` → 12 tests, 0 failures | `https://github.com/statick88/aplicaciones-web-semana1` | Verificado (intacto en `main` ff3d1d7) |

**Complementario de Semana 1** (no es requisito oficial verificado):

| Contenido | Ubicación | Pruebas | Estado |
|---|---|---|---|
| Persistencia de facturas (PDO/EF Core, POST) | `php/public/home.php`, `csharp/` | Smoke de formulario (200); no hay prueba de guardado en este lote | Complementario: el POST **no** valida `ModelState.IsValid` y nunca se presenta como validación robusta |
| Consulta transversal HTTP/DevTools | `subjects/aplicaciones-web/consulta-http.qmd`, `laboratorio-http-php.qmd` | Lectura/render | Complementario (transversal, no semanal) |

## Semana 2

> **Las fuentes oficiales de Semana 2 NO se reconfirmaron en este lote** (T8, bloqueada:
> requiere EVA autenticada o contenido del docente). Los objetivos provienen de los enclaces
> del `README.md` declarados como plan; **no** son evidencia de cobertura. No se infiere
> contenido desde `lleroc/web`.

| # | Objetivo oficial (plan, sin confirmar) | Capítulo del ebook | Práctica PHP | Práctica C# | Pruebas | Entrega | Estado |
|---|---|---|---|---|---|---|---|
| 2.1 | Tipos simples `int`, `float`, `string`, `bool`; conversión implícita/explicita; declaraciones de tipo y modo estricto; variables de variables y alternativa con arreglos; clase `Cliente` CRUD | Sin capítulo dedicado (el `02` cubre la Semana 1) | — | — | — | — | **Pendiente**: fuentes oficiales sin confirmar (EVA `_334088_1`) |
| 2.2 | Formularios HTML; GET vs POST; recepción de datos entre archivos; validación y saneamiento; formulario autoprocesado y Post/Redirect/Get | Sin capítulo dedicado (las tablas HTTP/DevTools son complementarias) | — (el POST de facturas es complementario, no cubre validación/PRG) | — | — | — | **Pendiente**: fuentes oficiales sin confirmar (EVA `_334090_1`) |

## Pruebas ejecutadas en este lote (resumen de evidencia)

| Comando | Resultado |
|---|---|
| `php php/tests/structure.php` | PASS: 10 layout checks |
| `php php/tests/variables.php` | PASS: 17 checks (tipos, constantes, nulos, interpolación, ámbito) |
| `python3 -m unittest discover -s tests -p 'test_*.py'` (en `csharp/`) | OK: 7 tests |
| `docker compose run --rm --no-deps -T app dotnet build --configuration Release --warnaserror` | Build succeeded: 0 warnings, 0 errors |
| Smoke HTTP (contenedor efímero `127.0.0.1:18080`) | `/`=200, `/variables.php`=200, `/home.php`=200, `/config` y `/src` y `/views`=404, traversal=400, sin errores PHP |
| `php tests/run.php` (en `aplicaciones-web-semana1`) | 12 tests, 0 failures |
