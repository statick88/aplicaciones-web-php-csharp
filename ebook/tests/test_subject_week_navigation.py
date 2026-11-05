"""Week navigation checks for the Aplicaciones Web subject index.

The subject page is the per-week entry point: it must link theory, examples,
exercises, the self-assessment (with its answers) and delivery evidence,
reusing the existing transversal HTTP pages instead of copying their content.
Also pins the PDF output name and the existence of every linked local page.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WEB_INDEX = ROOT / "subjects" / "aplicaciones-web.md"
CATALOG = ROOT.parent / "course" / "catalog.json"

# Theory, practice/review and optional environment chapters.
# Examples: transversal DevTools lab. Reference: transversal HTTP tables.
# Self-assessment anchor inside chapter 03, answers in answers.md.
# Delivery evidence is described without treating a personal repository as a source.
REQUIRED_LINKS = [
    "../chapters/01-web-foundations.md",
    "../chapters/02-variables-types-scope.md",
    "../chapters/03-week1-practice-review.md",
    "../chapters/04-development-environment.md",
    "aplicaciones-web/laboratorio-http-php.md",
    "aplicaciones-web/consulta-http.md",
    "../chapters/03-week1-practice-review.md#autoevaluacion-semana1",
    "../answers.md",
]


class WeekNavigationTests(unittest.TestCase):
    def test_links_theory_examples_exercises_self_check_and_delivery(self) -> None:
        text = WEB_INDEX.read_text(encoding="utf-8")
        for link in REQUIRED_LINKS:
            with self.subTest(link=link):
                self.assertIn(link, text)
        self.assertIn("| Entregas | Sitio personal y calculadora", text)
        self.assertNotIn("https://github.com/statick88", text)

    def test_every_linked_local_markdown_target_exists(self) -> None:
        text = WEB_INDEX.read_text(encoding="utf-8")
        targets = re.findall(r"\]\(([^)\s]+\.md)(?:#[^)\s]*)?\)", text)
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

    def test_catalog_keeps_every_week_navigation_target_public(self) -> None:
        catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
        sources = {page["source"] for page in catalog["pages"]}
        for target in REQUIRED_LINKS:
            source = (ROOT / "subjects" / target.split("#", 1)[0]).resolve()
            with self.subTest(target=target):
                self.assertIn(str(source.relative_to(ROOT.parent)), sources)


if __name__ == "__main__":
    unittest.main()
