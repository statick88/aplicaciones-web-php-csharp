import assert from "node:assert/strict";
import test from "node:test";
import { questionResult, summarizeAssessment, validateAssessment } from "./quiz.mjs";

const question = {
  id: "php-types-1",
  prompt: "¿Cuál es un tipo?",
  options: ["string", "table", "route"],
  correctIndex: 0,
  feedback: ["string representa texto.", "Una tabla no es un tipo de PHP.", "Una ruta no es un tipo de PHP."],
  objective: "Reconocer tipos",
  level: "comprender",
};

test("reports a selected wrong option as responded but not correct with didactic feedback", () => {
  assert.deepEqual(questionResult(question, 1), {
    responded: true,
    correct: false,
    feedback: "Por revisar. Elegiste «table». Una tabla no es un tipo de PHP. Objetivo: Reconocer tipos. Nivel: comprender.",
  });
  assert.deepEqual(summarizeAssessment([question], new Map([[question.id, 1]])), { responded: 1, correct: 0, total: 1 });
});

test("reports a correct answer and never counts visits as progress", () => {
  assert.deepEqual(questionResult(question, 0), {
    responded: true,
    correct: true,
    feedback: "Correcta. Elegiste «string». string representa texto. Objetivo: Reconocer tipos. Nivel: comprender.",
  });
  assert.deepEqual(summarizeAssessment([question], new Map()), { responded: 0, correct: 0, total: 1 });
});

test("accepts only the frozen multiple-choice assessment shape", () => {
  assert.deepEqual(validateAssessment({ schemaVersion: 1, pages: [{ href: "lesson.html", questions: [question] }] }).pages[0].questions, [question]);
  assert.equal(validateAssessment({ schemaVersion: 1, pages: [{ href: "lesson.html", questions: [{ ...question, options: ["a", "b"] }] }] }), null);
  assert.equal(validateAssessment({ schemaVersion: 1, pages: [{ href: "lesson.html", questions: [{ ...question, correctIndex: 3 }] }] }), null);
});
