import re
import struct
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "_quarto.yml"
SUBJECTS = {
    "Aplicaciones Web": "subjects/aplicaciones-web.qmd",
    "Diseño y Arquitectura de Software": "subjects/arquitectura-software.qmd",
    "Gestión Empresarial y Emprendimiento": "subjects/gestion-empresarial-emprendimiento.qmd",
    "Inteligencia Artificial": "subjects/inteligencia-artificial.qmd",
    "Inteligencia de Negocios": "subjects/inteligencia-negocios.qmd",
    "Proyectos Informáticos": "subjects/proyectos-informaticos.qmd",
}

class SubjectIndexesAndTypography(unittest.TestCase):
    def test_shared_bibliography_keeps_entries_for_unchanged_chapters(self):
        references = (ROOT / "references.qmd").read_text()
        self.assertRegex(references, r"(?m)^nocite:\s*['\"]@\*['\"]\s*$")
        self.assertIn("::: {#refs}", references)


    def test_portal_and_navigation_expose_six_independent_official_indexes(self):
        portal = (ROOT / "index.qmd").read_text()
        config = CONFIG.read_text()
        for official_name, relative_path in SUBJECTS.items():
            with self.subTest(subject=official_name):
                page = ROOT / relative_path
                self.assertTrue(page.is_file(), relative_path)
                text = page.read_text()
                self.assertRegex(text, rf"(?m)^# {re.escape(official_name)}$")
                self.assertIn(f"]({relative_path})", portal)
                self.assertIn(relative_path, config)


    def test_unavailable_subject_indexes_are_honest_and_do_not_mix_web_answers(self):
        unavailable = set(SUBJECTS.values()) - {
            "subjects/aplicaciones-web.qmd",
            "subjects/arquitectura-software.qmd",
        }
        for relative_path in unavailable:
            with self.subTest(page=relative_path):
                text = (ROOT / relative_path).read_text().lower()
                normalized = " ".join(text.replace("**", "").split())
                self.assertIn("no hay capítulos de estudio verificados y redactados", normalized)
                self.assertNotIn("answers.qmd", text)
                self.assertNotIn("respuestas de aplicaciones web", text)
