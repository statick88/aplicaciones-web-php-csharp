"""Publication contracts for the confirmed Week 3 study units."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WeekThreeStudyTests(unittest.TestCase):
    def assert_active_lesson(self, filename, prefix):
        catalog = json.loads((ROOT / "course/catalog.json").read_text())
        module = next((item for item in catalog["modules"] if item["week"] == 3), None)
        self.assertIsNotNone(module, "Week 3 must be an active study module")
        self.assertEqual(catalog["currentWeek"], 3)
        href = f"subjects/aplicaciones-web/semana-03/{filename}.html"
        self.assertIn(href, {unit["href"] for unit in module["units"]})
        page = next(item for item in catalog["pages"] if item["href"] == href)
        source = (ROOT / page["source"]).read_text()
        bank = json.loads((ROOT / "course/questions-web.json").read_text())
        assessment = next(item for item in bank["pages"] if item["href"] == href)
        self.assertEqual(len(assessment["questions"]), 9)
        for question in assessment["questions"]:
            self.assertTrue(question["id"].startswith(prefix))
            self.assertEqual(source.count(f'<!-- quiz: {question["id"]} -->'), 1)
            self.assertEqual(len(question["options"]), 3)
            self.assertEqual(len(question["feedback"]), 3)
        return source

    def test_class_one_is_active_with_distinct_language_and_data_scopes(self):
        source = self.assert_active_lesson("01-constantes-operadores-datos", "web-w3c1-")
        self.assertIn("{#s3c1-lenguajes}", source)
        self.assertIn("{#s3c1-complemento-mysql}", source)
        self.assertEqual(source.count("```php\n"), 1)
        self.assertEqual(source.count("```csharp\n"), 1)


if __name__ == "__main__":
    unittest.main()
