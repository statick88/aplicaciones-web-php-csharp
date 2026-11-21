# Semanas 4 y 5: alineación, estudio y pendientes

**El estudio está disponible; la práctica ejecutable todavía no es completa.** El cuaderno publica cuatro lecciones y sus autoevaluaciones formativas para las Semanas 4 y 5. Este informe conserva la trazabilidad entre los temas aportados, esas lecciones y las brechas de aplicación. No es una evaluación oficial ni prueba de ejecución local.

## Cómo interpretar la cobertura

- **Material aportado:** temas de clase recibidos; no demuestra ejecución local.
- **Estudio disponible:** lección, ejemplos instructivos, práctica de razonamiento y autoevaluación publicados.
- **Práctica parcial:** existe un código relacionado, pero no cubre ni verifica todo el recorrido de la clase.
- **Pendiente:** aplicación, recorrido o evidencia específica que aún falta.

Los temas de origen se conservan en las tablas siguientes sin atribuir un acceso renovado a Blackboard.

## Semana 4

| Clase | Temas del material aportado | Estudio publicado | Brecha práctica pendiente |
| --- | --- | --- | --- |
| 1 | Cadenas UTF-8, funciones `mb_*`, expresiones regulares `preg_*`, arreglos y transformaciones; comparación con DataAnnotations y LINQ | [Cadenas, expresiones regulares y arreglos](semana-04/01-cadenas-regex-arreglos.md#semana4-clase1-cadenas) cubre esos temas con [autoevaluación](semana-04/01-cadenas-regex-arreglos.md#s4c1-autoevaluacion) y distingue PHP de C#. | No hay una aplicación ejecutada que verifique este conjunto de objetivos. |
| 2 | POO, encapsulación de PHP 8.4, herencia, interfaces, repositorio PDO, inyección de dependencias, capas y excepciones; MVC y EF Core | [POO, capas y repaso del Parcial I](semana-04/02-poo-capas-parcial-i.md#semana4-clase2-poo) explica el recorrido y ofrece [autoevaluación](semana-04/02-poo-capas-parcial-i.md#s4c2-autoevaluacion). | Falta completar y verificar la práctica PHP de repositorio/capas y cualquier equivalencia integral con C#. |
| Repaso parcial I | Guía de temas y ejercicios T01–T16/C01 al final de la clase 2 | El repaso guiado y la autoevaluación son de estudio. | No hay evaluación oficial local ni se declara el Parcial I aprobado. |

### Evidencia local relacionada, no equivalencia completa

- `csharp/src/Controllers/ClientesController.cs`: acciones CRUD MVC.
- `csharp/src/Models/ClienteSemana3.cs`: modelo y anotaciones.
- `csharp/src/Data/FacturasDbContext.cs`: contexto EF Core; el proveedor configurado en `Program.cs` es SQL Server, no MySQL.
- `csharp/tests/test_semana3_http.py`: pruebas HTTP del CRUD de Semana 3. Su existencia no acredita todos los objetivos de Semana 4; este informe no vuelve a ejecutar ese stack.
- `php/src/semana2-cliente.php`: CRUD en memoria de Semana 2, no repositorio PDO de Semana 4.

## Semana 5

| Clase | Temas del material aportado | Estudio publicado | Brecha práctica pendiente |
| --- | --- | --- | --- |
| 1 · Tablas | CRUD, DDL/DML, restricciones, `ALTER TABLE` y migraciones | [Tablas, mantenimiento y archivos](semana-05/01-tablas-archivos.md#semana5-clase1-tablas) explica DDL, DML, restricciones y migraciones, con [autoevaluación](semana-05/01-tablas-archivos.md#s5c1-autoevaluacion). | Falta laboratorio MySQL con datos aislados y comprobaciones reales de tablas, restricciones y migraciones. |
| 1 · Archivos | Carga Angular hacia PHP/.NET; validación del servidor de MIME, tamaño y extensión; control de acceso | La misma lección describe `FormData`, el algoritmo de recepción y el contraste PHP/.NET/Angular. | No hay carga/descarga autorizada, frontend Angular ni endpoint implementados y probados. |
| 2 · INSERT | Angular → API → MySQL, parámetros preparados/EF y transacciones | [INSERT, SELECT y consultas verificables](semana-05/02-insert-select.md#semana5-clase2-insert-select) cubre parámetros, transacciones y su [autoevaluación](semana-05/02-insert-select.md#s5c2-autoevaluacion). | Falta API y cliente Angular conectados a MySQL, con inserciones y transacciones verificadas. |
| 2 · SELECT | Consultas, JOIN, filtros, paginación y comprobaciones con Postman | La misma lección explica JOIN, filtros, paginación y un plan de comprobación. | Faltan consultas y pruebas del contrato API en ejecución, incluidos filtros y paginación. |

## Criterio de aceptación separado

1. **Estudio:** una semana entra al catálogo cuando sus lecciones, ejercicios y autoevaluaciones formativas trazan los temas confirmados; por ello `currentWeek` ya es 5.
2. **Aplicación:** una práctica se acepta solo tras implementar y verificar su flujo en un entorno aislado, distinguiendo qué se ejecutó realmente.
3. La aceptación de estudio no afirma paridad PHP/C#, ejemplos ejecutados, datos modificados ni una evaluación oficial aprobada.

Esta actualización publica las **lecciones y el diagnóstico**; no implementa las aplicaciones pendientes. GitHub Pages sirve archivos estáticos: no aloja backends PHP/ASP.NET Core, bases de datos ni recepción de archivos. Puede servir un frontend Angular compilado, pero este cuaderno no despliega esa aplicación; solo explica sus fragmentos de estudio. El avance guardado en el navegador corresponde a las autoevaluaciones disponibles de las Semanas 1 a 5 y sigue siendo formativo.
