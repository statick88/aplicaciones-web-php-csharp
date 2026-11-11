# Semana 3 — CRUD de clientes

Aplicación web en C# con ASP.NET Core MVC, Entity Framework Core y SQL Server.

## Tarea

Crear, listar, consultar, editar y eliminar clientes. La tabla `Clientes` contiene `Id` y diez campos: cédula, nombres, apellidos, correo, teléfono, dirección, ciudad, provincia, fecha de nacimiento y estado activo.

## Ejecución

Desde `csharp/`:

```bash
docker compose up -d --build
```

Abrir <http://127.0.0.1:8080/Clientes>. La aplicación crea la tabla mediante una migración al iniciar. Usar datos ficticios: es una práctica local sin autenticación.
