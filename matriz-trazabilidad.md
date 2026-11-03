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
| 1.7 | Variables, tipos escalares e inferencia | `chapters/02-variables-types-scope.qmd` | `php/src/variables.php` + `php/views/variables.php` | `HomeController.cs` demo `Home/Variables` | `php tests/variables.php` → 17 PASS; `python3 -m unittest` → 8 OK | — | Verificado |
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

Fuentes aportadas por el usuario: `semana2.md` (Clase 1) y
`semana2-clase2.md` (Clase 2). Verificación local con PHP 8.5.12;
no se afirma acceso renovado a EVA ni publicación.

| # | Objetivo del material | Capítulo del ebook | Práctica PHP | Práctica C# | Pruebas | Entrega | Estado |
|---|---|---|---|---|---|---|---|
| 2.1 | Tipos simples y null; conversiones; comparaciones; tipos estrictos/unión; variables de variables y arreglos; Cliente CRUD | [Semana 2 · Clase 1](ebook/subjects/aplicaciones-web/semana-02/01-tipos-cliente.qmd) | `php/public/semana2-tipos.php`, `php/src/semana2-{tipos,cliente}.php` | `csharp/src/Controllers/Semana2Controller.cs`, `Models/Cliente*.cs`, `/Semana2/Tipos`: tipos estáticos, nullable, casts, `Dictionary` (no `$$`) y CRUD en memoria | PHP: `php php/tests/semana2-tipos.php`, `php php/tests/semana2-cliente.php`; C#: HTTP `test_semana2_http.py` → 8 OK | Local, sin publicar | PHP y C# verificados |
| 2.2 | Formularios; GET/POST; recepción entre archivos; validación/saneamiento; autoprocesado; PRG; registro/consulta | [Semana 2 · Clase 2](ebook/subjects/aplicaciones-web/semana-02/02-formularios-get-post.qmd) | `php/public/semana2.php`, `semana2-registro.php`, `php/src/semana2-formulario.php` | `/Semana2`: GET búsqueda, POST separado/autoprocesado, validación, antiforgery, sesión y 303 PRG | PHP: `python3 -m unittest discover -s php/tests -p 'test_semana2_http.py' -v` → 5 OK; C#: `SEMANA2_BASE_URL=http://127.0.0.1:18083 python3 -m unittest discover -s csharp/tests -p 'test_semana2_http.py' -v` → 8 OK | Local, sin publicar | PHP y C# verificados |

Las pruebas HTTP ejercitan ambos destinos POST, GET, 303/PRG, campos múltiples,
edad opcional y límites 16/99, nombre 80/81 caracteres, errores 422 sin nuevos registros,
arrays manipulados, salida escapada y token CSRF. El registro se conserva en sesión,
no en una base de datos. El CRUD de Clase 1 es en memoria.

## Evidencia adicional — Semana 2 C#

- Build Release con `--warnaserror`: 0 advertencias, 0 errores (imagen SDK local).
- `SEMANA2_BASE_URL=http://127.0.0.1:18083 python3 -m unittest discover -s csharp/tests -p 'test_*.py' -v`: 15 pruebas OK, incluyendo 8 HTTP.
- Navegador: registro, mensaje de éxito de una sola vez, recarga sin duplicación, búsqueda sin coincidencias y ejemplos de clase 1 comprobados.
- Verificación independiente: ambas clases y controles antiforgery/validación aprobados tras corregir claves de intereses manipuladas; sin bloqueantes pendientes.
- Las 15 pruebas anteriores usaron `PracticeOnly=true`. El build offline del verificador no tuvo caché NuGet suficiente; los builds normales del implementador sí pasaron.
- Revisión nativa: `review-44e36ad1f10d82fc` aprobada y reconocida, autoridad cerrada; observaciones informativas sin corrección obligatoria.

### Prueba adicional de facturas SQL Server — verificada

- SQL Server 2022 aislado, sin volúmenes compartidos ni puerto SQL publicado: migración inicial predeterminada comprobada.
- Fallo original reproducido: omitir `Mail` se aceptaba. El usuario autorizó corregirlo con «si».
- Corrección limitada: `Factura.Mail` tiene `Required` con «El correo es obligatorio.» y la vista muestra ese error. No se cambian formato de correo, otros campos, rutas ni estado HTTP de facturas.
- `python3 csharp/tests/check_factura_sql.py --base-url http://127.0.0.1:18084 --sql-container invoice-mail-proof-db` → PASS: omitido, vacío y espacios devuelven HTTP 200 sin tarjeta de éxito, conservan los otros campos y dejan todas las filas y `IDENT_CURRENT` intactos.
- Factura válida: HTTP 200 y coincidencia exacta de los seis campos almacenados; una fila y un valor de identidad nuevos. GET no altera filas ni contador.
- `SEMANA2_BASE_URL=http://127.0.0.1:18084 python3 -m unittest discover -s csharp/tests -p 'test_*.py' -v` → 15 pruebas OK, con filas completas y contador de facturas idénticos antes/después.
- Verificación independiente y spot-check del padre: aprobados. Navegador: error exacto visible aun omitiendo el `required` HTML, campos retenidos y sin tarjeta de éxito.
- Build Release con `--warnaserror`: 0 advertencias y 0 errores; sin migración nueva ni dependencias.
- Incidentes del probe resueltos: opciones incompatibles de `sqlcmd` y salida JSON truncada; el helper final usa `-y 0` sin `-h`/`-W`.
- Contenedores y red de prueba eliminados después de verificar; no se usaron datos existentes. El experimento sigue siendo complementario, no una validación integral de facturas.
- La aprobación nativa anterior cubre el snapshot de Semana 2 previo a este arreglo, no la corrección de `Mail`. Para esta corrección se completó verificación independiente; la evaluación nativa no pudo clasificar el nuevo candidato por requerir selección explícita de archivos no rastreados.

## Evidencia histórica — Semana 1

| Comando | Resultado |
|---|---|
| `php php/tests/structure.php` | PASS: 10 layout checks |
| `php php/tests/variables.php` | PASS: 17 checks (tipos, constantes, nulos, interpolación, ámbito) |
| `python3 -m unittest discover -s tests -p 'test_*.py'` (en `csharp/`) | OK: 7 tests |
| `docker compose run --rm --no-deps -T app dotnet build --configuration Release --warnaserror` | Build succeeded: 0 warnings, 0 errors |
| Smoke HTTP (contenedor efímero `127.0.0.1:18080`) | `/`=200, `/variables.php`=200, `/home.php`=200, `/config` y `/src` y `/views`=404, traversal=400, sin errores PHP |
| `php tests/run.php` (en `aplicaciones-web-semana1`) | 12 tests, 0 failures |
