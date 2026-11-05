# Entorno de desarrollo opcional {#entorno-desarrollo}

El objetivo sigue siendo aprender PHP y C#, no dominar una herramienta de
contenedores. Usa Docker Compose como única ruta de ejecución y aplica las
mismas comprobaciones de los capítulos **Fundamentos web** y **Variables, tipos y
alcance**. Docker Compose es una alternativa de ejecución, no un contenido que
debas aprobar para comprender la Semana 1.

::: {.callout-important}
## Antes de empezar

En Linux se verificaron los ejemplos de lenguaje y la ruta de ejecución con
Docker Compose. No se ejecutaron estas comprobaciones en Windows ni macOS.
:::

## Qué vas a preparar

Prepararás **dos escenarios alternativos**, cada uno con dos contenedores: uno
para la aplicación y otro para su base de datos. No necesitas instalar PHP,
.NET, MariaDB ni SQL Server directamente en tu computadora para esta ruta.

| Escenario | Servicio `app` | Servicio `db` |
|---|---|---|
| PHP + MariaDB | Apache, PHP y las extensiones `pdo_mysql` y `mysqli` | MariaDB |
| .NET + SQL Server | Aplicación ASP.NET Core MVC con `dotnet watch` | SQL Server |

Una **imagen** contiene el entorno de ejecución; un **contenedor** lo ejecuta.
Un **volumen** conserva los archivos de la base de datos aunque detengas el
contenedor. **Compose** describe los servicios y crea la red que los conecta.
Los archivos `php/compose.yaml`, `csharp/compose.yaml` y sus respectivos
`Dockerfile` ya existen: no debes crear otro proyecto para seguir esta práctica.

::: {.callout-warning}
## Entorno local, no receta de producción

Ambas aplicaciones usan `127.0.0.1:8080`: inicia **una por vez**. Los puertos de
las bases también se publican solo en loopback. La práctica .NET utiliza `sa` y
`TrustServerCertificate=True`; estas decisiones de desarrollo no deben copiarse
como configuración de seguridad de una aplicación en producción.
:::

## Elegir una ruta

| Ruta | Úsala cuando | Idea principal |
|---|---|---|
| VS Code + terminal Compose | quieres editar en tu host y controlar el stack desde una terminal | VS Code es el editor; Compose crea los servicios |

La aplicación `app` monta el código; el navegador, si se usa, ve la dirección
local indicada por Compose.

## Compatibilidad del host

| Host | Ruta de Docker documentada | Nota de arquitectura |
|---|---|---|
| Windows | WSL2 con Docker Desktop | Intel/AMD y Apple Silicon no aplican igual; consulta los requisitos de Desktop antes de instalar [@docker-docs] |
| Linux | Docker Engine; Docker Desktop no es requisito | la verificación actual fue aquí |
| macOS | Docker Desktop es el flujo documentado; Colima es una alternativa de compatibilidad no validada aquí | distingue Intel/AMD de Apple Silicon antes de elegir la práctica C# con base de datos |

No ejecutes `sudo`, cambios de grupo, instalaciones globales ni cambios de
seguridad del host desde esta guía. Sigue la documentación oficial de tu
plataforma para preparar Docker [@docker-docs]. Que un host pueda ejecutar un
contenedor simple no prueba que toda la práctica, y especialmente la base de
datos, sea compatible.

## Límite importante de SQL Server

La práctica C# usa SQL Server como servicio `db`. La documentación primaria de
SQL Server en contenedores Linux indica soporte para Linux x86-64 (Intel/AMD).
La emulación QEMU o Rosetta no está probada ni soportada [@sqlserver-containers].
Por ello no se promete que el stack C# con SQL Server funcione de manera nativa
en Apple Silicon, ni se reemplaza silenciosamente por otra base de datos.

Los ejemplos de lenguaje que no dependen de la base de datos pueden ejecutarse
con imágenes multi-arquitectura de PHP o del SDK .NET cuando estén disponibles.
Otra opción es un SQL Server x64 remoto, pero exige configurar explícitamente
la conexión: no viene configurado por este repositorio. Esta limitación no
cambia las comparaciones de variables, tipos, constantes o alcance.

## Ruta A: VS Code y terminal Compose

Esta ruta no requiere una ventana especial de VS Code. Ejecuta los comandos
siguientes desde la **raíz del repositorio**, no desde `php/public` ni `csharp/src`.

