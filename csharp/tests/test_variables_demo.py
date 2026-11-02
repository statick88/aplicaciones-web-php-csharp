"""Static coverage checks for the S1C2 variables demo (Class 2 declared topics).

The C# practice has no unit-test project (adding one would introduce a new
dependency), so these checks pin the demo content the same way the repository's
runtime configuration tests pin the stack configuration. Compilation is checked
separately with `dotnet build --configuration Release --warnaserror`.
"""

from __future__ import annotations

import unittest
from pathlib import Path


CSHARP_DIR = Path(__file__).resolve().parents[1]
CONTROLLER = CSHARP_DIR / "src" / "Controllers" / "HomeController.cs"
VIEW = CSHARP_DIR / "src" / "Views" / "Home" / "Variables.cshtml"


class VariablesDemoCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.view = VIEW.read_text(encoding="utf-8")

    def test_declares_a_compile_time_constant(self) -> None:
        self.assertIn("public const string", self.controller)
        self.assertIn("const (valor de compilación)", self.controller)

    def test_shows_nullable_values_and_null_coalescing(self) -> None:
        self.assertIn("string?", self.controller)
        self.assertIn("??", self.controller)
        self.assertIn("apellido", self.controller)

    def test_shows_string_interpolation(self) -> None:
        self.assertIn("Interpolación de cadena", self.controller)
        self.assertIn('$"Curso: {estudiante}"', self.controller)

    def test_prefers_a_parameter_over_shared_state(self) -> None:
        self.assertIn("private static string CursoDe(string nombre)", self.controller)
        self.assertIn("Parámetro", self.controller)

    def test_points_to_the_php_counterpart_entry(self) -> None:
        self.assertIn("public/variables.php", self.view)


if __name__ == "__main__":
    unittest.main()
