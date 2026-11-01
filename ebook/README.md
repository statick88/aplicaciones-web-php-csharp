# Ebook de Aplicaciones Web con PHP y C# — Semana 1

Libro Quarto en español para repasar únicamente la primera semana de la asignatura. El contenido es formativo y estático: GitHub Pages puede publicar el resultado HTML, pero no ejecuta PHP ni servicios .NET.

## Renderizado local

Desde la raíz del repositorio, con [Quarto 1.10.19](https://quarto.org/docs/get-started/) instalado y disponible en `PATH`:

```bash
quarto render ebook
```

El HTML usa **Solar oscuro por defecto**, un tema Bootstrap integrado de [Quarto para HTML](https://quarto.org/docs/output-formats/html-themes.html). `solarized` pertenece a las presentaciones reveal.js y no es el nombre del tema de este libro. Quarto puede emitir inicialmente `quarto-light` en el cuerpo y aplicar el modo mediante JavaScript: la comprobación inspecciona el enlace Bootstrap con `data-mode="dark"` y su paleta CSS predeterminada.

El resultado se escribe en `ebook/_book/`. El libro declara la URL pública base `https://statick88.github.io/aplicaciones-web-php-csharp/`, por lo que los enlaces internos se resuelven desde el proyecto de Pages.

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

La comprobación lee las entradas escalares `.qmd` de la configuración actual (también en listas anidadas); no es un analizador YAML general. No navega la red ni valida que Blackboard sea accesible: algunos enlaces del curso requieren autenticación. Comprueba referencias HTML `href`, `src`, `poster` y datos de objetos; no ejecuta JavaScript ni inspecciona recursos referidos desde CSS. La firma PDF no garantiza la integridad de todas sus páginas. La existencia de archivos y anclas no demuestra corrección pedagógica ni equivalencia entre HTML y PDF; tampoco reemplaza la revisión de ejemplos ejecutables en sus herramientas correspondientes.

## Publicación estática

El flujo [`.github/workflows/ebook.yml`](../.github/workflows/ebook.yml) renderiza el HTML y el PDF con Quarto 1.10.19, comprueba su estructura y publica exclusivamente `ebook/_book/` en GitHub Pages. Se ejecuta al cambiar `ebook/**` o el propio flujo en `main`, y también puede iniciarse manualmente. La URL prevista es `https://statick88.github.io/aplicaciones-web-php-csharp/`; estará disponible después de la primera ejecución verde y de que GitHub Pages esté habilitado para el repositorio.

Cambiar el tema o renderizar localmente no actualiza el sitio público: es necesario publicar el nuevo resultado mediante el flujo. Mientras no se publique, Pages puede seguir mostrando el tema anterior.

GitHub Pages sirve archivos estáticos: permite leer el ebook HTML y descargar su PDF, pero no ejecuta PHP, ASP.NET Core, Docker ni Dev Containers. Los ejemplos que requieran esos entornos se realizan localmente según sus instrucciones.

## Alcance editorial

Las fuentes oficiales del curso tienen prioridad. La documentación técnica complementa la explicación y los repositorios de práctica aportan ejemplos observables. No se publican exportaciones privadas de Blackboard ni se afirma el uso de software de coautoría no identificado. Las futuras semanas esperan el progreso efectivo del curso.

## Revisión de la integración

La ampliación por asignatura se prepara en una cadena de revisión. Este punto es
solo el seguimiento en borrador: no debe integrarse a la rama principal hasta
revisar sus unidades, resolver las comprobaciones pendientes y aprobar el alcance.