### Preparación común

**1. Abre una copia local del proyecto.** En su raíz deben estar las carpetas
`php/`, `csharp/` y `ebook/`. La obtención de la copia depende del canal de
entrega del curso; esta guía no la presenta como fuente técnica.

**2. Comprueba Docker y Compose.**

```bash
docker --version
docker compose version
docker info
```

Los dos primeros comandos identifican las herramientas; `docker info` comprueba
el acceso al motor. Si este último falla, resuelve la preparación de Docker con
la documentación de tu plataforma antes de investigar PHP o .NET. No necesitas
instalar los lenguajes ni los motores de base de datos en el host. La primera
construcción sí necesita acceso a los registros para descargar las imágenes.

**3. Decide qué escenario usar.** Los dos necesitan el puerto `8080` del host;
MariaDB publica además `3306` y SQL Server `1433`. Si otra aplicación ocupa uno
de esos puertos, identifica el conflicto antes de arrancar; no borres datos ni
modifiques servicios del host automáticamente.

::: {.callout-warning}
## Configura las contraseñas antes del primer arranque

Los Compose incluyen contraseñas de respaldo solo para desarrollo. Los archivos
`.env` que prepararás están ignorados por Git: no publiques sus valores ni los
incluyas en capturas. Los marcadores entre `<` y `>` deben reemplazarse completos
por contraseñas propias antes de ejecutar los comandos.

Si ya habías iniciado una base y su volumen contiene datos, **cambiar `.env` no
equivale a cambiar la contraseña almacenada en esa base**. Verifica las
credenciales existentes o realiza un cambio explícito dentro del motor; no
elimines el volumen para corregir una discrepancia.
:::

### PHP

El escenario usa `php/Dockerfile` y `php/compose.yaml`. El primero prepara
Apache, PHP 8.5.12 y las extensiones `pdo_mysql` y `mysqli`; Compose conecta
`app` con MariaDB. La configuración de Compose de esta práctica define esos
servicios; para instalar o administrar Docker, consulta su documentación oficial
[@docker-docs].

**1. Crea `php/.env` con tu editor.** Usa dos contraseñas distintas:

```dotenv
MARIADB_PASSWORD='<CLAVE_PROPIA_PARA_LA_APLICACION>'
MARIADB_ROOT_PASSWORD='<OTRA_CLAVE_PROPIA_PARA_ROOT>'
```

`MARIADB_PASSWORD` configura tanto el usuario de la base como `DB_PASSWORD` en
la aplicación. La aplicación usa el usuario `app` y la base `facturas`, no el
usuario administrador `root`. No tienes que crear esos nombres manualmente:
MariaDB los prepara mediante las variables del Compose en su inicialización.

**2. Valida la configuración y levanta el escenario.** Si habías iniciado el
escenario C#, detenlo primero como se indica en su sección de apagado.

```bash
docker compose --env-file php/.env -f php/compose.yaml config --quiet
docker compose --env-file php/.env -f php/compose.yaml up -d --build
```

`--env-file` selecciona explícitamente las variables, `-f` el archivo del
escenario, `--build` construye la imagen de la aplicación y `-d` deja los
servicios ejecutándose en segundo plano. El primer comando valida el modelo
sin imprimir las contraseñas; no comprueba que la base acepte conexiones.

**3. Revisa el estado.**

```bash
docker compose --env-file php/.env -f php/compose.yaml ps
```

Busca los servicios `app` y `db`. La base puede aparecer inicialmente como
`starting`; `app` depende de que la comprobación de salud de MariaDB termine
correctamente. Si hay un problema, consulta cada servicio por separado:

```bash
docker compose --env-file php/.env -f php/compose.yaml logs --tail=80 db
docker compose --env-file php/.env -f php/compose.yaml logs --tail=80 app
```

**4. Comprueba la aplicación y un guardado real.** Abre
`http://127.0.0.1:8080`. Ver una página confirma que responde PHP/Apache, pero no
prueba por sí solo que PHP pueda guardar en MariaDB.

