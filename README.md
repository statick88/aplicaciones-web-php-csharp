# aplicaciones-web-php-csharp

Repositorio público único de prácticas educativas de Aplicaciones Web, no de producción. Reúne los mismos ejercicios del curso en dos implementaciones por tecnología; el avance real se indica por separado en cada directorio, por lo que no se declara paridad completa.

| Implementación | Directorio | Guía específica |
| --- | --- | --- |
| PHP | [`php/`](php/) | [README de PHP](php/README.md) |
| C# / ASP.NET Core | [`csharp/`](csharp/) | [README de C#](csharp/README.md) |
| Ebook de Semana 1 | [`ebook/`](ebook/) | [README del ebook](ebook/README.md) |

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

## Ebook de Semana 1

El ebook estático de repaso se mantiene en [`ebook/`](ebook/) y cubre únicamente la Semana 1. Su URL prevista es [https://statick88.github.io/aplicaciones-web-php-csharp/](https://statick88.github.io/aplicaciones-web-php-csharp/); el despliegue queda pendiente de la primera ejecución verde del flujo de GitHub Pages.

## Semana 1 — avance verificado

Fuentes oficiales: [Clase 1](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334077_1?view=content&state=view) y [Clase 2](https://uniandesec.blackboard.com/ultra/courses/_3085_1/document/_334079_1?view=content&state=view).

### Clase 1 — PHP

- [x] Páginas estáticas y dinámicas: ejemplos PHP ejercitados.
- [x] Petición–respuesta HTTP: ejemplos ejercitados.
- [x] Entorno Docker con PHP 8.5 aceptado para la práctica.
- [ ] Historia de PHP 5 a 8.5: pendiente de practicar/verificar.
- [ ] Estructura separada `public/`, `src/`, `views/`, `config/` y ejemplos `require`/`include`: pendiente; `php/src/home.php` sigue siendo monolítico, no MVC.

### Clase 2 — .NET y variables

- [x] Diferencia .NET/ASP.NET y comparación PHP/C#: ejemplos ejercitados.
- [x] Declaración de variables, tipos e inferencia en PHP/C#: ejemplos ejercitados.
- [ ] Ejemplos específicos de valores nulos e interpolación: pendientes de verificar.
- [ ] Constantes (`const`/`define` en PHP y `const` en C#): pendiente de verificar.
- [ ] Scope y ejemplo recomendado de pasar parámetros en vez de `global`: pendiente de verificar.

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
