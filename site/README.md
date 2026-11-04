# Sitio estático de prácticas

La interfaz reproduce la composición oscura de `curso_net/site` y del recorrido autorizado `curso_net/design/aprende-csharp-dotnet/01-recorrido.html`: encabezado, hero radial, catálogo de dos columnas y lectura con barra lateral. Se adapta a **Programación Web**, PHP y .NET; no conserva la meta de certificación.

## Entrada de generación

El constructor consume `course/catalog.json` con el contrato de esquema 1 descrito en `odd/tasks/practicas-web-sin-quarto.md` (L7). Publica una copia en `site/course.json` sin `source`. La portada carga esa copia; las lecciones son documentos HTML estáticos generados desde `site/page.html`.

`page.html` conserva exactamente estos tokens: `{{root}}`, `{{title}}`, `{{content}}`, `{{navigation}}`, `{{pagination}}`, `{{week}}`. El constructor escapa título y semana, genera navegación/paginación y aplica `{{root}}` vacío en raíz o `../` a un nivel.

## Comprobaciones

```sh
node --test site/course-utils.test.mjs
```

Los recursos usan rutas relativas aptas para GitHub Pages bajo una subruta. La portada usa `textContent` para títulos y resultados; no inserta HTML editorial ni ejecuta endpoints PHP. El catálogo principal sólo presenta semanas vigentes; `pages` mantiene enlaces al cuaderno y al material archivado de otras asignaturas.
