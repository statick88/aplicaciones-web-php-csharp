# Fuentes editables de las figuras

Estos ocho SVG conservan el texto, los títulos y las descripciones originales.
Se editan aquí, con la familia **FiraCode Nerd Font** y sus variantes Regular/Bold
incluidas sin modificar en `../assets/fonts/fira-code-nerd/` bajo SIL OFL 1.1.

El exportador genera los SVG para `../assets/` como contornos vectoriales: muestran
Fira incluso si el lector no tiene la fuente instalada y no cargan fuentes externas.
En esos archivos finales las letras no son texto seleccionable; el original textual
se conserva en este directorio y el texto alternativo/caption del libro no cambia.
Las capturas PNG reales de DevTools no se procesan ni se reconstruyen.

Desde la raíz del repositorio:

```bash
python3 ebook/scripts/render_diagram_fonts.py
python3 ebook/scripts/render_diagram_fonts.py --check
```

La regeneración local necesita `rsvg-convert` y `fc-match` ya disponibles. No instala
paquetes ni fuentes globales: crea una configuración Fontconfig temporal dentro de
`.atl/` que solo referencia las dos fuentes incluidas. Valida todas las entradas y
prepara todos los resultados antes de reemplazar los ocho SVG de publicación.
`--check` solo valida metadatos, fuentes, etiquetas y hashes; no escribe archivos.
GitHub Pages consume los SVG ya generados y no necesita ejecutar este exportador.

El MCP oficial de Excalidraw fuerza **Excalifont** en su
[código publicado](https://github.com/excalidraw/excalidraw-mcp/blob/157aa23ceb1976008aadc89eb05e3444060f09d6/src/mcp-app.tsx#L42-L53). No se
presentan estos contornos como texto Fira editable nativo en ese editor, ni se
rebautiza otra fuente como Fira. Esta limitación fue aceptada explícitamente para
la publicación; no cambia la tipografía del texto del ebook.
