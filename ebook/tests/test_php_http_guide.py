"""Source-level regression checks for the executable PHP lab guide link."""

import re
import unittest
from pathlib import Path

GUIDE = (Path(__file__).resolve().parents[1]
         / "subjects/aplicaciones-web/laboratorio-http-php.qmd")


class PhpHttpGuide(unittest.TestCase):
    def test_launch_link_targets_the_documented_executing_server(self):
        source = GUIDE.read_text(encoding="utf-8")
        launch = re.search(r"\[el laboratorio local\]\(([^)]+)\)", source)
        self.assertIsNotNone(launch)
        self.assertEqual(launch.group(1), "http://127.0.0.1:8088/")
        self.assertIn("[guía del ejemplo](../../examples/http-methods/README.md)", source)


if __name__ == "__main__":
    unittest.main()
