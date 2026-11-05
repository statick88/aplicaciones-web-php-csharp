"""Regression checks for the public multiple-choice assessment banks."""
import json
from collections import Counter
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
BANKS = (
    ROOT / "course/questions-web.json",
    ROOT / "course/questions-architecture.json",
)


class QuestionDidacticsTests(unittest.TestCase):
    def setUp(self):
        self.questions = [
            question
            for bank_path in BANKS
            for page in json.loads(bank_path.read_text(encoding="utf-8"))["pages"]
            for question in page["questions"]
        ]

    def test_correct_answers_are_not_all_in_one_position(self):
        positions = Counter(question["correctIndex"] for question in self.questions)
        self.assertEqual(len(self.questions), 87)
        self.assertGreater(len(positions), 1, positions)
        self.assertLess(max(positions.values()), len(self.questions), positions)

    def test_options_and_feedback_are_paired_and_complete(self):
        for question in self.questions:
            with self.subTest(question=question["id"]):
                self.assertIn(len(question["options"]), (3, 4))
                self.assertEqual(len(question["feedback"]), len(question["options"]))
                self.assertTrue(all(option.strip() for option in question["options"]))
                self.assertTrue(all(item.strip() for item in question["feedback"]))
                self.assertIn(question["correctIndex"], range(len(question["options"])))

    def test_questions_remain_closed_with_one_unambiguous_best_answer(self):
        for question in self.questions:
            with self.subTest(question=question["id"]):
                self.assertEqual(len(question["options"]), len(set(question["options"])))
                self.assertEqual(len(question["feedback"]), len(set(question["feedback"])))
                self.assertNotRegex(
                    question["prompt"],
                    r"(?i)\b(escribe|justifica|explica con tus palabras|respuesta abierta)\b",
                )


if __name__ == "__main__":
    unittest.main()
