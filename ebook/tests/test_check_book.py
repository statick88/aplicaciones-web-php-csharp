"""Public CLI checks; fixtures and mutations stay in disposable system temp dirs."""
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/check_book.py"
PAGES = ("index", "chapters/01-web-foundations", "chapters/02-variables-types-scope",
         "chapters/03-week1-practice-review", "chapters/04-development-environment",
         "answers", "references")


class BookChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.book = Path(self.temp.name) / "ebook"
        (self.book / "scripts").mkdir(parents=True)
        shutil.copyfile(SCRIPT, self.book / "scripts/check_book.py")
        self.put("_quarto.yml", "book:\n  chapters:\n" + "".join(
            f"    - {page}.qmd\n" for page in PAGES))
        self.put("references.bib", "")
        self.put("assets/styles.css", "")
        for name in ("request-response", "runtime-comparison", "scope"):
            self.put(f"assets/{name}.svg", '<svg xmlns="http://www.w3.org/2000/svg"/>')
        for page in PAGES:
            self.put(f"{page}.qmd", "# Texto\n")
            prefix = "../" if "/" in page else ""
            self.put(f"_book/{page}.html", '<link rel="stylesheet" href="' + prefix +
                     'bootstrap.css" data-mode="dark"><link rel="stylesheet" href="' + prefix +
                     'bootstrap-icons.css"><h1 id="texto">Texto</h1>')
        self.put("_book/bootstrap-icons.css", "/* Icons are not the theme. */")
        self.put("_book/bootstrap.css", ":root{--bs-body-bg:#002b36;--bs-body-color:#adb5bd;}")
        self.put("_book/aplicaciones-web-php-csharp-semana1.pdf", b"%PDF-1.7\nfixture\n%%EOF\n")

    def put(self, name, text):
        path = self.book / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text if isinstance(text, bytes) else text.encode())

    def check(self, *args):
        before = {p.relative_to(self.book): p.read_bytes() for p in self.book.rglob("*") if p.is_file()}
        result = subprocess.run([sys.executable, str(self.book / "scripts/check_book.py"), *args],
                                capture_output=True, text=True)
        after = {p.relative_to(self.book): p.read_bytes() for p in self.book.rglob("*") if p.is_file()}
        self.assertEqual(before, after)
        return result

    def rejected(self, message):
        result = self.check("--rendered")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "Comprobación estructural fallida:\n- " + message + "\n")

    def test_existing_source_and_rendered_success(self):
        for args in ((), ("--rendered",)):
            with self.subTest(args=args):
                result = self.check(*args)
                self.assertEqual((result.returncode, result.stdout, result.stderr),
                                 (0, "Comprobación estructural correcta.\n", ""))

    def test_all_configured_pages_required(self):
        for page in ("answers", "references", "appendix"):
            with self.subTest(page=page):
                self.set_extra_page(page)
                path = self.book / f"_book/{page}.html"
                saved = path.read_bytes() if path.exists() else None
                if saved is not None:
                    path.unlink()
                self.rejected(f"falta artefacto renderizado: ebook/_book/{page}.html")
                self.put(f"_book/{page}.html", saved or b"<h1>Appendix</h1>")

    def set_extra_page(self, page):
        if page == "appendix":
            config = self.book / "_quarto.yml"
            config.write_text(config.read_text() + "    - appendix.qmd\n")
            self.put("appendix.qmd", "# Appendix\n")

    def test_answers_images_checked(self):
        self.put("_book/answers.html", '<img src="bootstrap.css">')
        self.rejected("imagen HTML sin texto alternativo en answers.html: bootstrap.css")

    def test_local_targets_and_anchors(self):
        for target, message in (("missing.html", "destino local inexistente"),
                                ("references.html#missing", "ancla local inexistente"),
                                ("#missing", "ancla local inexistente"),
                                ("missing.png", "destino local inexistente")):
            with self.subTest(target=target):
                self.put("_book/answers.html", f'<a href="{target}">Ir</a>')
                self.rejected(f"{message} en answers.html: {target}")

    def test_existing_local_links_external_links_and_encoded_anchor(self):
        self.put("_book/answers.html", '<h1 id="sección">Texto</h1>'
                 '<a href="#secci%C3%B3n">Ir</a><a href="references.html?x=1#texto">Ref</a>'
                 '<a href="https://example.org/no-network">Externo</a>'
                 '<img alt="Texto" src="bootstrap.css"><script src="bootstrap.css"></script>')
        self.assertEqual(self.check("--rendered").returncode, 0)

    def test_pdf_signature(self):
        self.put("_book/aplicaciones-web-php-csharp-semana1.pdf", "not a PDF")
        self.rejected("firma PDF inválida: ebook/_book/aplicaciones-web-php-csharp-semana1.pdf")

    def test_default_solar_mode_and_palette(self):
        for mode, css in (("light", "#002b36"), ("dark", "#ffffff")):
            with self.subTest(mode=mode):
                self.put("_book/index.html", f'<link rel="stylesheet" href="bootstrap-probe.css" data-mode="{mode}">')
                self.put("_book/bootstrap-probe.css", f":root{{--bs-body-bg:{css};--bs-body-color:#adb5bd;}}")
                self.rejected("tema Solar oscuro no predeterminado en index.html")


if __name__ == "__main__":
    unittest.main()
