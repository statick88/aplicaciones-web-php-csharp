"""Publication contracts for the Week 5 study-only units."""
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class WeekFiveStudyTests(unittest.TestCase):
    def test_two_active_study_lessons_have_matched_six_question_banks(self):
        catalog = json.loads((ROOT / "course/catalog.json").read_text())
        self.assertEqual(catalog["currentWeek"], 5)
        module = next(item for item in catalog["modules"] if item["week"] == 5)
        self.assertEqual(len(module["units"]), 2)
        bank = json.loads((ROOT / "course/questions-web.json").read_text())
        expected = (
            ("01-tablas-archivos", "web-w5c1-"),
            ("02-insert-select", "web-w5c2-"),
        )
        for filename, prefix in expected:
            with self.subTest(lesson=filename):
                href = f"subjects/aplicaciones-web/semana-05/{filename}.html"
                self.assertIn(href, {unit["href"] for unit in module["units"]})
                page = next(item for item in catalog["pages"] if item["href"] == href)
                source = (ROOT / page["source"]).read_text()
                assessment = next(item for item in bank["pages"] if item["href"] == href)
                self.assertEqual(len(assessment["questions"]), 6)
                for question in assessment["questions"]:
                    self.assertTrue(question["id"].startswith(prefix))
                    self.assertEqual(source.count(f'<!-- quiz: {question["id"]} -->'), 1)
                    self.assertIn(len(question["options"]), (3, 4))
                    self.assertEqual(len(question["feedback"]), len(question["options"]))

    def test_lessons_pin_week_five_coverage_and_study_only_boundary(self):
        first = (ROOT / "ebook/subjects/aplicaciones-web/semana-05/01-tablas-archivos.md").read_text()
        second = (ROOT / "ebook/subjects/aplicaciones-web/semana-05/02-insert-select.md").read_text()
        for token in ("DDL", "CRUD", "ALTER TABLE", "FormData", "PHP", ".NET"):
            self.assertIn(token, first)
        for token in ("PDO", "EF Core", "transacción", "JOIN", "paginación", "Postman"):
            self.assertIn(token, second)
        self.assertIn("ejemplos instructivos", first)
        self.assertIn("ejemplos instructivos", second)
        self.assertIn("no se ejecutan", first)
        self.assertIn("no se ejecutan", second)


if __name__ == "__main__":
    unittest.main()