Para comprobar el recorrido completo, abre `http://127.0.0.1:8080/home.php`,
completa el formulario con **datos ficticios** y presiona **Guardar**. En este
proyecto, `php/public/home.php` abre la conexión mediante PDO al recibir el POST,
crea la tabla `facturas` con `CREATE TABLE IF NOT EXISTS` y después ejecuta el
`INSERT` parametrizado. No hay un archivo SQL de inicio que debas importar.
El resultado esperado incluye **“Guardada en MariaDB”** y el identificador de la
fila. Si aparece **“No se pudo guardar en la base de datos”**, revisa el error y
las credenciales; no consideres exitoso el ejercicio solo porque el formulario
se haya mostrado.

**5. Edita el código y detén sin borrar datos.** El proyecto PHP completo está
montado en `/var/www/html`, pero Apache solo sirve `public/` como DocumentRoot:
la lógica (`src/`), las plantillas (`views/`) y la configuración (`config/`)
quedan fuera de la URL. Para cambios de PHP normalmente basta con guardar el
archivo y recargar el navegador. Reconstruye si modificas el `Dockerfile` o sus
extensiones.

```bash
docker compose --env-file php/.env -f php/compose.yaml stop
```

Para volver a iniciar, reutiliza el mismo comando `up -d --build` del paso 2.

### C# / ASP.NET Core

El escenario usa `csharp/Dockerfile` y `csharp/compose.yaml`: un contenedor con
SDK .NET 10.0.403 y `dotnet watch`, y otro con SQL Server 2022. Antes de
empezar, respeta el límite x86-64 explicado arriba y la documentación oficial de
SQL Server en contenedores [@sqlserver-containers]. El Compose declara
`ACCEPT_EULA=Y`: revisa los términos de Microsoft antes de utilizar la imagen.

**1. Libera el puerto y crea `csharp/.env`.** Si ya preparaste PHP con los pasos
anteriores y sigue encendido, detenlo:

```bash
docker compose --env-file php/.env -f php/compose.yaml stop
```

Si comienzas directamente por .NET y no has preparado PHP, omite ese comando.
Luego crea el archivo con tu editor:

```dotenv
MSSQL_SA_PASSWORD='<CLAVE_PROPIA_FUERTE_PARA_SQL_SERVER>'
```

Reemplaza el marcador por una contraseña propia; se recomienda al menos 16
caracteres combinando mayúsculas, minúsculas, números y símbolos como `!`, `_`
o `-`. Evita `;` en este ejemplo: la contraseña se interpola directamente en
la cadena de conexión. El mismo valor configura SQL Server y la variable
`ConnectionStrings__Facturas` de la aplicación.

**2. Valida y construye.**

```bash
docker compose --env-file csharp/.env -f csharp/compose.yaml config --quiet
docker compose --env-file csharp/.env -f csharp/compose.yaml up -d --build
```

No necesitas ejecutar `dotnet new` ni instalar el SDK en el host: el proyecto
MVC ya está en `csharp/src` y el SDK está dentro de `app`.

**3. Espera a SQL Server y revisa los registros.**

```bash
docker compose --env-file csharp/.env -f csharp/compose.yaml ps
docker compose --env-file csharp/.env -f csharp/compose.yaml logs --tail=100 db
docker compose --env-file csharp/.env -f csharp/compose.yaml logs --tail=100 app
```

La comprobación de salud de `db` ejecuta una consulta con `sqlcmd`; `app` espera
a que termine correctamente. Ese estado confirma que responde el motor, no que
el formulario de la aplicación ya haya guardado una factura.

**4. Comprueba las migraciones y el formulario.** Al iniciar, `Program.cs`
ejecuta `Database.Migrate()`: aplica las migraciones pendientes de EF Core en la
base `Facturas`. Para este arranque no debes ejecutar manualmente
`dotnet ef database update`. Si una migración falla, la aplicación puede no
iniciar: revisa los registros de `app`, no solo los de SQL Server.

Abre `http://127.0.0.1:8080` y completa el formulario con datos ficticios. El POST
llega a `HomeController`, agrega la entidad y llama a `SaveChanges()`. El envío
exitoso vuelve mostrando los datos; esta aplicación no tiene un mensaje
específico de “conexión correcta” ni un endpoint de salud propio. No inventes
esa evidencia: el recorrido que debes comprobar es formulario, POST y guardado.

**5. Edita y detén el escenario.** `csharp/src` está montado en `/app`;
`dotnet watch` detecta cambios y recompila durante el desarrollo.

```bash
docker compose --env-file csharp/.env -f csharp/compose.yaml stop
```

