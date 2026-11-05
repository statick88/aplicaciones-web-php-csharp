"""Structural contract for the Web multiple-choice question bank."""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
BANK_PATH = ROOT / "course/questions-web.json"
CATALOG_PATH = ROOT / "course/catalog.json"


class QuestionsWebTests(unittest.TestCase):
    def setUp(self):
        self.bank = json.loads(BANK_PATH.read_text(encoding="utf-8"))
        self.catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))

    def test_bank_has_the_frozen_schema_and_catalogued_pages(self):
        self.assertEqual(set(self.bank), {"schemaVersion", "pages"})
        self.assertEqual(self.bank["schemaVersion"], 1)
        catalog_hrefs = {page["href"] for page in self.catalog["pages"]}
        seen = set()
        for page in self.bank["pages"]:
            self.assertEqual(set(page), {"href", "questions"})
            self.assertIn(page["href"], catalog_hrefs)
            self.assertNotIn(page["href"], seen)
            seen.add(page["href"])
            self.assertTrue(page["questions"])

    def test_questions_have_unique_ids_and_actionable_feedback(self):
        ids = set()
        for page in self.bank["pages"]:
            for question in page["questions"]:
                self.assertEqual(
                    set(question) - {"id", "prompt", "options", "correctIndex", "feedback", "objective", "level", "code"},
                    set(),
                )
                self.assertRegex(question["id"], r"^web-[a-z0-9-]+$")
                self.assertNotIn(question["id"], ids)
                ids.add(question["id"])
                self.assertTrue(question["prompt"])
                self.assertIn(len(question["options"]), (3, 4))
                self.assertTrue(all(isinstance(option, str) and option for option in question["options"]))
                self.assertEqual(len(question["feedback"]), len(question["options"]))
                self.assertTrue(all(isinstance(item, str) and item for item in question["feedback"]))
                self.assertIsInstance(question["correctIndex"], int)
                self.assertIn(question["correctIndex"], range(len(question["options"])))
                self.assertTrue(question["objective"])
                self.assertIn(question["level"], {"comprender", "aplicar", "analizar"})

    def test_each_question_has_one_marker_in_its_catalog_source(self):
        by_href = {page["href"]: page["source"] for page in self.catalog["pages"]}
        for page in self.bank["pages"]:
            source = (ROOT / by_href[page["href"]]).read_text(encoding="utf-8")
            markers = re.findall(r"<!-- quiz: (web-[a-z0-9-]+) -->", source)
            expected = [question["id"] for question in page["questions"]]
            self.assertCountEqual(markers, expected)
            self.assertEqual(len(markers), len(set(markers)))

    def test_legacy_review_and_week2_anchors_remain(self):
        review = (ROOT / "ebook/chapters/03-week1-practice-review.md").read_text(encoding="utf-8")
        answers = (ROOT / "ebook/answers.md").read_text(encoding="utf-8")
        for number in range(1, 11):
            self.assertIn(f'id="p{number}"', review)
            self.assertIn(f"#p{number}-respuesta", review)
            self.assertIn(f"#p{number}", answers)
        for class_number in (1, 2):
            source = (ROOT / f"ebook/subjects/aplicaciones-web/semana-02/0{class_number}-{'tipos-cliente' if class_number == 1 else 'formularios-get-post'}.md").read_text(encoding="utf-8")
            self.assertIn(f"s2c{class_number}-ejercicios", source)
            self.assertIn(f"s2c{class_number}-respuestas", source)
            for number in range(1, 6):
                self.assertIn(f"s2c{class_number}-ej-{number}", source)
                self.assertIn(f"s2c{class_number}-r-{number}", source)


if __name__ == "__main__":
    unittest.main()
