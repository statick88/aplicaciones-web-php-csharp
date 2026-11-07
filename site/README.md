# Sitio estático de prácticas

La interfaz reproduce la composición oscura de `curso_net/site` y del recorrido autorizado `curso_net/design/aprende-csharp-dotnet/01-recorrido.html`: encabezado, hero radial, catálogo de dos columnas y lectura con barra lateral. Se adapta a **Programación Web**, PHP y .NET; no conserva la meta de certificación.

El diseño utiliza todo el ancho disponible, con 1rem de margen interior lateral. Las lecciones no tienen un ancho máximo independiente; ocupan la columna completa junto al índice y se apilan en móvil.

## Entrada de generación

El constructor consume `course/catalog.json` con el contrato de esquema 1 descrito en `odd/tasks/practicas-web-sin-quarto.md` (L7). Publica una copia en `site/course.json` sin `source`. La portada carga esa copia; las lecciones son documentos HTML estáticos generados desde `site/page.html`.

`page.html` conserva exactamente estos tokens: `{{root}}`, `{{title}}`, `{{content}}`, `{{navigation}}`, `{{pagination}}`, `{{week}}`. El constructor escapa título y semana, genera navegación/paginación y aplica `{{root}}` vacío en raíz o `../` a un nivel. También publica `assessments.json` (esquema 1) y copia `progress.mjs` y `quiz.mjs`; las lecciones cargan el módulo con `{{root}}quiz.mjs`.

## Comprobaciones

```sh
node --test site/*.test.mjs
```

La comprobación visual de ancho completo cubre portada, lecciones y formularios en 375, 1920 y 2560px. Con `_site` generado y servido en `http://127.0.0.1:4187/`, puede ejecutarse con Playwright CLI:

```sh
playwright-cli open http://127.0.0.1:4187/
playwright-cli run-code --filename tests/browser-layout.js
playwright-cli run-code --filename tests/browser-progress.js
```

Tras generar `assessments.json` y las lecciones con cuestionarios, `browser-progress.js` crea un contexto aislado: responde una opción errónea, recarga, cambia a la correcta y comprueba el resumen de portada. No borra el almacenamiento de un perfil humano. El mismo archivo puede ejecutarse como función de página desde la herramienta Playwright del entorno. `browser-layout.js` comprueba el ancho del contenedor, el espacio restante de las lecciones y la ausencia de desborde horizontal.

Las evaluaciones son únicamente de opción múltiple: cada selección muestra `Correcta` o `Por revisar`, la justificación de la alternativa y su objetivo/nivel. El progreso cuenta respuestas y aciertos por separado; no cuenta visitas ni representa una insignia de dominio. Se guarda solamente la selección validada, con versión y firma de contenido, en `localStorage` del navegador cuando está disponible. Los datos dañados o incompatibles se ignoran, y si no se puede guardar la interfaz lo informa sin prometer persistencia. No hay cuentas, servidor, sincronización ni reinicio de claves ajenas.

Los recursos usan rutas relativas aptas para GitHub Pages bajo una subruta. La portada usa `textContent` para títulos y resultados; no inserta HTML editorial ni ejecuta endpoints PHP. El catálogo principal sólo presenta semanas vigentes; `pages` mantiene enlaces al cuaderno y al material archivado de otras asignaturas.

El diálogo de ejemplo de las lecciones se abre con su botón, se cierra con Escape o sus acciones y conserva el foco dentro mientras está abierto. `tests/browser-modal.js` verifica apertura, teclado, cierre y devolución de foco sobre una vista local en el puerto 4188.
