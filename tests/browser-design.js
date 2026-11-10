async (page) => {
  const base = "http://127.0.0.1:4187/";
  const assert = (ok, message) => { if (!ok) throw new Error(message); };
  const results = [];
  await page.route(`${base}**`, (route) => route.continue());
  try {
    for (const width of [375, 1440, 1920]) {
      await page.setViewportSize({ width, height: 812 });
      await page.goto(`${base}chapters/01-web-foundations.html`, { waitUntil: "networkidle" });
      const reading = await page.evaluate(() => {
        const article = document.querySelector(".lesson");
        const paragraph = article.querySelector(":scope > p:not(.eyebrow)");
        const heading = article.querySelector("h1");
        const eyebrow = article.querySelector(".eyebrow");
        const sidebar = document.querySelector(".lesson-sidebar");
        return { prose: paragraph.getBoundingClientRect().width, title: parseFloat(getComputedStyle(heading).fontSize),
          eyebrow: eyebrow?.textContent ?? "", firstModule: sidebar.querySelector(".sidebar-module").textContent,
          supplementaryClosed: !sidebar.querySelector(".sidebar-supplementary").open,
          overflow: document.documentElement.scrollWidth > innerWidth };
      });
      assert(reading.prose <= 760 && reading.title <= 48 && !reading.overflow, `Lectura incómoda: ${JSON.stringify(reading)}`);
      assert((reading.eyebrow.match(/Semana 1/gi) || []).length <= 1, "Contexto de semana repetido");
      assert(reading.firstModule.includes("Semana 1") && reading.supplementaryClosed, "El índice no prioriza la lección actual");
      const supplementary = page.locator(".sidebar-supplementary");
      await supplementary.locator("summary").click();
      assert(await supplementary.locator("a").first().isVisible(), "El material plegado no puede consultarse");
      await supplementary.locator("summary").click();
      await page.getByRole("button", { name: /^Abrir cuestionario/ }).click();
      const dialog = page.getByRole("dialog");
      const total = await dialog.locator(".quiz-question").count();
      const previous = dialog.getByRole("button", { name: "Anterior", exact: true });
      const next = dialog.getByRole("button", { name: "Siguiente", exact: true });
      const counter = dialog.locator(".quiz-position");
      assert(await counter.textContent() === `Pregunta 1 de ${total}`, "Falta la posición inicial");
      assert(await previous.isDisabled(), "Anterior debe estar desactivado al inicio");
      assert(await dialog.locator(".quiz-question:visible").count() === 1, "Debe verse solo una pregunta");
      for (let index = 2; index <= total; index++) {
        await next.click();
        assert(await counter.textContent() === `Pregunta ${index} de ${total}`, "La posición no avanza");
        assert(await dialog.locator(".quiz-question:visible").count() === 1, "Se muestran varias preguntas");
      }
      assert(await next.isDisabled(), "Siguiente debe estar desactivado al final");
      await previous.click();
      assert(await counter.textContent() === `Pregunta ${total - 1} de ${total}`, "No se puede retroceder");
      const details = await dialog.evaluate((node) => {
        node.scrollTop = node.scrollHeight;
        const box = node.getBoundingClientRect();
        const close = node.querySelector(".modal-close").getBoundingClientRect();
        const note = node.querySelector(".quiz-storage-note");
        return { closeVisible: close.top >= box.top && close.bottom <= box.bottom,
          secondaryNote: parseFloat(getComputedStyle(note).fontSize) < parseFloat(getComputedStyle(node.querySelector(".quiz-progress")).fontSize),
          overflow: node.scrollWidth > node.clientWidth };
      });
      assert(details.closeVisible && details.secondaryNote && !details.overflow, `Controles incómodos: ${JSON.stringify(details)}`);
      results.push({ width, total, ...reading, ...details });
      await page.keyboard.press("Escape");
    }
    const course = await page.evaluate(async () => (await fetch("../course.json")).json());
    const lastModule = course.modules.at(-1);
    await page.goto(new URL(lastModule.units[0].href, base).href, { waitUntil: "networkidle" });
    assert(await page.locator(".lesson-sidebar .sidebar-module").first().textContent() === lastModule.title, "La semana consultada no aparece primero");
    assert(await page.locator('.lesson-sidebar a[aria-current="page"]').isVisible(), "La lección activa quedó plegada");
    const unitHrefs = new Set(course.modules.flatMap((module) => module.units.map((unit) => unit.href)));
    const supplementaryPage = course.pages.find((entry) => !unitHrefs.has(entry.href));
    await page.goto(new URL(supplementaryPage.href, base).href, { waitUntil: "networkidle" });
    assert(await page.locator(".sidebar-supplementary").getAttribute("open") !== null, "El material complementario activo quedó plegado");
    return results;
  } finally {
    await page.unroute(`${base}**`);
  }
}
