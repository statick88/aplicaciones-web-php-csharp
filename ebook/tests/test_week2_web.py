"""Week 2 chapters must be reachable in the book and subject navigation."""
from pathlib import Path
import re
import unittest

BOOK = Path(__file__).resolve().parents[1]
CHAPTERS = (
    "subjects/aplicaciones-web/semana-02/01-tipos-cliente.qmd",
    "subjects/aplicaciones-web/semana-02/02-formularios-get-post.qmd",
)


class Week2WebTests(unittest.TestCase):
    def test_both_classes_are_configured_and_linked_from_subject(self):
        config = (BOOK / "_quarto.yml").read_text()
        subject = (BOOK / "subjects/aplicaciones-web.qmd").read_text()
        for chapter in CHAPTERS:
            with self.subTest(chapter=chapter):
                self.assertIn(chapter, config)
                self.assertIn(chapter.removeprefix("subjects/"), subject)
        self.assertIn("## Navegación de la Semana 2", subject)

    def test_chapters_have_portable_questions_answers_and_language_examples(self):
        for index, chapter in enumerate(CHAPTERS, 1):
            with self.subTest(chapter=chapter):
                source = (BOOK / chapter).read_text()
                ids = re.findall(r"\{#([^}]+)\}", source)
                self.assertEqual(len(ids), len(set(ids)))
                self.assertNotIn("<span", source)
                self.assertIn("```php", source)
                self.assertIn("```csharp", source)
                self.assertIn(f"s2c{index}-ejercicios", ids)
                self.assertIn(f"s2c{index}-respuestas", ids)
                for number in range(1, 6):
                    self.assertIn(f"s2c{index}-ej-{number}", ids)
                    self.assertIn(f"s2c{index}-r-{number}", ids)
                    self.assertIn(f"](#s2c{index}-ej-{number})", source)
                for target in re.findall(r"\]\(#([^)]+)\)", source):
                    self.assertIn(target, ids)


if __name__ == "__main__":
    unittest.main()
