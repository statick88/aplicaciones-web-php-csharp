# C# / ASP.NET Core MVC Practice

C# / ASP.NET Core technology implementation of the Week 1 and Week 2 course exercises in this repository, using MVC, EF Core, SQL Server, and Docker Compose. See the [general repository guide](../README.md). It is not a production application. Invoice persistence is an extra experiment rather than an official Week 1 deliverable, and its POST flow is not claimed as robust server-side validation.

## Quick start

From this repository directory:

```bash
docker compose up -d --build
```

Open <http://127.0.0.1:8080>. To alternate with PHP without deleting volumes:

```bash
docker compose stop
```

## Minimal verification

The full test suite includes runtime HTTP proof and therefore requires an explicitly started server URL; it fails (rather than silently skipping) if `SEMANA2_BASE_URL` is absent:

```bash
SEMANA2_BASE_URL=http://127.0.0.1:18083 python3 -m unittest discover -s tests -p 'test_*.py' -v
```

The test resolves `compose.yaml` from its own repository, so a standalone clone can use any directory name. After an initial normal restore has populated packages, the warning-as-error build command is:

```bash
docker compose run --rm --no-deps -T app dotnet build --configuration Release --warnaserror --nologo
```

## Week 2 practice (ASP.NET Core MVC)

Week 2 is now implemented separately from the invoice experiment:

- **Class 1:** `GET /Semana2/Tipos` compares C#'s static scalar types, nullable references and explicit parsing/casts with PHP. C# has no PHP `$$` variables; the controlled alternative shown is `Dictionary<string, string>`. Its in-memory `ClienteRepositorioMemoria` demonstrates register, consult, list, update and delete, including missing IDs.
- **Class 2:** `GET /Semana2` is a no-mutation search (`?q=`); `POST /Semana2/Registrar` is the separate receiver and `POST /Semana2` is the self-processing receiver. Both require antiforgery validation, accept name (required, max. 80), valid email, optional age 16–99, `SOF`/`SIS`, and zero or more `web`/`movil`/`datos` interests. Invalid POSTs return 422 with values and errors retained; valid posts store only validated data in that browser's session and redirect with 303 to `/Semana2`; a one-time TempData flash confirms success (PRG).

Razor HTML-encodes rendered values by default; server validation still treats every HTTP field as untrusted. POST only keeps data out of the URL: it does **not** encrypt it, so real personal data requires HTTPS.

The normal compose path still migrates the invoice database. For the database-independent Week 2 practice only, set `PracticeOnly=true`; it only skips that existing startup `Migrate()` call. The compose connection string remains available so MVC can resolve `HomeController` without contacting a database. After building the image, run this exact isolated server command from `csharp/`:

```bash
docker compose run --rm --no-deps -e PracticeOnly=true -p 127.0.0.1:18083:8080 app dotnet run --no-launch-profile
```

This foreground command uses the compose bind mount and its `/app/bin` and `/app/obj` caches. Then run runtime checks against it explicitly:

```bash
SEMANA2_BASE_URL=http://127.0.0.1:18083 python3 -m unittest discover -s tests -p 'test_semana2_http.py' -v
```

The test deliberately errors if `SEMANA2_BASE_URL` is unset; no source-string check substitutes for runtime HTTP evidence.

Verified: Release build with 0 warnings/errors; 15 tests (8 HTTP plus 7 existing configuration/Week 1 checks), browser registration/search/refresh, and independent validation of both classes. Malformed indexed/dotted interest keys are rejected without saving. The displayed count is the total stored in the session; a filter with no matches shows an explicit message. The original 15-test verification used the isolated no-database mode.

### Additional SQL Server verification — Mail boundary

The invoice experiment requires `Mail` server-side. An omitted, empty, or whitespace-only `Mail` returns the existing HTTP 200 form response with `El correo es obligatorio.`, retains the other submitted fields, renders no success card, and creates no row or identity value. This intentionally does not validate the email format or harden unrelated invoice fields.

Against an explicitly started isolated SQL Server-backed app, run the focused proof from the repository root:

```bash
python3 csharp/tests/check_factura_sql.py --base-url http://127.0.0.1:18084 --sql-container invoice-mail-proof-db
```

It snapshots all invoice rows and `IDENT_CURRENT` before each rejected request, verifies the existing successful HTTP 200 route preserves all six fields exactly in SQL, and confirms a subsequent GET does not mutate invoices. It uses unique fictional invoice numbers so it can run against a nonempty isolated database.

Verified against SQL Server 2022 with default migrations enabled: the focused proof passes all five cases, and the 15-test suite passes with complete invoice rows and `IDENT_CURRENT` unchanged before/after Week 2 registrations. Independent verification and a browser check confirmed the exact required message and retained fields. The initial missing-Mail failure and a truncated JSON snapshot in the proof helper were corrected; no schema migration or new dependencies were needed. The disposable SQL containers/network were removed after verification; this command requires creating a fresh isolated server before rerunning.

The native review of the earlier Week 2 snapshot was approved and acknowledged (`review-44e36ad1f10d82fc`); its informational findings did not open a correction. That acknowledgement predates the Mail fix and is not claimed to cover it. The Mail fix has separate independent HTTP/SQL verification; the native assessment could not classify the new working-tree candidate because it requires an explicit untracked selection. This is not a claim that all invoice validation is robust.

## Week 1 learning status

| Official topic | Status |
| --- | --- |
| .NET and ASP.NET differences | Exercised |
| PHP/C# variables and constants | Variables/types exercised; C# `const` in the demo (`HomeController.Constantes`); PHP `const`/`define` in `php/config/config.php` |
| Explicit types and type inference | Exercised |
| Nullable values and interpolation examples | Exercised (C# via `HomeController.Constantes`; nullable, `??` and string interpolation in `CursoDe`) |
| Scope; prefer parameters to `global` | Exercised (`CursoDe(string nombre)` receives a parameter)

## Local data and security boundary

The compose services bind to loopback. ASP.NET Core Data Protection keys persist in a local Docker volume and are **not encrypted at rest**; access relies on local Docker/host volume permissions. This configuration is for educational use only, not production key management. `.env`, keys, logs, and build/test caches are ignored.

## Project layout

```text
compose.yaml                 # app and SQL Server services
Dockerfile                   # .NET SDK 10 image
src/                          # MVC application
tests/test_runtime_config.py  # compose/runtime configuration checks
```

## Course references and next weeks

The image pins .NET SDK **10.0.403** (C# **14**) and EF Core **10.0.14**. The [completed assignment](https://github.com/statick88/aplicaciones-web-semana1) (personal page and PHP calculator) remains separate; this directory is the C# technology implementation of the shared course practices.

- [Week 1, Class 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334077_1?view=content&state=view)
- [Week 1, Class 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334079_1?view=content&state=view)

Course checkpoints (Week 2 verified against the supplied root Markdown materials):

- [x] [Week 2, Class 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334088_1?view=content&state=view): C# comparison of types, casts, nullable values, Dictionary and Cliente CRUD in memory.
- [x] [Week 2, Class 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334090_1?view=content&state=view): independent MVC GET/POST practice with validation, antiforgery, session and PRG; it does not certify or alter invoices.
- [ ] Week 3 onward: await official content. No later-week behavior is implemented by this documentation update.

Official .NET release reference: <https://builds.dotnet.microsoft.com/dotnet/release-metadata/releases-index.json>.
