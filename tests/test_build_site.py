"""Public build_site CLI tests using independent disposable fixtures."""
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "tools/build_site.py"

class BuildSite(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "tools").mkdir(); shutil.copy2(SOURCE, self.root / "tools/build_site.py")
        (self.root / "course").mkdir(); (self.root / "ebook/assets").mkdir(parents=True)
        (self.root / "site").mkdir()
        (self.root / "ebook/downloads").mkdir()
        (self.root / "ebook/downloads/aplicaciones-web-php-csharp-semana1.pdf").write_bytes(b"%PDF-1.7\nfixture\n")
        (self.root / "requirements-docs.txt").write_text("Markdown==3.8.2\n")
        (self.root / "site/page.html").write_text("<title>{{title}}</title><a href=\"{{root}}index.html#catalogo\">Recorrido</a><nav>{{navigation}}</nav><main><h1{{heading_id}}>{{title}}</h1>{{content}}</main><footer>{{pagination}} {{week}}</footer>")
        (self.root / "site/index.html").write_text('<div id="catalogo"></div><div id="app"><input id="search"></div>')
        (self.root / "site/app.mjs").write_text("fetch('./course.json')")
        (self.root / "site/styles.css").write_text("body{}")
        (self.root / "site/course-utils.mjs").write_text("export {}")
        (self.root / "ebook/assets/diagram.svg").write_text("<svg/>")
        (self.root / "ebook/assets/plain.svg").write_text("<svg/>")
        (self.root / "ebook/references.bib").write_text('@misc{source,\n title = {Source},\n author = {Author},\n year = {2026}\n}\n')
        (self.root / "ebook/index.md").write_text("---\ntitle: Privado\nnocite: '@source'\n---\n# Inicio {#inicio}\n\n[Lección](chapters/one.md#lesson) [@source;\n@source]\n")
        (self.root / "ebook/references.md").write_text("# Referencias\n\n<span id=\"ref-source\">Source</span>\n")
        (self.root / "ebook/chapters").mkdir(); (self.root / "ebook/chapters/one.md").write_text("# Lección {#lesson}\n\n[Inicio](../index.md#inicio)\n\n::: {.callout-note}\n## Nota\n\nContenido **Markdown**.\n:::\n\n::: {.table-responsive tabindex=\"0\" role=\"region\" aria-label=\"Tabla de prueba\"}\n\n|a|b|\n|-|-|\n|1|2|\n\n:::\n\n![Texto](../assets/diagram.svg){fig-alt=Alternativo fig-cap=Figura}\n\n![Simple](../assets/plain.svg)\n")
        catalog={"schemaVersion":1,"title":"Curso","currentWeek":2,"modules":[{"id":"w1","title":"W1","week":1,"description":"","units":[{"id":"one","title":"Lección","source":"ebook/chapters/one.md","href":"chapters/one.html","technologies":["php"]}]}],"pages":[{"source":"ebook/index.md","href":"cuaderno.html","title":"Inicio"},{"source":"ebook/references.md","href":"references.html","title":"Referencias"},{"source":"ebook/chapters/one.md","href":"chapters/one.html","title":"Lección"}]}
        (self.root / "course/catalog.json").write_text(json.dumps(catalog))
    def invoke(self, *args):
        return subprocess.run([sys.executable, str(self.root / "tools/build_site.py"), *args], cwd=self.root, text=True, capture_output=True)
    def test_builds_public_contract_and_validates_links(self):
        output=self.root / "output"; result=self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "Site output is valid.\n", ""))
        page=(output / "chapters/one.html").read_text()
        self.assertIn('<figure><img src="../assets/diagram.svg" alt="Alternativo"><figcaption>Figura</figcaption></figure>', page)
        self.assertIn('<img alt="Simple" src="../assets/plain.svg">', page)
        self.assertTrue((output / "assets/plain.svg").is_file())
        self.assertIn('href="references.html#ref-source"', (output / "cuaderno.html").read_text())
        self.assertIn('href="../cuaderno.html#inicio"', page)
        self.assertIn('href="../index.html#catalogo"', page)
        self.assertIn('<aside class="callout callout-note">', page)
        self.assertIn('<h2 id="nota">Nota</h2>', page)
        self.assertIn('<div aria-label="Tabla de prueba" class="table-responsive" role="region" tabindex="0">', page)
        self.assertIn('<table>', page)
        self.assertEqual(page.count("<h1"), 1)
        self.assertIn('<h1 id="lesson">Lección</h1>', page)
        self.assertIn('class="sidebar-module"', page)
        self.assertIn('class="sidebar-list"', page)
        self.assertIn('aria-current="page"', page)
        self.assertIn('Semana 1 · W1', page)
        cuaderno=(output / "cuaderno.html").read_text()
        before = {path.relative_to(output): path.read_bytes() for path in output.rglob("*") if path.is_file()}
        result = self.invoke("--output", str(output), "--check")
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "Site output is valid.\n", ""))
        self.assertEqual({path.relative_to(output): path.read_bytes() for path in output.rglob("*") if path.is_file()}, before)
        self.assertNotIn("Privado", cuaderno)
        self.assertEqual(cuaderno.count('class="citation"'), 2)
        self.assertIn('id="catalogo"', (output / "index.html").read_text())
        self.assertTrue((output / ".nojekyll").exists())
        self.assertEqual((output / "aplicaciones-web-php-csharp-semana1.pdf").read_bytes(), b"%PDF-1.7\nfixture\n")
        self.assertEqual((output / "styles.css").read_text(), "body{}")
        public=json.loads((output / "course.json").read_text()); self.assertNotIn("source", public["pages"][0]); self.assertNotIn("source", public["modules"][0]["units"][0])
    def test_preserves_bibliography_organization_names(self):
        (self.root / "ebook/references.bib").write_text('@misc{source,\n title = {Documentation},\n author = {{Microsoft}},\n year = {2026}\n}\n')
        output = self.root / "output"
        result = self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "Site output is valid.\n", ""))
        self.assertIn('id="ref-source">Microsoft. Documentation. 2026.', (output / "references.html").read_text())

    def test_build_still_creates_nested_output_directories(self):
        output = self.root / "new-parent" / "site"
        result = self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "Site output is valid.\n", ""))
        self.assertTrue((output / "chapters/one.html").is_file())

    def test_rejected_catalog_leaves_existing_output_unchanged(self):
        output=self.root / "output"; output.mkdir(); marker=output / "keep.txt"; marker.write_text("keep")
        catalog=json.loads((self.root / "course/catalog.json").read_text()); catalog["pages"].append(catalog["pages"][0])
        (self.root / "course/catalog.json").write_text(json.dumps(catalog))
        result=self.invoke("--output", str(output))
        self.assertEqual(result.returncode, 2); self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "build_site: duplicate catalog page: ebook/index.md\n")
        self.assertEqual(marker.read_text(), "keep")
    def test_check_rejects_missing_destination_without_mutating_output(self):
        output=self.root / "output"; output.mkdir(); (output / "index.html").write_text('<a href="missing.html">bad</a>')
        before=(output / "index.html").read_bytes(); result=self.invoke("--output", str(output), "--check")
        self.assertEqual(result.returncode, 2); self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "build_site: invalid output:\nindex.html: missing destination missing.html\n")
        self.assertEqual((output / "index.html").read_bytes(), before)

    def test_rejects_catalog_escapes_before_writing_output(self):
        output=self.root / "output"; output.mkdir(); (output / "counter.txt").write_text("7")
        outside=self.root / "outside.md"; outside.write_text("ordinary fixture")
        catalog=json.loads((self.root / "course/catalog.json").read_text())
        cases=("ebook/../outside.md", "ebook/link.md", "../outside.html", "/outside.html", "chapters/%2e%2e/outside.html")
        for value in cases:
            with self.subTest(value=value):
                changed=json.loads(json.dumps(catalog))
                if value.endswith(".md"):
                    changed["pages"][0]["source"]=value
                    if value.endswith("link.md"):
                        (self.root / "ebook/link.md").symlink_to(outside)
                else: changed["pages"][0]["href"]=value
                (self.root / "course/catalog.json").write_text(json.dumps(changed))
                result=self.invoke("--output", str(output))
                self.assertEqual((result.returncode, result.stdout, result.stderr), (2, "", "build_site: each page needs safe ebook/*.md source and safe relative *.html href\n"))
                self.assertEqual((output / "counter.txt").read_text(), "7")
                self.assertFalse((self.root / "outside.html").exists())

    def test_failed_build_preserves_existing_output(self):
        output=self.root / "output"; output.mkdir(); (output / "counter.txt").write_text("7")
        for text, error in (("# Inicio {#inicio}\n\n[@unknown]\n", "citation missing from references.bib: @unknown"), ("# Inicio {#inicio}\n\n[bad](missing.html)\n", "invalid output:\ncuaderno.html: missing destination missing.html")):
            with self.subTest(error=error):
                before={path.relative_to(output): path.read_bytes() for path in output.rglob("*") if path.is_file()}
                (self.root / "ebook/index.md").write_text(text)
                result=self.invoke("--output", str(output))
                self.assertEqual((result.returncode, result.stdout, result.stderr), (2, "", f"build_site: {error}\n"))
                self.assertEqual({path.relative_to(output): path.read_bytes() for path in output.rglob("*") if path.is_file()}, before)

    def test_publication_failure_preserves_existing_output(self):
        output=self.root / "output"; output.mkdir(); (output / "chapters").write_text("occupied"); (output / "counter.txt").write_text("7")
        before={path.relative_to(output): path.read_bytes() for path in output.rglob("*") if path.is_file()}
        result=self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (2, "", f"build_site: output path is not a directory: {output / 'chapters'}\n"))
        self.assertEqual({path.relative_to(output): path.read_bytes() for path in output.rglob("*") if path.is_file()}, before)
if __name__ == "__main__": unittest.main()
