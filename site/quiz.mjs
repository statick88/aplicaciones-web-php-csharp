import { createProgressStore, isValidSelection, summarizeSelections } from "./progress.mjs";

const LEVELS = new Set(["comprender", "aplicar", "analizar"]);

function validQuestion(question) {
  return typeof question?.id === "string"
    && question.id.length > 0
    && typeof question.prompt === "string"
    && Array.isArray(question.options)
    && question.options.length >= 3
    && question.options.length <= 4
    && question.options.every((option) => typeof option === "string")
    && Number.isInteger(question.correctIndex)
    && question.correctIndex >= 0
    && question.correctIndex < question.options.length
    && Array.isArray(question.feedback)
    && question.feedback.length === question.options.length
    && question.feedback.every((item) => typeof item === "string")
    && typeof question.objective === "string"
    && LEVELS.has(question.level)
    && (question.code === undefined || typeof question.code === "string");
}

export function validateAssessment(data) {
  if (data?.schemaVersion !== 1 || !Array.isArray(data.pages)) return null;
  const ids = new Set();
  for (const page of data.pages) {
    if (typeof page?.href !== "string" || !Array.isArray(page.questions)) return null;
    for (const question of page.questions) {
      if (!validQuestion(question) || ids.has(question.id)) return null;
      ids.add(question.id);
    }
  }
  return data;
}

export function questionResult(question, selection) {
  if (!isValidSelection(question, selection)) return { responded: false, correct: false, feedback: "" };
  const correct = selection === question.correctIndex;
  return {
    responded: true,
    correct,
    feedback: `${correct ? "Correcta" : "Por revisar"}. Elegiste «${question.options[selection]}». ${question.feedback[selection]} Objetivo: ${question.objective}. Nivel: ${question.level}.`,
  };
}

export function summarizeAssessment(questions, selections) {
  return summarizeSelections(questions, (question) => selections?.get(question.id));
}

function pageQuestions(assessment, moduleUrl, pathname) {
  return assessment.pages.find((page) => new URL(page.href, moduleUrl).pathname === pathname)?.questions ?? [];
}

function progressElement(firstQuestion) {
  const existing = document.querySelector(".quiz-progress");
  if (existing) {
    existing.hidden = false;
    return existing;
  }
  const node = document.createElement("p");
  node.className = "quiz-progress";
  node.setAttribute("aria-live", "polite");
  firstQuestion.before(node);
  return node;
}

function renderFeedback(fieldset, result) {
  const feedback = fieldset.querySelector(".quiz-feedback");
  if (feedback) {
    feedback.setAttribute("aria-live", "polite");
    feedback.textContent = result.feedback;
  }
}

function initializeQuizDialog(fieldsets, progress) {
  const dialog = document.createElement("dialog");
  // Keep the inline questions usable in browsers without native dialog support.
  if (typeof dialog.showModal !== "function") return;
  dialog.id = "lesson-quiz-dialog";
  dialog.className = "quiz-dialog";
  dialog.setAttribute("aria-labelledby", "lesson-quiz-title");

  const header = document.createElement("div");
  header.className = "quiz-dialog-header";
  const title = document.createElement("h2");
  title.id = "lesson-quiz-title";
  title.textContent = "Cuestionario de la lección";
  const close = document.createElement("button");
  close.type = "button";
  close.className = "modal-close";
  close.textContent = "Cerrar cuestionario";
  close.autofocus = true;
  header.append(title, close);

  const trigger = document.createElement("button");
  trigger.type = "button";
  trigger.className = "cta quiz-open";
  trigger.textContent = `Abrir cuestionario (${fieldsets.length} preguntas)`;
  trigger.setAttribute("aria-haspopup", "dialog");
  trigger.setAttribute("aria-controls", dialog.id);
  fieldsets[0].before(trigger);
  const position = document.createElement("p");
  position.className = "quiz-position";
  position.setAttribute("aria-live", "polite");
  const navigation = document.createElement("nav");
  navigation.className = "quiz-navigation";
  navigation.setAttribute("aria-label", "Preguntas del cuestionario");
  const previous = document.createElement("button");
  previous.type = "button";
  previous.className = "modal-close";
  previous.textContent = "Anterior";
  const next = document.createElement("button");
  next.type = "button";
  next.className = "modal-close";
  next.textContent = "Siguiente";
  navigation.append(previous, position, next);
  let current = 0;
  function showQuestion(index, moveFocus = false) {
    current = index;
    for (const [number, fieldset] of fieldsets.entries()) fieldset.hidden = number !== current;
    position.textContent = `Pregunta ${current + 1} de ${fieldsets.length}`;
    previous.disabled = current === 0;
    next.disabled = current === fieldsets.length - 1;
    if (moveFocus) {
      const question = fieldsets[current];
      question.tabIndex = -1;
      question.focus({ preventScroll: true });
      dialog.scrollTop = 0;
    }
  }
  previous.addEventListener("click", () => showQuestion(current - 1, true));
  next.addEventListener("click", () => showQuestion(current + 1, true));
  showQuestion(0);
  dialog.append(header, progress, ...fieldsets, navigation);
  document.body.append(dialog);

  trigger.addEventListener("click", () => dialog.showModal());
  close.addEventListener("click", () => dialog.close());
  dialog.addEventListener("close", () => trigger.focus());
  dialog.addEventListener("keydown", (event) => {
    if (event.key !== "Tab") return;
    const controls = [...dialog.querySelectorAll('button:not([disabled]), input:not([disabled]), a[href], [tabindex="0"]')]
      .filter((node) => node.getClientRects().length > 0);
    const first = controls[0];
    const last = controls.at(-1);
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  });
}

