export function filterUnits(modules, query) {
  const normalized = String(query ?? "").trim().toLocaleLowerCase("es");
  return (Array.isArray(modules) ? modules : []).flatMap((module) =>
    (Array.isArray(module.units) ? module.units : [])
      .filter((unit) => {
        if (!normalized) return true;
        const labels = (Array.isArray(unit.technologies) ? unit.technologies : [])
          .flatMap((technology) => technology === "dotnet" ? ["dotnet", ".NET"] : [technology]);
        const searchable = [unit.title, ...labels]
          .join(" ")
          .toLocaleLowerCase("es");
        return searchable.includes(normalized);
      })
      .map((unit) => ({ module, unit })),
  );
}

export function supportingPages(pages, modules, currentWeek) {
  const active = new Set(filterUnits(modules.filter((module) => Number(module.week) <= Number(currentWeek)), "")
    .map(({ unit }) => unit.href));
  return pages.filter((page) => !active.has(page.href));
}

export function isLocalHref(href) {
  return typeof href === "string"
    && href.length > 0
    && !/^[a-z][a-z\d+.-]*:/i.test(href)
    && !href.startsWith("//")
    && !href.includes("\\");
}
