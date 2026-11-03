# PHP Practice

PHP technology implementation of the Week 1 and Week 2 course exercises in this repository, not a production application. See the [general repository guide](../README.md). Apache serves `public/` (the only folder exposed to the browser); MariaDB and the invoice page are extra experiments, outside the tested Week 1 requirements. `public/home.php` is currently monolithic and is **not** MVC.

## Quick start

From this repository directory:

```bash
docker compose up -d --build
```

Open <http://127.0.0.1:8080>. Stop the stack when alternating with the C# practice, preserving local volumes:

```bash
docker compose stop
```

## Minimal verification

From this repository directory, run the existing variables check with a local PHP 8.5 runtime:

```bash
php tests/variables.php
```

Or run the same check in the application image without starting dependent services:

```bash
docker compose run --rm --no-deps -T -v "$PWD:/practice:ro" app php /practice/tests/variables.php
```

## Week 1 learning status

| Official topic | Status |
| --- | --- |
| Static and dynamic pages | Exercised |
| HTTP request–response | Exercised |
| Docker PHP 8.5.12 environment | Exercised |
| PHP 5–8.5 history | Not yet verified |
| `public/`, `src/`, `views/`, `config/`; `require`/`include` examples | Exercised (entry `public/variables.php` requires `config/`, `src/` and `views/`; checked by `tests/structure.php`); documented (see below); `home.php` monolítico por diseño |
| PHP variables and scalar types | Exercised |
| Constants (`const`, `define`), nullable values and interpolation examples | Exercised (`src/constantes-nulos-interpolacion.php`, `tests/constantes-nulos-interpolacion.php`; `php/config/config.php` declares `const`/`define`; null, `??` and interpolation in `src/variables.php`) |
| Scope; prefer parameters to `global` | Exercised (`cursoDe(string $nombre)` receives a parameter; checked by `tests/variables.php`)

The invoice POST experiment does not claim robust server-side validation and is not an official Week 1 deliverable.

## Local data and security boundary

Compose binds services only to loopback. A `.env` can override development passwords; it is intentionally ignored. Database data and local keys are for development practice, not production security.

## Recommended project layout and include patterns

The recommended separation is `public/`, `src/`, `views/`, `config/`. This repository keeps examples under `src/` and tests under `tests/`; `src/home.php` remains **monolithic by design** (invoice experiment, not reference MVC).

- `require` vs `include`: `require` raises a fatal error if the file is missing; `include` only a warning. Use `require` for essential files.
- `require_once`/`include_once`: ensure the file is included only once, avoiding duplicate class/function declarations.

## Project layout

```text
compose.yaml        # Apache/PHP and MariaDB (project mounted at /var/www/html)
Dockerfile          # PHP 8.5 Apache image; DocumentRoot = public/
public/             # web-exposed entry points (only folder served by Apache)
src/                # logic of the educational examples
views/              # presentation templates
config/             # shared settings (const/define demo)
tests/structure.php # layout check (public/src/views/config + require)
tests/variables.php # exercised-topic check (types, constants, scope)
```

## Course references and next weeks

The separate completed assignment (personal page and PHP calculator) is published at [aplicaciones-web-semana1](https://github.com/statick88/aplicaciones-web-semana1). This directory contains the PHP technology implementation of additional shared course practices, not a replacement for that delivery.

- [Week 1, Class 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334077_1?view=content&state=view)
- [Week 1, Class 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334079_1?view=content&state=view)

## Week 2 — completed PHP practice

The supplied [Class 1](../semana2.md) and [Class 2](../semana2-clase2.md)
materials are the acceptance reference; no authenticated Blackboard session is needed.
C# and ebook Week 2 coverage are not claimed.

Run locally without a database or Docker, from `php/`:

```bash
php -S 127.0.0.1:8081 -t public
```

- <http://127.0.0.1:8081/semana2-tipos.php>: scalar types, null, casts, comparisons,
  strict typing (including an actual caught TypeError), union types, variable variables,
  associative arrays and a full in-memory Cliente CRUD demonstration.
- <http://127.0.0.1:8081/semana2.php>: GET search and POST registration.
  “Enviar a otro archivo” posts to `semana2-registro.php`;
  “Procesar en esta página” posts to the form itself. Both use the same validation
  and redirect with HTTP 303 after success. Refreshing the GET does not resubmit.

The name is required (1–80 Unicode characters after trimming), email must validate,
age may be empty or an integer from 16 through 99, career is SOF/SIS, and interests
are optional web/movil/datos values. Invalid fields/arrays produce HTTP 422 without
creating a record; values are retained for correction. Invalid CSRF tokens return 403;
unsupported methods return 405 with an Allow header. HTML output is escaped.

```bash
# From the repository root; PHP 8+ and Python 3, no third-party test dependencies.
for test in php/tests/*.php; do php "$test" || exit; done
python3 -m unittest discover -s php/tests -p 'test_semana2_http.py' -v
```

The HTTP suite creates a local PHP server, fresh cookie jars and a temporary session
directory inside `php/`, cleaning them up at completion. It tests both POST routes,
GET filtering, multiple interests, boundaries, malicious array shapes, output escaping,
CSRF and PRG. Class 1 tests check all CRUD operations and missing IDs.

### Educational limits

The Class 1 repository resets each request and follows the supplied example (registering
an existing ID replaces it). Class 2 only appends validated new records to the browser
session, not MariaDB; closing/expiring the session loses the records. Use fictional data.
POST does not encrypt data; real personal information requires HTTPS. Neither this
example nor the separate invoice experiment is a production application.

Week 3 onward remains pending published content.

Official PHP release reference: <https://www.php.net/releases/index.php?json&version=8.5>.
