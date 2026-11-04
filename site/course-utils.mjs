export function filterUnits(modules, query) {
  const normalized = String(query ?? "").trim().toLocaleLowerCase("es");
  return (Array.isArray(modules) ? modules : []).flatMap((module) =>
    (Array.isArray(module.units) ? module.units : [])
      .filter((unit) => {
        if (!normalized) return true;
        const searchable = [unit.title, ...(Array.isArray(unit.technologies) ? unit.technologies : [])]
          .join(" ")
          .toLocaleLowerCase("es");
        return searchable.includes(normalized);
      })
      .map((unit) => ({ module, unit })),
  );
}

export function isLocalHref(href) {
  return typeof href === "string"
    && href.length > 0
    && !/^[a-z][a-z\d+.-]*:/i.test(href)
    && !href.startsWith("//")
    && !href.includes("\\");
}
