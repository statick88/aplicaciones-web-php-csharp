# Sitio estático de prácticas

La interfaz reproduce la composición oscura de `curso_net/site` y del recorrido autorizado `curso_net/design/aprende-csharp-dotnet/01-recorrido.html`: encabezado, hero radial, catálogo de dos columnas y lectura con barra lateral. Se adapta a **Programación Web**, PHP y .NET; no conserva la meta de certificación.

El diseño utiliza todo el ancho disponible, con 1rem de margen interior lateral. La lección ocupa su columna completa; los párrafos y listas limitan su medida a 72ch para facilitar la lectura, sin reducir el espacio de código, tablas ni figuras. El índice prioriza la semana de la lección abierta y pliega las otras semanas y el material complementario; este último se abre al consultar una de sus páginas. Las secciones plegadas se pueden abrir también en móvil.

En cada lección, **Ocultar temas** retira el índice y amplía el contenido a todo el ancho disponible. **Mostrar temas** restaura la navegación. El botón funciona con ratón, Enter o Espacio y comunica su estado con `aria-expanded`. La selección solo dura en la página actual; no modifica el progreso ni el almacenamiento. Sin JavaScript, los temas permanecen visibles y el botón no aparece. El comportamiento está aislado en `lesson-layout.mjs`, que también copia el constructor.

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
playwright-cli run-code --filename tests/browser-design.js
```

Tras generar `assessments.json` y las lecciones con cuestionarios, `browser-progress.js` crea un contexto aislado: responde una opción errónea, recarga, cambia a la correcta y comprueba el resumen de portada. No borra el almacenamiento de un perfil humano. El mismo archivo puede ejecutarse como función de página desde la herramienta Playwright del entorno. `browser-layout.js` comprueba el ancho del contenedor, el espacio restante de las lecciones y la ausencia de desborde horizontal; también oculta y restaura los temas con teclado, verifica el foco y el estado accesible, y comprueba que la lección ocupe todo el ancho al ocultarlos.

Cada lección reúne sus preguntas en un diálogo nativo al pulsar **Abrir cuestionario**. Se muestra una pregunta por vez, con posición **Pregunta N de T** y botones **Anterior** y **Siguiente**, desactivados en los extremos. Al cambiar de pregunta el foco pasa a su contenido; las respuestas se conservan al retroceder y al cerrar. El encabezado con **Cerrar cuestionario** y la navegación permanecen visibles al desplazarse. El progreso destaca respuestas y aciertos; el aviso de almacenamiento queda en segundo plano. El foco entra al modal y vuelve al botón al cerrarlo con **Cerrar cuestionario** o Escape. El contenido se desplaza dentro del diálogo en pantallas pequeñas. Sin soporte de diálogos, las preguntas permanecen en la página; si falla la carga del banco, se conserva el aviso con las opciones desactivadas. `browser-progress.js` comprueba apertura, cierre, foco y conservación de respuestas además del progreso.

Las evaluaciones son únicamente de opción múltiple: cada selección muestra `Correcta` o `Por revisar`, la justificación de la alternativa y su objetivo/nivel. El progreso cuenta respuestas y aciertos por separado; no cuenta visitas ni representa una insignia de dominio. Se guarda solamente la selección validada, con versión y firma de contenido, en `localStorage` del navegador cuando está disponible. Los datos dañados o incompatibles se ignoran, y si no se puede guardar la interfaz lo informa sin prometer persistencia. No hay cuentas, servidor, sincronización ni reinicio de claves ajenas.

Los recursos usan rutas relativas aptas para GitHub Pages bajo una subruta. La portada usa `textContent` para títulos y resultados; no inserta HTML editorial ni ejecuta endpoints PHP. El catálogo principal sólo presenta semanas vigentes; `pages` mantiene enlaces al cuaderno y al material archivado de otras asignaturas.

El diálogo de ejemplo de las lecciones se abre con su botón, se cierra con Escape o sus acciones y conserva el foco dentro mientras está abierto. `tests/browser-modal.js` verifica apertura, teclado, cierre y devolución de foco sobre una vista local en el puerto 4188.
