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
      }
    }
  } finally {
    await page.unroute(`${base}**`);
  }
  return measurements;
}
