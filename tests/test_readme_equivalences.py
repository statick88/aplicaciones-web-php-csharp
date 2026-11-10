"""Equivalences-map checks for the root README.

The repository presents the same course exercises in two stacks. The root
README must map PHP and C# counterparts explicitly while keeping the
no-full-parity disclaimer, every mapped local path must exist, and every
local markdown link in the README must resolve.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"

# Paths that the equivalences map must name; each must also exist.
MAPPED_PATHS = [
    "php/public/variables.php",
    "php/src/variables.php",
    "php/views/variables.php",
    "php/config/config.php",
    "php/tests/",
    "csharp/src/Controllers/HomeController.cs",
    "csharp/src/Views/Home/Variables.cshtml",
    "csharp/tests/",
]


class RootReadmeEquivalencesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.text = README.read_text(encoding="utf-8")

    def test_declares_the_equivalences_section(self) -> None:
        self.assertIn("## Equivalencias PHP", self.text)

    def test_keeps_the_no_full_parity_disclaimer(self) -> None:
        self.assertIn("no se declara paridad completa", self.text)

    def test_maps_both_stacks_with_existing_paths(self) -> None:
        for path in MAPPED_PATHS:
            with self.subTest(path=path):
                self.assertIn(path, self.text)
                self.assertTrue((ROOT / path).exists(), path)

    def test_local_markdown_links_resolve(self) -> None:
        links = re.findall(r"\]\(([^)\s]+)\)", self.text)
        local = [link for link in links if not re.match(r"[a-z]+://", link)]
        self.assertTrue(local, "root README must keep local links")
        for link in local:
            with self.subTest(link=link):
                target = link.split("#", 1)[0]
                if not target:
                    continue
                self.assertTrue((ROOT / target).exists(), link)


if __name__ == "__main__":
    unittest.main()
