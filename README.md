# aplicaciones-web-php-csharp

Repositorio público único de prácticas educativas de Aplicaciones Web, no de producción. Reúne los mismos ejercicios del curso en dos implementaciones por tecnología; el avance real se indica por separado en cada directorio, por lo que no se declara paridad completa.

| Implementación | Directorio | Guía específica |
| --- | --- | --- |
| PHP | [`php/`](php/) | [README de PHP](php/README.md) |
| C# / ASP.NET Core | [`csharp/`](csharp/) | [README de C#](csharp/README.md) |
| Cuaderno de estudio y práctica | [`ebook/`](ebook/) | [README del ebook](ebook/README.md) |

> La entrega pública ya existente es [aplicaciones-web-semana1](https://github.com/statick88/aplicaciones-web-semana1): sitio personal HTML/CSS y calculadora PHP. El commit `ff3d1d7` de esa entrega ya fue comprobado (lint de 3 archivos y 12 pruebas). Estas prácticas son ejercicios adicionales y no duplican esa entrega.

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

Las instrucciones y comprobaciones propias de cada práctica están en sus README independientes.

## Cuaderno de estudio y práctica

El cuaderno en [`ebook/`](ebook/) crece por asignatura y semana para preparar evaluaciones con teoría, ejemplos resueltos, práctica y autoevaluación. La edición local incluye Aplicaciones Web con PHP y C#, Semanas 1 a 3 (ambas clases, ejemplos, ejercicios y respuestas; en Semana 3 se distingue la comparación PHP/C# de la ampliación conceptual PHP/MySQL). Se publica como HTML estático en [GitHub Pages](https://statick88.github.io/aplicaciones-web-php-csharp/).

Para generar el sitio sin Quarto:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-docs.txt
.venv/bin/python tools/build_site.py --output _site
```

Cada actualización semanal añade o corrige el contenido editorial y registra todas las páginas en `course/catalog.json`; después ejecute la compilación y su comprobación `--check`. El flujo de publicación valida y publica únicamente `_site`. Las evaluaciones publicadas son preguntas de opción múltiple: sus selecciones y el avance formativo se conservan solamente en el almacenamiento local disponible del navegador, sin cuentas ni envío de datos. El PDF histórico permanece en la URL heredada por compatibilidad, pero no aparece en la interfaz actual ni se regenera; la guía técnica de migración explica su condición archivada. Pages no ejecuta PHP, .NET ni los ejemplos HTTP: estos se mantienen como material descargable y se ejecutan solo en sus entornos locales.

El resto del repositorio (prácticas PHP/C#, material de otras asignaturas y el archivo `ebook/index.typ`) se conserva fuera de la entrada activa del sitio.

## Semana 1 — avance verificado

Fuentes oficiales: [Clase 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334077_1?view=content&state=view) y [Clase 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334079_1?view=content&state=view).

### Clase 1 — PHP

- [x] Páginas estáticas y dinámicas: ejemplos PHP ejercitados.
- [x] Petición–respuesta HTTP: ejemplos ejercitados.
- [x] Entorno Docker con PHP 8.5 aceptado para la práctica.
- [ ] Historia de PHP 5 a 8.5: pendiente de practicar/verificar.
- [x] Estructura separada `public/`, `src/`, `views/`, `config/` y ejemplos `require`/`include`: ejercitados en `php/` (entrada `public/variables.php` con `require` de config, lógica y vista); documentada en `php/README.md`; `php/src/home.php` y `php/public/home.php` siguen monolíticos por diseño (experimento), no MVC.

### Clase 2 — .NET y variables

- [x] Diferencia .NET/ASP.NET y comparación PHP/C#: ejemplos ejercitados.
- [x] Declaración de variables, tipos e inferencia en PHP/C#: ejemplos ejercitados.
- [x] Ejemplos específicos de valores nulos e interpolación: verificados (PHP `src/constantes-nulos-interpolacion.php`, C# `HomeController.Constantes`) y ejercitados en ambos stacks (`php/tests/variables.php`, demo `Home/Variables`).
- [x] Constantes (`const`/`define` en PHP y `const` en C#): verificadas y ejercitadas en ambos stacks.
- [x] Scope y ejemplo recomendado de pasar parámetros en vez de `global`: ejercitado en ambos stacks (`cursoDe()` / `CursoDe()`).

Las facturas, la base de datos y los experimentos de persistencia son ejercicios adicionales. No son requisitos oficiales comprobados de Semana 1; el formulario POST no se presenta como validación robusta del servidor.

## Semana 2 — práctica PHP verificada

Fuentes de trabajo aportadas en la raíz: [Clase 1](semana2.md) y [Clase 2](semana2-clase2.md).
Estos materiales permiten completar las prácticas sin volver a acceder a Blackboard.
La contraparte C# de ambas clases está implementada y verificada (sección siguiente). El ebook incorpora [Clase 1](ebook/subjects/aplicaciones-web/semana-02/01-tipos-cliente.md) y [Clase 2](ebook/subjects/aplicaciones-web/semana-02/02-formularios-get-post.md), con práctica y respuestas; la actualización permanece local, sin publicar.

### Clase 1 — Tipos simples, variables de variables y Cliente

- [x] Tipos `int`, `float`, `string`, `bool` y `null`; comprobaciones de tipo.
- [x] Conversión implícita y explícita; comparaciones flexibles y estrictas.
- [x] Declaraciones de tipo, tipos unión y rechazo con `TypeError`.
- [x] Variables de variables, propiedades dinámicas de `stdClass` y alternativa con arreglos.
- [x] Clase `Cliente`: registrar, consultar, listar, actualizar correo y eliminar en memoria.

Demo: [`php/public/semana2-tipos.php`](php/public/semana2-tipos.php).
Pruebas: `php php/tests/semana2-tipos.php` y `php php/tests/semana2-cliente.php`.

### Clase 2 — Formularios GET y POST

- [x] Formulario con nombre, correo, edad opcional, carrera e intereses múltiples.
- [x] Consulta GET por nombre/correo sin modificar registros.
- [x] Recepción POST entre archivos y formulario autoprocesado (dos botones).
- [x] Validación del servidor: tipos de entrada, nombre de hasta 80 caracteres, correo,
  edad entre 16 y 99, listas permitidas de carreras e intereses.
- [x] Normalización con `trim`, escape HTML al mostrar y conservación de valores tras errores.
- [x] Registro/consulta de clientes en sesión y Post/Redirect/Get con estado 303.

Demo: [`php/public/semana2.php`](php/public/semana2.php).
Verificación HTTP aislada: `python3 -m unittest discover -s php/tests -p 'test_semana2_http.py' -v`
(5 pruebas, con casos de límites y entradas manipuladas).

Los registros duran solo la sesión de práctica; no hay persistencia MySQL.
POST no cifra: se requiere HTTPS para datos reales. La práctica incluye token CSRF.
La guía de ejecución y los límites están en [PHP](php/README.md#week-2--completed-php-practice).

## Semana 2 — contraparte C# / ASP.NET Core

La práctica C# implementa la misma Semana 2 sin modificar PHP ni el experimento de facturas: [`/Semana2/Tipos`](csharp/src/Controllers/Semana2Controller.cs) cubre tipos, conversiones, nullable, `Dictionary` como alternativa tipada a `$$` y CRUD `Cliente` en memoria; [`/Semana2`](csharp/src/Views/Semana2/Index.cshtml) cubre búsqueda GET, dos destinos POST, validación, antiforgery, sesión por navegador y PRG 303. Las reglas y rutas están documentadas en [csharp/README.md](csharp/README.md#week-2-practice-aspnet-core-mvc).

Para ejecución aislada sin SQL Server, el opt-in `PracticeOnly=true` solo omite la migración inicial existente; el comportamiento normal de compose no cambia. Desde `csharp/`, el comando documentado es:

```bash
docker compose run --rm --no-deps -e PracticeOnly=true -p 127.0.0.1:18083:8080 app dotnet run --no-launch-profile
```

Verificado con build Release (0 advertencias/errores), 15 pruebas (8 HTTP y 7 previas), recorrido en navegador y verificador independiente. Los registros solo duran la sesión; POST no cifra datos y HTTPS sigue siendo necesario para información real.

## Semana 3 en adelante

- [ ] Pendiente de publicación y verificación oficial; no se infiere ni inventa un temario.
