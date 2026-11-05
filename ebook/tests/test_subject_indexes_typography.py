import json
import re
import struct
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT.parent / "course" / "catalog.json"
SUBJECTS = {
    "Aplicaciones Web": "subjects/aplicaciones-web.md",
    "Diseño y Arquitectura de Software": "subjects/arquitectura-software.md",
    "Gestión Empresarial y Emprendimiento": "subjects/gestion-empresarial-emprendimiento.md",
    "Inteligencia Artificial": "subjects/inteligencia-artificial.md",
    "Inteligencia de Negocios": "subjects/inteligencia-negocios.md",
    "Proyectos Informáticos": "subjects/proyectos-informaticos.md",
}
FONT_DIR = ROOT / "assets/fonts/fira-code-nerd"


def read_name_records(path):
    data = path.read_bytes()
    num_tables = struct.unpack(">H", data[4:6])[0]
    tables = {}
    for index in range(num_tables):
        start = 12 + index * 16
        tag, _, offset, length = struct.unpack(">4sIII", data[start : start + 16])
        tables[tag] = data[offset : offset + length]
    table = tables[b"name"]
    count, string_offset = struct.unpack(">HH", table[2:6])
    values = []
    for index in range(count):
        start = 6 + index * 12
        platform, _, _, name_id, length, offset = struct.unpack(">HHHHHH", table[start : start + 12])
        if name_id not in {1, 2}:
            continue
        raw = table[string_offset + offset : string_offset + offset + length]
        values.append((name_id, raw.decode("utf-16-be" if platform in {0, 3} else "latin-1")))
    return values


class SubjectIndexesAndTypography(unittest.TestCase):
    def test_shared_bibliography_keeps_its_render_target(self):
        references = (ROOT / "references.md").read_text()
        self.assertIn("# Fuentes y política de uso", references)
        self.assertIn("::: {#refs}", references)

    def test_portal_and_catalog_expose_six_independent_official_indexes(self):
        portal = (ROOT / "index.md").read_text()
        catalog = json.loads(CATALOG.read_text())
        sources = {page["source"] for page in catalog["pages"]}
        for official_name, relative_path in SUBJECTS.items():
            with self.subTest(subject=official_name):
                page = ROOT / relative_path
                self.assertTrue(page.is_file(), relative_path)
                text = page.read_text()
                self.assertRegex(text, rf"(?m)^# {re.escape(official_name)}$")
                self.assertIn(f"]({relative_path})", portal)
                self.assertIn(f"ebook/{relative_path}", sources)

    def test_unavailable_subject_indexes_are_honest_and_do_not_mix_web_answers(self):
        unavailable = set(SUBJECTS.values()) - {
            "subjects/aplicaciones-web.md",
            "subjects/arquitectura-software.md",
        }
        for relative_path in unavailable:
            with self.subTest(page=relative_path):
                text = (ROOT / relative_path).read_text().lower()
                normalized = " ".join(text.replace("**", "").split())
                self.assertIn("no hay capítulos de estudio verificados y redactados", normalized)
                self.assertNotIn("answers.md", text)
                self.assertNotIn("respuestas de aplicaciones web", text)

    def test_bundled_fira_fonts_license_and_portable_typst_configuration(self):
        regular = FONT_DIR / "FiraCodeNerdFont-Regular.ttf"
        bold = FONT_DIR / "FiraCodeNerdFont-Bold.ttf"
        for font, style in ((regular, "Regular"), (bold, "Bold")):
            with self.subTest(font=font.name):
                self.assertTrue(font.is_file())
                records = read_name_records(font)
                self.assertIn((1, "FiraCode Nerd Font"), records)
                self.assertIn((2, style), records)

        license_text = (FONT_DIR / "LICENSE.txt").read_text()
        self.assertIn("SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007", license_text)
        self.assertIn("PERMISSION & CONDITIONS", license_text)
        self.assertIn("TERMINATION", license_text)
        attribution = (FONT_DIR / "README.md").read_text()
        self.assertIn("FiraCode Project Authors", attribution)
        self.assertIn("SIL Open Font License 1.1", attribution)

        readme = (ROOT / "README.md").read_text()
        self.assertIn("Markdown editables", readme)
        self.assertIn("course/catalog.json", readme)

    def test_proportional_book_text_keeps_fira_code_and_justified_prose(self):
        css = (ROOT / "assets/styles.css").read_text()
        self.assertIn("@font-face", css)
        self.assertRegex(css, r"\.csl-entry\s*\{[^}]*overflow-wrap:\s*anywhere")
        self.assertRegex(css, r"main\.content table\s*\{[^}]*overflow-x:\s*auto")
        self.assertRegex(css, r"main\.content :not\(pre\) > code\s*\{[^}]*white-space:\s*normal")
        self.assertIn("FiraCodeNerdFont-Regular.ttf", css)
        self.assertIn("FiraCodeNerdFont-Bold.ttf", css)
        self.assertNotRegex(css, r"(?:body|h[1-6])[^\{]*\{[^}]*font-family:\s*\"FiraCode Nerd Font\"")
        self.assertRegex(css, r"code,\s*pre,\s*kbd,\s*samp\s*\{[^}]*font-family:\s*\"FiraCode Nerd Font\"")
        self.assertRegex(css, r"main[^,{]*p[^\{]*\{[^}]*text-align:\s*justify")
        self.assertNotRegex(css, r"(?:code|pre|table|nav)[^\{]*\{[^}]*text-align:\s*justify")

        typst = (ROOT / "assets/typography.typ").read_text()
        self.assertNotIn('#set text(font: "FiraCode Nerd Font")', typst)
        self.assertNotIn('#show heading: set text(font: "FiraCode Nerd Font")', typst)
        self.assertIn('#show raw: set text(font: "FiraCode Nerd Font")', typst)
        self.assertIn("#set par(justify: true)", typst)


if __name__ == "__main__":
    unittest.main()
