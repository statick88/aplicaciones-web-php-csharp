# PHP Practice

PHP technology implementation of the shared Week 1 course exercises in this repository, not a production application. See the [general repository guide](../README.md). Apache serves `src/`; MariaDB and the invoice page are extra experiments, outside the tested Week 1 requirements. `src/home.php` is currently monolithic and is **not** MVC.

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
| `public/`, `src/`, `views/`, `config/`; `require`/`include` examples | Not yet verified |
| PHP variables and scalar types | Exercised |
| Constants (`const`, `define`), nullable values and interpolation examples | Not yet verified |
| Scope; prefer parameters to `global` | Existing scope exercise only; parameter recommendation remains unchecked |

The invoice POST experiment does not claim robust server-side validation and is not an official Week 1 deliverable.

## Local data and security boundary

Compose binds services only to loopback. A `.env` can override development passwords; it is intentionally ignored. Database data and local keys are for development practice, not production security.

## Project layout

```text
compose.yaml       # Apache/PHP and MariaDB
Dockerfile          # PHP 8.5 Apache image
src/                # educational examples
tests/variables.php # minimal exercised-topic check
```

## Course references and next weeks

The separate completed assignment (personal page and PHP calculator) is published at [aplicaciones-web-semana1](https://github.com/statick88/aplicaciones-web-semana1). This directory contains the PHP technology implementation of additional shared course practices, not a replacement for that delivery.

- [Week 1, Class 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334077_1?view=content&state=view)
- [Week 1, Class 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334079_1?view=content&state=view)

Planned work from the prepared course checklist; detailed Week 2 content was not rechecked in this verification:

- [ ] [Week 2, Class 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334088_1?view=content&state=view): simple types, conversions, strict typing, variable variables and the `Cliente` CRUD exercise.
- [ ] [Week 2, Class 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334090_1?view=content&state=view): forms, GET/POST, input validation and Post/Redirect/Get.
- [ ] Week 3 onward: await published official content before adding requirements or implementations.

Official PHP release reference: <https://www.php.net/releases/index.php?json&version=8.5>.
