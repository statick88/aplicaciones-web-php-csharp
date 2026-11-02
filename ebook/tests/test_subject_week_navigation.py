"""Week navigation checks for the Aplicaciones Web subject index.

The subject page is the per-week entry point: it must link theory, examples,
exercises, the self-assessment (with its answers) and the published delivery,
reusing the existing transversal HTTP pages instead of copying their content.
Also pins the PDF output name and the existence of every linked local page.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WEB_INDEX = ROOT / "subjects" / "aplicaciones-web.qmd"
CONFIG = ROOT / "_quarto.yml"

# Theory, practice/review and optional environment chapters.
# Examples: transversal DevTools lab. Reference: transversal HTTP tables.
# Self-assessment anchor inside chapter 03, answers in answers.qmd.
# Delivery: the published Semana 1 repository.
REQUIRED_LINKS = [
    "../chapters/01-web-foundations.qmd",
    "../chapters/02-variables-types-scope.qmd",
    "../chapters/03-week1-practice-review.qmd",
    "../chapters/04-development-environment.qmd",
    "aplicaciones-web/laboratorio-http-php.qmd",
    "aplicaciones-web/consulta-http.qmd",
    "../chapters/03-week1-practice-review.qmd#autoevaluacion-semana1",
    "../answers.qmd",
    "https://github.com/statick88/aplicaciones-web-semana1",
]


class WeekNavigationTests(unittest.TestCase):
    def test_links_theory_examples_exercises_self_check_and_delivery(self) -> None:
        text = WEB_INDEX.read_text(encoding="utf-8")
        for link in REQUIRED_LINKS:
            with self.subTest(link=link):
                self.assertIn(link, text)

    def test_every_linked_local_qmd_target_exists(self) -> None:
        text = WEB_INDEX.read_text(encoding="utf-8")
        targets = re.findall(r"\]\(([^)\s]+\.qmd)(?:#[^)\s]*)?\)", text)
        self.assertTrue(targets, "subject index must link local pages")
        for target in targets:
            with self.subTest(target=target):
                self.assertTrue(
                    (ROOT / "subjects" / target).resolve().is_file(), target
                )

    def test_reuses_transversal_http_pages_instead_of_copying_them(self) -> None:
        text = WEB_INDEX.read_text(encoding="utf-8").lower()
        # Distinctive phrases owned by the transversal pages.
        self.assertNotIn("idempotencia", text)
        self.assertNotIn("cinco métodos", text)

    def test_pdf_output_name_stays_compatible(self) -> None:
        config = CONFIG.read_text(encoding="utf-8")
        self.assertIn("output-file: aplicaciones-web-php-csharp-semana1", config)


if __name__ == "__main__":
    unittest.main()
