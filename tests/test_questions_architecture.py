"""Contract tests for the Architecture multiple-choice content bank."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "course/questions-architecture.json"
PAGES = {
    "subjects/arquitectura-software/semana-01/01-diseno-arquitectura.html": ROOT / "ebook/subjects/arquitectura-software/semana-01/01-diseno-arquitectura.md",
    "subjects/arquitectura-software/semana-01/02-dominios-mitos.html": ROOT / "ebook/subjects/arquitectura-software/semana-01/02-dominios-mitos.md",
    "subjects/arquitectura-software/semana-01/03-practica-autoevaluacion.html": ROOT / "ebook/subjects/arquitectura-software/semana-01/03-practica-autoevaluacion.md",
    "subjects/arquitectura-software/semana-02/01-procesos-flujo.html": ROOT / "ebook/subjects/arquitectura-software/semana-02/01-procesos-flujo.md",
    "subjects/arquitectura-software/semana-02/02-modelos-practica-autoevaluacion.html": ROOT / "ebook/subjects/arquitectura-software/semana-02/02-modelos-practica-autoevaluacion.md",
}
EXPECTED_IDS = {
    "arq-diseno-frontera", "arq-diseno-modulos", "arq-diseno-calidad",
    "arq-tipos-ejes", "arq-tipos-sensor", "arq-tipos-terminado",
    "arq-s1-caso-regla", "arq-s1-analisis", "arq-s1-fronteras", "arq-s1-vista",
    "arq-s1-estilo", "arq-s1-cualidades", "arq-s1-clasificacion", "arq-s1-sumar-personas",
    "arq-s1-terminado", "arq-s1-cambio", "arq-s1-documentacion",
    "arq-proceso-requisito", "arq-proceso-tareas",
    "arq-s2-practica-modelo", "arq-s2-actividad-tarea", "arq-s2-volver-requisitos",
    "arq-s2-patron", "arq-s2-cascada", "arq-s2-incremento", "arq-s2-evolucion",
    "arq-s2-espiral", "arq-s2-contexto", "arq-s2-evidencias", "arq-s2-revisar",
}

class QuestionsArchitectureContract(unittest.TestCase):
    def test_bank_shape_feedback_and_marker_coverage(self):
        bank = json.loads(BANK.read_text(encoding="utf-8"))
        self.assertEqual(bank["schemaVersion"], 1)
        found = set()
        by_page = {}
        for page in bank["pages"]:
            self.assertIn(page["href"], PAGES)
            self.assertNotIn(page["href"], by_page)
            by_page[page["href"]] = page
            for question in page["questions"]:
                self.assertRegex(question["id"], r"^arq-[a-z0-9-]+$")
                self.assertNotIn(question["id"], found)
                found.add(question["id"])
                self.assertTrue(question["prompt"].strip())
                self.assertIn(len(question["options"]), (3, 4))
                self.assertEqual(len(question["feedback"]), len(question["options"]))
                self.assertTrue(all(item.strip() for item in question["feedback"]))
                self.assertIsInstance(question["correctIndex"], int)
                self.assertIn(question["correctIndex"], range(len(question["options"])))
                self.assertTrue(question["objective"].strip())
                self.assertIn(question["level"], ("comprender", "aplicar", "analizar"))
        self.assertEqual(found, EXPECTED_IDS)
        self.assertEqual(set(by_page), set(PAGES))
        for href, source in PAGES.items():
            markers = re.findall(r"<!-- quiz: ([a-z0-9-]+) -->", source.read_text(encoding="utf-8"))
            self.assertEqual(markers, [item["id"] for item in by_page[href]["questions"]])

    def test_main_questions_and_legacy_sections_are_preserved(self):
        bank = json.loads(BANK.read_text(encoding="utf-8"))
        ids = {question["id"] for page in bank["pages"] for question in page["questions"]}
        self.assertEqual(sum(identifier.startswith("arq-s1-") and identifier != "arq-s1-caso-regla" for identifier in ids), 10)
        self.assertEqual(sum(identifier.startswith("arq-s2-") and identifier != "arq-s2-practica-modelo" for identifier in ids), 10)
        practice = PAGES["subjects/arquitectura-software/semana-01/03-practica-autoevaluacion.html"].read_text(encoding="utf-8")
        models = PAGES["subjects/arquitectura-software/semana-02/02-modelos-practica-autoevaluacion.html"].read_text(encoding="utf-8")
        for heading in ("## Caso guiado", "## Ejercicio análogo", "## Autoevaluación formativa", "### 1. De necesidad a decisión", "### 10. Mito: «no hace falta documentación»"):
            self.assertIn(heading, practice)
        for heading in ("## Caso trabajado", "## Práctica análoga", "## Autoevaluación formativa", "### 1. Actividad y tarea", "### 10. Revisar una elección"):
            self.assertIn(heading, models)
        combined = "\n".join(path.read_text(encoding="utf-8") for path in PAGES.values())
        self.assertNotIn("- [ ]", combined)
        self.assertNotRegex(combined, r"(?i)(responde|contesta|justifica|escribe|propón) (primero )?(con tus palabras|una página|en tus apuntes)")

if __name__ == "__main__":
    unittest.main()
