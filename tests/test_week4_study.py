"""Publication contracts for the Week 4 study-only units."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WeekFourStudyTests(unittest.TestCase):
    def test_two_active_study_lessons_have_matched_six_question_banks(self):
        catalog = json.loads((ROOT / "course/catalog.json").read_text())
        self.assertGreaterEqual(catalog["currentWeek"], 4)
        module = next(item for item in catalog["modules"] if item["week"] == 4)
        self.assertEqual(len(module["units"]), 2)
        bank = json.loads((ROOT / "course/questions-web.json").read_text())
        expected = (
            ("01-cadenas-regex-arreglos", "web-w4c1-"),
            ("02-poo-capas-parcial-i", "web-w4c2-"),
        )
        for filename, prefix in expected:
            with self.subTest(lesson=filename):
                href = f"subjects/aplicaciones-web/semana-04/{filename}.html"
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

    def test_lessons_pin_week_four_coverage_and_study_only_boundary(self):
        first = (ROOT / "ebook/subjects/aplicaciones-web/semana-04/01-cadenas-regex-arreglos.md").read_text()
        second = (ROOT / "ebook/subjects/aplicaciones-web/semana-04/02-poo-capas-parcial-i.md").read_text()
        for token in ("mb_strlen", "UTF-8", "preg_match", "array_map", "DataAnnotations", "LINQ"):
            self.assertIn(token, first)
        for token in ("encapsulamiento", "interfaz", "PDO", "inyección de dependencias", "MVC", "Entity Framework"):
            self.assertIn(token, second)
        self.assertIn("no constituye una evaluación oficial", second)
        self.assertIn("ejemplos instructivos", first)
        self.assertIn("ejemplos instructivos", second)


if __name__ == "__main__":
    unittest.main()
