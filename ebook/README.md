# Cuaderno de estudio y práctica — Ingeniería de Software

Libro Quarto en español que crece por asignatura y semana para preparar evaluaciones con teoría, ejemplos resueltos, práctica y autoevaluación. La cobertura actual es Aplicaciones Web con PHP y C#, Semana 1. El contenido es formativo y estático: GitHub Pages puede publicar el resultado HTML, pero no ejecuta PHP ni servicios .NET.

## Renderizado local

Desde la raíz del repositorio, con [Quarto 1.10.19](https://quarto.org/docs/get-started/) instalado y disponible en `PATH`:

```bash
quarto render ebook
```

El HTML usa **Solar oscuro por defecto**, un tema Bootstrap integrado de [Quarto para HTML](https://quarto.org/docs/output-formats/html-themes.html). `solarized` pertenece a las presentaciones reveal.js y no es el nombre del tema de este libro. Quarto puede emitir inicialmente `quarto-light` en el cuerpo y aplicar el modo mediante JavaScript: la comprobación inspecciona el enlace Bootstrap con `data-mode="dark"` y su paleta CSS predeterminada.

La bibliografía central declara `nocite: '@*'` para conservar todas las entradas
registradas, también cuando Quarto reutiliza capítulos sin cambios. Las citas de
otros capítulos deben seguir teniendo destino en `references.html`.

El resultado se escribe en `ebook/_book/`. El libro declara la URL pública base `https://statick88.github.io/aplicaciones-web-php-csharp/`, por lo que los enlaces internos se resuelven desde el proyecto de Pages.

## Organización por asignatura y semana

Cada asignatura es una parte del libro. Quarto no admite una parte dentro de otra:
las semanas se indican en la cobertura de la página de asignatura y en las rutas
semanales de los capítulos nuevos, no mediante partes anidadas. Las rutas históricas
de Web se conservan. Para otra semana, añada sus capítulos a la misma parte y actualice
la tabla de cobertura con el material efectivamente verificado.

Como apoyo transversal de Web, [Tablas de consulta HTTP](subjects/aplicaciones-web/consulta-http.qmd)
resume siete métodos, idempotencia, datos en DevTools/PHP y estados frecuentes.
El [laboratorio PHP de métodos HTTP](subjects/aplicaciones-web/laboratorio-http-php.qmd)
añade práctica local con cinco peticiones y capturas reales de DevTools Network. No
presenta estas referencias como una nueva semana del programa.

Para ejecutar el laboratorio desde la raíz del repositorio, se necesita PHP local:

```bash
php -S 127.0.0.1:8088 -t ebook/examples/http-methods ebook/examples/http-methods/router.php
```

Abre `http://127.0.0.1:8088/` y sigue `ebook/examples/http-methods/README.md`.
El enlace loopback, el document root aislado y `router.php` son parte de la
protección: no omitas el router, no uses `0.0.0.0` ni sirvas la raíz del repositorio.
`file://` y GitHub Pages no ejecutan PHP.

## Comprobación estructural

```bash
python3 ebook/scripts/check_book.py
```

Con un render ya generado, añada `--rendered` para comprobar todas las páginas configuradas (incluidas respuestas y referencias), imágenes con texto alternativo, destinos locales de enlaces y recursos HTML, anclas HTML, tema Solar oscuro y firma inicial `%PDF-` del PDF:

```bash
python3 ebook/scripts/check_book.py --rendered
```

Pruebas aisladas del comprobador (sin dependencias adicionales):

```bash
python3 -B -m unittest discover -s ebook/tests -v
```

La comprobación lee las entradas escalares `.qmd`, `file:` y `part:` de la configuración actual (también en listas anidadas); no es un analizador YAML general. No navega la red ni valida que Blackboard sea accesible: algunos enlaces del curso requieren autenticación. Comprueba referencias HTML `href`, `src`, `poster` y datos de objetos; no ejecuta JavaScript ni inspecciona recursos referidos desde CSS. La firma PDF no garantiza la integridad de todas sus páginas. La existencia de archivos y anclas no demuestra corrección pedagógica ni equivalencia entre HTML y PDF; tampoco reemplaza la revisión de ejemplos ejecutables en sus herramientas correspondientes.

## Publicación estática

**Esta tarea no realizó ninguna publicación.** El flujo [`.github/workflows/ebook.yml`](../.github/workflows/ebook.yml) renderiza el HTML y el PDF con Quarto 1.10.19, comprueba su estructura y publica exclusivamente `ebook/_book/` en GitHub Pages. Se ejecuta al cambiar `ebook/**` o el propio flujo en `main`, y también puede iniciarse manualmente. La URL prevista es `https://statick88.github.io/aplicaciones-web-php-csharp/`; estará disponible después de la primera ejecución verde y de que GitHub Pages esté habilitado para el repositorio.

Cambiar el tema o renderizar localmente no actualiza el sitio público: es necesario publicar el nuevo resultado mediante el flujo. Mientras no se publique, Pages puede seguir mostrando el tema anterior.

GitHub Pages sirve archivos estáticos: permite leer el ebook HTML y descargar su PDF, pero no ejecuta PHP, ASP.NET Core, Docker ni Dev Containers. Los ejemplos que requieran esos entornos se realizan localmente según sus instrucciones.

## Alcance editorial

Las fuentes oficiales de cada asignatura tienen prioridad. La documentación técnica complementa la explicación y los repositorios de práctica aportan ejemplos observables. No se publican exportaciones privadas de Blackboard ni se afirma el uso de software de coautoría no identificado.

Para incorporar una semana futura: verifique primero las fuentes oficiales; agregue capítulos, ejercicios y retroalimentación explicativos y originales; actualice la cobertura semanal, la navegación y las referencias; después renderice y ejecute la comprobación estructural. No invente contenido curricular futuro.

La primera lectura de Semana 2 de Arquitectura explica actividades, flujo, tareas
y patrones de proceso mediante un caso original de reservas de biblioteca.