async function initializeQuiz() {
  const fieldsets = [...document.querySelectorAll(".quiz-question[data-question-id]")];
  if (!fieldsets.length) return;

  let assessment;
  try {
    const response = await fetch(new URL("./assessments.json", import.meta.url));
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    assessment = validateAssessment(await response.json());
  } catch (error) {
    console.error("No se pudieron cargar las evaluaciones", error);
  }
  if (!assessment) {
    const progress = progressElement(fieldsets[0]);
    progress.textContent = "No se pudieron cargar las evaluaciones. Las opciones permanecen desactivadas y no se guardará ningún progreso.";
    for (const fieldset of fieldsets) {
      for (const radio of fieldset.querySelectorAll('input[type="radio"]')) radio.disabled = true;
    }
    return;
  }

  const questions = pageQuestions(assessment, import.meta.url, window.location.pathname);
  const questionById = new Map(questions.map((question) => [question.id, question]));
  const store = createProgressStore({ getStorage: () => window.localStorage, moduleUrl: import.meta.url });
  const selections = new Map();
  let storageAvailable = true;

  for (const fieldset of fieldsets) {
    const question = questionById.get(fieldset.dataset.questionId);
    if (!question || fieldset.id !== question.id) continue;
    for (const radio of fieldset.querySelectorAll('input[type="radio"]')) radio.disabled = false;
    const restored = store.read(question);
    if (restored.selection !== null) {
      selections.set(question.id, restored.selection);
      const radio = fieldset.querySelector(`input[type="radio"][value="${restored.selection}"]`);
      if (radio) radio.checked = true;
      renderFeedback(fieldset, questionResult(question, restored.selection));
    }
    if (restored.reason === "unavailable") storageAvailable = false;
  }

  const progress = progressElement(fieldsets[0]);
  function updateProgress() {
    const summary = summarizeAssessment(questions, selections);
    const persistence = storageAvailable
      ? " Los cambios se guardan en este dispositivo."
      : " No se pudo guardar en este dispositivo; la selección se conserva mientras esta página permanezca abierta.";
    const counts = document.createElement("span");
    counts.className = "quiz-progress-counts";
    counts.textContent = `${summary.responded}/${summary.total} respondidas · ${summary.correct}/${summary.total} correctas.`;
    const note = document.createElement("small");
    note.className = "quiz-storage-note";
    note.textContent = persistence;
    progress.replaceChildren(counts, note);
  }

  for (const fieldset of fieldsets) {
    const question = questionById.get(fieldset.dataset.questionId);
    if (!question || fieldset.id !== question.id) continue;
    for (const radio of fieldset.querySelectorAll('input[type="radio"]')) {
      radio.addEventListener("change", () => {
        const selection = Number(radio.value);
        if (!radio.checked || !isValidSelection(question, selection)) return;
        selections.set(question.id, selection);
        const saved = store.save(question, selection);
        if (!saved.saved) storageAvailable = false;
        renderFeedback(fieldset, questionResult(question, selection));
        updateProgress();
      });
    }
  }
  updateProgress();
  initializeQuizDialog(fieldsets, progress);
}

if (typeof document !== "undefined") initializeQuiz();
