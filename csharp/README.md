# C# / ASP.NET Core MVC Practice

C# / ASP.NET Core technology implementation of the shared Week 1 course exercises in this repository, using MVC, EF Core, SQL Server, and Docker Compose. See the [general repository guide](../README.md). It is not a production application. Invoice persistence is an extra experiment rather than an official Week 1 deliverable, and its POST flow is not claimed as robust server-side validation.

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

From this repository directory, run the configuration tests:

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```

The test resolves `compose.yaml` from its own repository, so a standalone clone can use any directory name.

After an initial normal restore has populated packages, the existing warning-as-error build command is:

```bash
docker compose run --rm --no-deps -T app dotnet build --configuration Release --warnaserror --nologo
```

## Week 1 learning status

| Official topic | Status |
| --- | --- |
| .NET and ASP.NET differences | Exercised |
| PHP/C# variables and constants | Variables/types exercised; PHP `const`/`define` and C# `const` remain unchecked |
| Explicit types and type inference | Exercised |
| Nullable values and interpolation examples | Not yet verified |
| Scope; prefer parameters to `global` | Parameter recommendation remains unchecked |

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

Planned course checkpoints, not verified implementations:

- [ ] [Week 2, Class 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334088_1?view=content&state=view): verify the published types/conversions and PHP object exercise before proposing a C# comparison.
- [ ] [Week 2, Class 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334090_1?view=content&state=view): verify the forms and GET/POST requirements; existing invoice experiments do not certify completion.
- [ ] Week 3 onward: await official content. No later-week behavior is implemented by this documentation update.

Official .NET release reference: <https://builds.dotnet.microsoft.com/dotnet/release-metadata/releases-index.json>.
