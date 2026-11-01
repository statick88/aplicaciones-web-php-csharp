import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SubjectIndexesAndTypography(unittest.TestCase):
    def test_shared_bibliography_keeps_entries_for_unchanged_chapters(self):
        references = (ROOT / "references.qmd").read_text()
        self.assertRegex(references, r"(?m)^nocite:\s*['\"]@\*['\"]\s*$")
        self.assertIn("::: {#refs}", references)