Para retomar, usa el mismo comando `up -d --build` del paso 2.

### Direcciones y persistencia

| Servicio | Desde el navegador o una herramienta del host | Desde `app` |
|---|---|---|
| Aplicación PHP o .NET | `http://127.0.0.1:8080` | No aplica |
| MariaDB | `127.0.0.1:3306` | `db:3306` |
| SQL Server | `127.0.0.1:1433` | `db:1433` |

Dentro de `app`, `localhost` es el propio contenedor de la aplicación. La base
se encuentra por el nombre de servicio **`db`**, que resuelve la red de Compose.
No hay phpMyAdmin ni un administrador web de SQL Server configurados: la
página en `8080` es la aplicación de práctica.

MariaDB guarda sus archivos en un volumen montado en `/var/lib/mysql`; SQL
Server en `/var/opt/mssql`. Son datos distintos del código montado desde `src`.
`stop` conserva contenedores y volúmenes. Reutiliza el mismo escenario y nombre
de proyecto: cambiar de proyecto puede seleccionar otros volúmenes.
**No ejecutes `down -v` como solución de problemas:** puede eliminar los datos.

### Si algo falla

| Síntoma | Qué revisar primero |
|---|---|
| Docker no responde o no permite el acceso | `docker info` y la preparación del motor en tu host |
| No encuentra `.env` o `compose.yaml` | La raíz del repositorio y los argumentos `--env-file` y `-f` |
| Puerto ocupado | El otro escenario o un servicio local que ya usa `8080`, `3306` o `1433` |
| `db` permanece iniciando o queda `unhealthy` | Registros de `db`, recursos disponibles y, para SQL Server, contraseña y arquitectura |
| Error de autenticación | Coincidencia de credenciales y si el volumen ya tenía otra contraseña; no lo borres |
| PHP muestra el formulario pero no guarda | POST a `/home.php`, mensaje de error y conexión PDO |
| .NET no inicia o falla al enviar | Registros de `app`, migraciones y conexión usada por `SaveChanges()` |

Que un contenedor figure en `ps` no prueba todo el escenario. Separa siempre
cuatro comprobaciones: configuración válida, servicios disponibles, respuesta
HTTP y persistencia de un registro de prueba. No se promete aquí ejecución en
hosts o integraciones que no se hayan verificado.


## VS Code: extensiones y perfiles

Las extensiones no se instalan automáticamente; instálalas manualmente según
el escenario que uses.

**PHP + MariaDB** ("PHP Intelephense", "PHP Debug", "SQLTools" y "SQLTools
Driver: MySQL/MariaDB"):
- PHP Intelephense
- PHP Debug
- SQLTools
- SQLTools Driver: MySQL/MariaDB

**.NET + SQL Server** ("C# Dev Kit", ".NET Extension Pack" y "SQL Server
(mssql)"):
- C# Dev Kit
- .NET Extension Pack
- SQL Server (mssql)

Crea perfiles separados en VS Code: **"PHP + MariaDB"** y **".NET + SQL
Server"**, con las extensiones recomendadas en cada uno.

## Cliente vs servidor

El navegador y VS Code son el **cliente**; PHP/Apache, .NET Kestrel y las
bases de datos son el **servidor**. Los servicios se comunican por nombre
dentro de la red de Compose: `db:3306` (MariaDB) y `db:1433` (SQL Server).
Desde el host se accede por `127.0.0.1:3306` y `127.0.0.1:1433`.

## Comprobación de aprendizaje, no de plataforma

Selecciona una alternativa y usa la retroalimentación para distinguir evidencia de
servicio, respuesta HTTP y persistencia. Las prácticas de ejecución siguen siendo
opcionales y no requieren una respuesta escrita.

<!-- quiz: web-environment-evidence -->

<!-- quiz: web-environment-boundary -->

Si no puedes iniciar el stack C# en Apple Silicon, aún puedes estudiar los
fragmentos y completar la comparación conceptual. No presentes esa lectura
como ejecución verificada del servicio SQL Server.

## Referencias de operación

- [Documentación de Docker Engine](https://docs.docker.com/engine/install/)
  para la preparación específica del host [@docker-docs].
- [SQL Server en contenedores Linux](https://learn.microsoft.com/sql/linux/install-upgrade/quickstart-install-docker)
  para el límite x86-64 y soporte de emulación [@sqlserver-containers].
