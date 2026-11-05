# Cuaderno de estudio y práctica

Las fuentes editoriales son archivos Markdown editables (`.md`). El sitio estático se genera sin Quarto; los ejemplos y recursos permanecen junto a sus lecciones.

## Editar y añadir contenido

1. Edite una página Markdown bajo `ebook/` y conserve sus enlaces, IDs, texto alternativo y bloques `:::` cuando existan.
2. Al añadir una página, registre su `source`, `href` y título en `course/catalog.json`. `source` usa la ruta `ebook/*.md`; `href` publica la misma ruta sin `ebook/` y con `.html`. La excepción es `ebook/index.md`, publicado como `cuaderno.html`.
3. Incluya una unidad solo cuando corresponda a una semana confirmada. Las páginas de apoyo y el archivo de otras asignaturas siguen en el catálogo sin inventar semanas futuras.

## Generar el sitio

Desde la raíz del repositorio:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-docs.txt
python3 tools/build_site.py --output _site
```

El resultado es HTML estático. GitHub Pages no ejecuta PHP, .NET ni los servicios de los ejemplos; siga las instrucciones locales de cada práctica cuando corresponda. Las evaluaciones se definen en los bancos de preguntas del curso y se insertan mediante marcadores editoriales; el constructor valida su esquema, sus marcadores y sus referencias antes de publicar. La interacción es de opción múltiple y guarda solo selecciones válidas en el almacenamiento local del navegador cuando está disponible.
