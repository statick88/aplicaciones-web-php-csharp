# Ebook de Aplicaciones Web con PHP y C# — Semana 1

Libro Quarto en español para repasar únicamente la primera semana de la asignatura. El contenido es formativo y estático: GitHub Pages puede publicar el resultado HTML, pero no ejecuta PHP ni servicios .NET.

## Renderizado local

Desde la raíz del repositorio, con [Quarto 1.10.19](https://quarto.org/docs/get-started/) instalado y disponible en `PATH`:

```bash
quarto render ebook
```

El resultado se escribe en `ebook/_book/`. El libro declara la URL pública base `https://statick88.github.io/aplicaciones-web-php-csharp/`, por lo que los enlaces internos se resuelven desde el proyecto de Pages.

## Comprobación estructural

```bash
python3 ebook/scripts/check_book.py
```

Con un render ya generado, añada `--rendered` para comprobar los artefactos HTML y PDF esperados:

```bash
python3 ebook/scripts/check_book.py --rendered
```

La comprobación no navega la red ni valida que Blackboard sea accesible: algunos enlaces del curso requieren autenticación. Tampoco reemplaza la revisión de ejemplos ejecutables en sus herramientas correspondientes.

## Publicación estática

El flujo [`.github/workflows/ebook.yml`](../.github/workflows/ebook.yml) renderiza el HTML y el PDF con Quarto 1.10.19, comprueba su estructura y publica exclusivamente `ebook/_book/` en GitHub Pages. Se ejecuta al cambiar `ebook/**` o el propio flujo en `main`, y también puede iniciarse manualmente. La URL prevista es `https://statick88.github.io/aplicaciones-web-php-csharp/`; estará disponible después de la primera ejecución verde y de que GitHub Pages esté habilitado para el repositorio.

GitHub Pages sirve archivos estáticos: permite leer el ebook HTML y descargar su PDF, pero no ejecuta PHP, ASP.NET Core, Docker ni Dev Containers. Los ejemplos que requieran esos entornos se realizan localmente según sus instrucciones.

## Alcance editorial

Las fuentes oficiales del curso tienen prioridad. La documentación técnica complementa la explicación y los repositorios de práctica aportan ejemplos observables. No se publican exportaciones privadas de Blackboard ni se afirma el uso de software de coautoría no identificado. Las futuras semanas esperan el progreso efectivo del curso.
