"""Assessment publication behavior through the public build CLI."""
import json
import unittest

import test_build_site as build_fixture


class AssessmentBuild(unittest.TestCase):
    invoke = build_fixture.BuildSite.invoke

    def set_up_assessment(self):
        source = self.root / "ebook/chapters/one.md"
        source.write_text(source.read_text() + "\n<!-- quiz: safe-question -->\n")
        self.bank({
            "schemaVersion": 1,
            "pages": [{"href": "chapters/one.html", "questions": [self.question()]}],
        })
        (self.root / "site/quiz.mjs").write_text("export {}")
        (self.root / "site/progress.mjs").write_text("export {}")

    def setUp(self):
        build_fixture.BuildSite.setUp(self)
        self.set_up_assessment()

    def question(self):
        return {
            "id": "safe-question", "prompt": "¿Qué ocurre con <script>alert(1)</script> y \"comillas\"?",
            "options": ["<b>Literal</b>", "Otra", "Tercera"], "correctIndex": 0,
            "feedback": ["<img src=x>", "No", "No"], "objective": "Escapar texto", "level": "comprender",
            "code": "<script>no()</script>",
        }

    def bank(self, web, architecture=None):
        (self.root / "course/questions-web.json").write_text(json.dumps(web))
        (self.root / "course/questions-architecture.json").write_text(json.dumps(architecture or {"schemaVersion": 1, "pages": []}))

    def test_markers_render_questions_and_publish_modules(self):
        output = self.root / "output"
        result = self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "Site output is valid.\n", ""))
        page = (output / "chapters/one.html").read_text()
        self.assertIn('<fieldset class="quiz-question" data-question-id="safe-question" id="safe-question">', page)
        self.assertIn('input type="radio" name="safe-question" value="0" disabled', page)
        self.assertIn('&lt;script&gt;alert(1)&lt;/script&gt;', page)
        self.assertNotIn('<script>alert(1)</script>', page)
        self.assertTrue((output / "quiz.mjs").is_file())
        self.assertTrue((output / "progress.mjs").is_file())
        self.assertEqual(json.loads((output / "assessments.json").read_text())["pages"][0]["questions"][0]["id"], "safe-question")

    def output_files(self, output):
        return {path.relative_to(output): path.read_bytes() for path in output.rglob("*") if path.is_file()}

    def test_invalid_bank_or_unknown_marker_preserves_output(self):
        output = self.root / "output"; output.mkdir(); (output / "keep").write_text("same")
        before = self.output_files(output)
        bank = {"schemaVersion": 1, "pages": [{"href": "chapters/one.html", "questions": [{**self.question(), "options": ["same", "same", "third"]}]}]}
        self.bank(bank)
        result = self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (2, "", "build_site: assessment: safe-question: options must be 3 or 4 distinct non-empty strings\n"))
        self.assertEqual(self.output_files(output), before)
        self.bank({"schemaVersion": 1, "pages": [{"href": "chapters/one.html", "questions": [self.question()]}]})
        source = self.root / "ebook/chapters/one.md"; source.write_text(source.read_text() + "<!-- quiz: unknown-question -->\n")
        result = self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (2, "", "build_site: assessment: marker has no question: unknown-question\n"))
        self.assertEqual(self.output_files(output), before)

    def test_duplicate_question_id_preserves_output(self):
        output = self.root / "output"; output.mkdir(); (output / "keep").write_text("same")
        before = self.output_files(output)
        duplicate = self.question(); duplicate["id"] = "safe-question"
        self.bank({"schemaVersion": 1, "pages": [{"href": "chapters/one.html", "questions": [self.question()]}]}, {"schemaVersion": 1, "pages": [{"href": "cuaderno.html", "questions": [duplicate]}]})
        result = self.invoke("--output", str(output))
        self.assertEqual((result.returncode, result.stdout, result.stderr), (2, "", "build_site: assessment: duplicate question id: safe-question\n"))
        self.assertEqual(self.output_files(output), before)

    def test_publishes_only_cited_bibliography_with_doi_fallback(self):
        (self.root / "ebook/references.bib").write_text(
            "@article{source,\n title = {Used},\n author = {Author},\n year = {2026},\n doi = {10.1000/example}\n}\n"
            "@misc{private,\n title = {Private},\n author = {Nobody},\n year = {2026}\n}\n"
        )
        output = self.root / "output"
        result = self.invoke("--output", str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        references = (output / "references.html").read_text()
        self.assertIn("https://doi.org/10.1000/example", references)
        self.assertNotIn("Private", references)


if __name__ == "__main__":
    unittest.main()
