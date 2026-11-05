import assert from "node:assert/strict";
import test from "node:test";
import { createProgressStore, signatureForQuestion } from "./progress.mjs";

class FakeStorage {
  constructor(entries = {}) { this.entries = new Map(Object.entries(entries)); }
  getItem(key) { return this.entries.has(key) ? this.entries.get(key) : null; }
  setItem(key, value) { this.entries.set(key, value); }
}

const question = {
  id: "php-types-1",
  prompt: "¿Cuál es un tipo?",
  options: ["string", "table", "route"],
  correctIndex: 0,
  feedback: ["Sí", "No", "No"],
  objective: "Reconocer tipos",
  level: "comprender",
};

test("persists a validated selection in a versioned key scoped to the site root", () => {
  const storage = new FakeStorage({ unrelated: "keep" });
  const store = createProgressStore({ storage, moduleUrl: "https://example.test/course/quiz.mjs" });

  assert.equal(store.save(question, 1).saved, true);
  assert.equal(store.read(question).selection, 1);
  assert.equal(storage.getItem("unrelated"), "keep");
  assert.match([...storage.entries.keys()].find((key) => key !== "unrelated"), /^practicas-quiz:v1:%2Fcourse%2F:/);
});

test("rejects invalid selections without changing stored or unrelated data", () => {
  const storage = new FakeStorage({ unrelated: "keep" });
  const store = createProgressStore({ storage, moduleUrl: "https://example.test/quiz.mjs" });
  store.save(question, 0);
  const before = storage.getItem(store.keyFor(question));

  assert.deepEqual(store.save(question, 9), { saved: false, reason: "invalid" });
  assert.equal(storage.getItem(store.keyFor(question)), before);
  assert.equal(storage.getItem("unrelated"), "keep");
});

test("ignores corrupt and stale records without treating them as answers", () => {
  const storage = new FakeStorage();
  const store = createProgressStore({ storage, moduleUrl: "https://example.test/quiz.mjs" });
  storage.setItem(store.keyFor(question), "not-json");
  assert.deepEqual(store.read(question), { selection: null, reason: "corrupt" });
  storage.setItem(store.keyFor(question), JSON.stringify({ version: 1, qid: question.id, selection: 0, signature: "old" }));
  assert.deepEqual(store.read(question), { selection: null, reason: "stale" });
  assert.notEqual(signatureForQuestion(question), "old");
});

test("keeps an in-memory answer usable when storage is unavailable", () => {
  const store = createProgressStore({ getStorage: () => { throw new Error("blocked"); }, moduleUrl: "https://example.test/quiz.mjs" });
  assert.deepEqual(store.save(question, 0), { saved: false, reason: "unavailable" });
  assert.deepEqual(store.read(question), { selection: null, reason: "unavailable" });
});

test("reports a write failure without modifying unrelated keys", () => {
  const storage = new FakeStorage({ unrelated: "keep" });
  storage.setItem = () => { throw new Error("denied"); };
  const store = createProgressStore({ storage, moduleUrl: "https://example.test/quiz.mjs" });
  assert.deepEqual(store.save(question, 0), { saved: false, reason: "unavailable" });
  assert.equal(storage.entries.get("unrelated"), "keep");
});

test("reports an unavailable getter without modifying unrelated keys", () => {
  const storage = new FakeStorage({ unrelated: "keep" });
  storage.getItem = () => { throw new Error("denied"); };
  const store = createProgressStore({ storage, moduleUrl: "https://example.test/quiz.mjs" });
  assert.deepEqual(store.read(question), { selection: null, reason: "unavailable" });
  assert.equal(storage.entries.get("unrelated"), "keep");
});
