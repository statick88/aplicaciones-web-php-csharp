# Semanas 4 y 5: alineación y pendientes

**La cobertura todavía no es completa.** El cuaderno publica lecciones y autoevaluaciones de las Semanas 1 a 3. La Semana 4 tiene coincidencias parciales con prácticas anteriores; la Semana 5 no tiene una implementación integral local. Este informe no es una lección completada ni una evaluación oficial.

## Cómo interpretar la cobertura

- **Material aportado:** contenido de clase recibido; no demuestra ejecución local.
- **Parcial:** existe una práctica relacionada, pero no cubre todos los objetivos de la clase.
- **Pendiente:** falta la lección activa, la práctica correspondiente o evidencia específica de su ejecución.

El contraste usa las transcripciones locales `clase1-semana4.txt`, `clase2-semana4.txt`, `semana5-contenido1.txt` y `semana5-contenido2.txt`. No se afirma un acceso renovado a Blackboard. Los archivos de origen locales no se distribuyen con este informe; los temas relevantes quedan identificados abajo.

## Semana 4

| Clase | Contenido del material aportado | Cobertura actual | Qué falta para declarar alineación |
| --- | --- | --- | --- |
| 1 | Cadenas UTF-8, funciones `mb_*`, expresiones regulares `preg_*`, arreglos y transformaciones; comparación con DataAnnotations y LINQ | Hay ejemplos previos de tipos, cadenas y validación, pero no una lección activa de esta clase | Desarrollar cadenas multibyte, regex y operaciones sobre arreglos con ejemplos, ejercicios y comprobaciones específicas; distinguir PHP de C# |
| 2 | POO, encapsulación de PHP 8.4, herencia, interfaces, repositorio PDO, inyección de dependencias, capas y excepciones; MVC y EF Core | **Parcial:** C# ya contiene CRUD MVC de clientes, un modelo con anotaciones y persistencia EF Core sobre SQL Server; PHP tiene un Cliente en memoria y un experimento PDO, no una implementación equivalente de toda la clase | Completar el recorrido POO/repositorio/capas y su práctica PHP; explicar las diferencias con C# y verificar los objetivos pendientes |
| Repaso parcial I | Guía de temas y ejercicios T01–T16/C01 al final de la clase 2 | No hay una evaluación local publicada que cubra esta guía completa | Preparar repaso y autoevaluación diferenciados de la evaluación oficial; no declarar el parcial aprobado |

### Evidencia local relacionada, no equivalencia completa

- `csharp/src/Controllers/ClientesController.cs`: acciones CRUD MVC.
- `csharp/src/Models/ClienteSemana3.cs`: modelo y anotaciones.
- `csharp/src/Data/FacturasDbContext.cs`: contexto EF Core; el proveedor configurado en `Program.cs` es SQL Server, no MySQL.
- `csharp/tests/test_semana3_http.py`: pruebas HTTP del CRUD de Semana 3. Su existencia no acredita todos los objetivos de Semana 4; este informe no vuelve a ejecutar ese stack.
- `php/src/semana2-cliente.php`: CRUD en memoria de Semana 2, no repositorio PDO de Semana 4.

## Semana 5

| Clase | Contenido del material aportado | Cobertura actual | Qué falta para declarar alineación |
| --- | --- | --- | --- |
| 1 · Tablas | CRUD, DDL/DML, restricciones, `ALTER TABLE` y migraciones | Hay persistencia experimental y migraciones EF Core de otras prácticas; no constituyen el recorrido MySQL completo | Lección y laboratorio de tablas/restricciones/migraciones con comprobaciones sobre datos de prueba aislados |
| 1 · Archivos | Carga Angular hacia PHP/.NET; validación del servidor de MIME, tamaño y extensión; control de acceso | Sin práctica integral de carga/descarga autorizada ni frontend Angular identificado | Implementar y probar el flujo completo antes de declararlo disponible; no confundir un ejemplo de clase con una carga segura ya verificada |
| 2 · INSERT | Angular → API → MySQL, parámetros preparados/EF y transacciones | El CRUD MVC existente usa SQL Server y formularios Razor, no este recorrido | Preparar API y cliente correspondientes, inserciones parametrizadas y comprobaciones de transacciones |
| 2 · SELECT | Consultas, JOIN, filtros, paginación y comprobaciones con Postman | Sin evidencia local del conjunto de objetivos de esta clase | Desarrollar consultas y recorrido de pruebas del contrato de la API, incluidos filtros y paginación |

## Criterio para ampliar el catálogo

1. Crear las dos lecciones de cada semana a partir de sus fuentes, con diferencias PHP/C# explícitas.
2. Incorporar ejemplos y autoevaluaciones formativas que cubran los objetivos de cada clase.
3. Separar lectura conceptual de prácticas ejecutables y registrar qué se ejecutó realmente.
4. Verificar las prácticas en entornos aislados y construir/validar el sitio.
5. Solo entonces registrar los módulos semanales y avanzar `currentWeek` en `course/catalog.json`.

Esta actualización publica el **diagnóstico**, no implementa las aplicaciones pendientes. GitHub Pages sirve HTML estático: no ejecuta PHP, ASP.NET Core, bases de datos ni cargas de archivos. El avance guardado en el navegador sigue correspondiendo exclusivamente a las evaluaciones disponibles de las Semanas 1 a 3.
