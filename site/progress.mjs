const VERSION = 1;
const PREFIX = "practicas-quiz";

function rootPath(moduleUrl) {
  try {
    return new URL(".", moduleUrl).pathname;
  } catch {
    return "/";
  }
}

function hash(value) {
  let result = 2166136261;
  for (const character of value) {
    result ^= character.charCodeAt(0);
    result = Math.imul(result, 16777619);
  }
  return (result >>> 0).toString(36);
}

export function signatureForQuestion(question) {
  return hash(JSON.stringify({
    id: question?.id,
    prompt: question?.prompt,
    options: question?.options,
    correctIndex: question?.correctIndex,
    feedback: question?.feedback,
    objective: question?.objective,
    level: question?.level,
    code: question?.code,
  }));
}

export function isValidSelection(question, selection) {
  return Number.isInteger(selection)
    && Array.isArray(question?.options)
    && selection >= 0
    && selection < question.options.length;
}

export function summarizeSelections(questions, selectionFor) {
  return (Array.isArray(questions) ? questions : []).reduce((summary, question) => {
    const selection = selectionFor(question);
    if (!isValidSelection(question, selection)) return summary;
    summary.responded += 1;
    if (selection === question.correctIndex) summary.correct += 1;
    return summary;
  }, { responded: 0, correct: 0, total: Array.isArray(questions) ? questions.length : 0 });
}

export function createProgressStore({ storage, getStorage, moduleUrl } = {}) {
  const namespace = `${PREFIX}:v${VERSION}:${encodeURIComponent(rootPath(moduleUrl))}:`;
  let unavailable = false;

  function resolveStorage() {
    if (unavailable) return null;
    try {
      const candidate = storage ?? (typeof getStorage === "function" ? getStorage() : null);
      if (!candidate || typeof candidate.getItem !== "function" || typeof candidate.setItem !== "function") throw new Error("Storage unavailable");
      return candidate;
    } catch {
      unavailable = true;
      return null;
    }
  }

  function keyFor(question) {
    return `${namespace}${encodeURIComponent(question?.id ?? "")}`;
  }

  function read(question) {
    const candidate = resolveStorage();
    if (!candidate) return { selection: null, reason: "unavailable" };
    let raw;
    try {
      raw = candidate.getItem(keyFor(question));
    } catch {
      unavailable = true;
      return { selection: null, reason: "unavailable" };
    }
    if (raw === null) return { selection: null, reason: "missing" };
    try {
      const record = JSON.parse(raw);
      if (record?.version !== VERSION || record.qid !== question?.id || record.signature !== signatureForQuestion(question) || !isValidSelection(question, record.selection)) {
        return { selection: null, reason: "stale" };
      }
      return { selection: record.selection, reason: "stored" };
    } catch {
      return { selection: null, reason: "corrupt" };
    }
  }

  function save(question, selection) {
    if (!isValidSelection(question, selection)) return { saved: false, reason: "invalid" };
    const candidate = resolveStorage();
    if (!candidate) return { saved: false, reason: "unavailable" };
    try {
      candidate.setItem(keyFor(question), JSON.stringify({
        version: VERSION,
        qid: question.id,
        selection,
        signature: signatureForQuestion(question),
      }));
      return { saved: true, reason: "stored" };
    } catch {
      unavailable = true;
      return { saved: false, reason: "unavailable" };
    }
  }

  return { keyFor, read, save };
}
