async (page) => {
  const base = "http://127.0.0.1:4187/";
  const browser = page.context().browser();
  if (!browser) throw new Error("La prueba requiere un contexto aislado");
  const contexts = [];
  const assert = (condition, message) => { if (!condition) throw new Error(message); };
  const summary = async (tab, selector, responded, correct, total) => {
    const text = await tab.locator(selector).textContent();
    assert(text.includes(`${responded}/${total} respondidas`) && text.includes(`${correct}/${total} correctas`), `Contadores inesperados: ${text}`);
    return text;
  };
  const isolatedPage = async () => {
    const context = await browser.newContext();
    contexts.push(context);
    return context.newPage();
  };
  try {
    const tab = await isolatedPage();
    await tab.goto(base, { waitUntil: "networkidle" });
    const { assessment, course } = await tab.evaluate(async () => ({
      assessment: await (await fetch("./assessments.json")).json(),
      course: await (await fetch("./course.json")).json(),
    }));
    const active = new Set(course.modules.filter((module) => module.week <= course.currentWeek).flatMap((module) => module.units).map((unit) => unit.href));
    const webPages = assessment.pages.filter((entry) => active.has(entry.href));
    const total = webPages.reduce((count, entry) => count + entry.questions.length, 0);
    const entry = webPages[0], question = entry.questions[0];
    const wrong = question.correctIndex === 0 ? 1 : 0;
    await summary(tab, ".course-progress", 0, 0, total);
    await tab.evaluate(() => localStorage.setItem("other-application-counter", "7"));
    await tab.goto(new URL(entry.href, base).href, { waitUntil: "networkidle" });
    await summary(tab, ".quiz-progress", 0, 0, entry.questions.length);
    assert(await tab.locator('.quiz-question textarea, .quiz-question input:not([type="radio"])').count() === 0, "La evaluación contiene respuesta libre");
    await tab.locator(`#${question.id} input[value="${wrong}"]`).check();
    await summary(tab, ".quiz-progress", 1, 0, entry.questions.length);
    await tab.reload({ waitUntil: "networkidle" });
    assert(await tab.locator(`#${question.id} input[value="${wrong}"]`).isChecked(), "No se restauró la opción seleccionada");
    const wrongState = await tab.locator(`#${question.id} .quiz-feedback`).textContent();
    assert(wrongState.includes("Por revisar") && wrongState.includes(question.feedback[wrong]), "No se restauró la explicación de la opción incorrecta");
    await summary(tab, ".quiz-progress", 1, 0, entry.questions.length);
    await tab.locator(`#${question.id} input[value="${question.correctIndex}"]`).check();
    await tab.reload({ waitUntil: "networkidle" });
    assert(await tab.locator(`#${question.id} input[value="${question.correctIndex}"]`).isChecked(), "No se restauró la respuesta correcta");
    const correctState = await tab.locator(`#${question.id} .quiz-feedback`).textContent();
    assert(correctState.includes("Correcta") && correctState.includes(question.feedback[question.correctIndex]), "Falta la explicación de la opción correcta");
    await summary(tab, ".quiz-progress", 1, 1, entry.questions.length);
    const architecture = assessment.pages.find((candidate) => candidate.questions.some((item) => item.id.startsWith("arq-")));
    await tab.goto(new URL(architecture.href, base).href, { waitUntil: "networkidle" });
    const arq = architecture.questions[0];
    await tab.locator(`#${arq.id} input[value="${arq.correctIndex}"]`).check();
    await tab.goto(base, { waitUntil: "networkidle" });
    const homeProgress = await summary(tab, ".course-progress", 1, 1, total);
    const corruptKey = await tab.evaluate((qid) => {
      const key = Object.keys(localStorage).find((name) => name.startsWith("practicas-quiz:") && JSON.parse(localStorage.getItem(name)).qid === qid);
      if (key) localStorage.setItem(key, "corrupt-record");
      return key;
    }, question.id);
    assert(Boolean(corruptKey), "No existe un registro persistente para la respuesta");
    await tab.goto(new URL(entry.href, base).href, { waitUntil: "networkidle" });
    assert(await tab.locator(`#${question.id} input:checked`).count() === 0, "Se aceptó un registro corrupto como respuesta");
    await summary(tab, ".quiz-progress", 0, 0, entry.questions.length);
    const retained = await tab.evaluate((key) => ({ other: localStorage.getItem("other-application-counter"), corrupt: localStorage.getItem(key) }), corruptKey);
    assert(retained.other === "7" && retained.corrupt === "corrupt-record", "La lectura modificó datos almacenados");

    const blocked = await isolatedPage();
    await blocked.addInitScript(() => Object.defineProperty(window, "localStorage", { get() { throw new Error("Blocked in isolated test"); } }));
    await blocked.goto(new URL(entry.href, base).href, { waitUntil: "networkidle" });
    await blocked.locator(`#${question.id} input[value="${wrong}"]`).check();
    const temporary = await summary(blocked, ".quiz-progress", 1, 0, entry.questions.length);
    assert(temporary.includes("No se pudo guardar"), "La UI afirma persistencia con almacenamiento bloqueado");
    await blocked.reload({ waitUntil: "networkidle" });
    await summary(blocked, ".quiz-progress", 0, 0, entry.questions.length);

    const failed = await isolatedPage();
    await failed.route("**/assessments.json", (route) => route.fulfill({ status: 503, contentType: "application/json", body: "{}" }));
    await failed.goto(new URL(entry.href, base).href, { waitUntil: "networkidle" });
    assert(await failed.locator('.quiz-question input[type="radio"]:enabled').count() === 0, "Las opciones siguen activas sin banco válido");
    const loadFailure = await failed.locator(".quiz-progress").textContent();
    assert(loadFailure.includes("No se pudieron cargar las evaluaciones") && loadFailure.includes("no se guardará"), "Falta un aviso honesto al fallar la carga");
    return { question: question.id, totalWeb: total, homeProgress, wrongState, correctState, corruptedRecordIgnored: true, unrelatedStoragePreserved: true, blockedStorageHonest: true, loadFailureHonest: true };
  } finally {
    await Promise.all(contexts.map((context) => context.close()));
  }
}
