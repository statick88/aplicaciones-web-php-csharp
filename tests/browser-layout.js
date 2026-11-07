async (page) => {
  const base = "http://127.0.0.1:4187/";
  const paths = [
    "",
    "chapters/01-web-foundations.html",
    "subjects/aplicaciones-web/semana-02/02-formularios-get-post.html",
  ];
  const measurements = [];
  // Routing disables the browser cache while checking regenerated local CSS.
  await page.route(`${base}**`, (route) => route.continue());
  try {
    for (const width of [1920, 2560, 375]) {
      await page.setViewportSize({ width, height: 900 });
      for (const path of paths) {
        await page.goto(new URL(path, base).href, { waitUntil: "networkidle" });
        const result = await page.evaluate(() => {
          const main = document.querySelector("main");
          const bounds = main.getBoundingClientRect();
          const lesson = document.querySelector(".lesson");
          const article = lesson?.getBoundingClientRect();
          return {
            viewport: document.documentElement.clientWidth,
            width: bounds.width,
            left: bounds.left,
            overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth,
            articleGap: article ? bounds.right - parseFloat(getComputedStyle(main).paddingRight) - article.right : 0,
            headerGutter: parseFloat(getComputedStyle(document.querySelector(".site-header")).paddingLeft),
          };
        });
        if (Math.abs(result.width - result.viewport) > 1 || Math.abs(result.left) > 1) {
          throw new Error(`${width}px ${path || "home"}: main uses ${result.width}px of ${result.viewport}px`);
        }
        if (result.overflow || Math.abs(result.articleGap) > 1 || result.headerGutter > 20) {
          throw new Error(`${width}px ${path || "home"}: unused space or overflow: ${JSON.stringify(result)}`);
        }
        measurements.push({ width, path: path || "home", ...result });
        if (path) {
          const toggle = page.getByRole("button", { name: "Ocultar temas", exact: true });
          await toggle.waitFor({ state: "visible", timeout: 3000 });
          if (await toggle.getAttribute("aria-expanded") !== "true") throw new Error("Topics must initially be expanded");
          const before = await page.locator(".lesson").boundingBox();
          await toggle.focus();
          await page.keyboard.press("Enter");
          const show = page.getByRole("button", { name: "Mostrar temas", exact: true });
          if (await show.getAttribute("aria-expanded") !== "false") throw new Error("Collapsed state not announced");
          if (await page.locator(".lesson-sidebar").isVisible()) throw new Error("Topics remain visible");
          const expanded = await page.evaluate(() => {
            const layout = document.querySelector(".lesson-layout").getBoundingClientRect();
            const article = document.querySelector(".lesson").getBoundingClientRect();
            return { left: Math.abs(layout.left - article.left), right: Math.abs(layout.right - article.right), width: article.width,
              overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth };
          });
          if (expanded.left > 1 || expanded.right > 1 || expanded.overflow) throw new Error(`Not full width: ${JSON.stringify(expanded)}`);
          if (width > 700 && expanded.width <= before.width) throw new Error("Hiding topics did not widen the lesson");
          if (!(await show.evaluate((node) => node === document.activeElement))) throw new Error("Toggle lost keyboard focus");
          await page.keyboard.press("Space");
          if (!(await page.locator(".lesson-sidebar").isVisible())) throw new Error("Topics did not return");
          if (await toggle.getAttribute("aria-expanded") !== "true") throw new Error("Restored state not announced");
          const restored = await page.locator(".lesson").boundingBox();
          if (Math.abs(restored.width - before.width) > 1) throw new Error("Original layout not restored");
          measurements.push({ width, path, topicsToggle: "keyboard hide/show passed", ...expanded });
        } else if (await page.locator("[data-topics-toggle]").count()) {
          throw new Error("Home should not have a topics toggle");
        }
      }
    }
  } finally {
    await page.unroute(`${base}**`);
  }
  return measurements;
}
