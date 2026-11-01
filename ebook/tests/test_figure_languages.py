"""Regression coverage for standalone PHP and C# teaching figures."""
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

BOOK = Path(__file__).resolve().parents[1]

FIGURES = {
    "request-response.svg": ("PHP", ("C#", ".NET")),
    "request-response-csharp.svg": ("C#", ("PHP", "OPcache")),
    "runtime-comparison.svg": ("PHP", ("C#", ".NET")),
    "runtime-csharp.svg": ("C#", ("PHP", "OPcache")),
    "scope.svg": ("PHP", ("C#", ".NET")),
    "scope-csharp.svg": ("C#", ("PHP", "OPcache")),
}

CHAPTER_FIGURES = {
    "chapters/01-web-foundations.qmd": {
        "request-response.svg": ("Flujo PHP", "Flujo PHP"),
        "request-response-csharp.svg": ("Flujo C#", "Flujo C#"),
        "runtime-comparison.svg": ("Ruta de ejecución de PHP", "Ruta de ejecución de PHP"),
        "runtime-csharp.svg": ("Ruta de ejecución de C#", "Ruta de ejecución de C#"),
    },
    "chapters/02-variables-types-scope.qmd": {
        "scope.svg": ("Alcance en PHP", "Alcance en PHP"),
        "scope-csharp.svg": ("Alcance en C#", "Alcance en C#"),
    },
}


class StandaloneLanguageFigures(unittest.TestCase):
    def test_each_language_has_its_own_asset_caption_and_alt(self):
        for filename, (language, forbidden) in FIGURES.items():
            with self.subTest(asset=filename):
                path = BOOK / "assets" / filename
                self.assertTrue(path.is_file(), f"Missing public figure: {path}")
                root = ET.parse(path).getroot()
                visible = " ".join("".join(root.itertext()).split())
                self.assertIn(language, visible)
                for other in forbidden:
                    self.assertNotIn(other, visible)
                self.assertEqual(root.find("{http://www.w3.org/2000/svg}script"), None)

        for chapter, figures in CHAPTER_FIGURES.items():
            content = (BOOK / chapter).read_text(encoding="utf-8")
            for filename, (caption, alt) in figures.items():
                with self.subTest(chapter=chapter, figure=filename):
                    reference = f"../assets/{filename}"
                    self.assertEqual(content.count(reference), 1)
                    figure_line = next(line for line in content.splitlines() if reference in line)
                    self.assertIn(f"![{caption}", figure_line)
                    self.assertIn(f'fig-alt="{alt}', figure_line)


if __name__ == "__main__":
    unittest.main()
