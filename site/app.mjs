import { filterUnits, isLocalHref, supportingPages } from "./course-utils.mjs";

const app = document.querySelector("#app");
const search = document.querySelector("#search");
const catalogAnchor = document.querySelector("#catalogo");
let course;

function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function link(text, href, className) {
  const anchor = element("a", className, text);
  anchor.href = href;
  return anchor;
}

function clearApp() { app.replaceChildren(); }

function courseModules() {
  return course.modules.filter((module) => Number(module.week) <= Number(course.currentWeek));
}

function technologies(unit) {
  const wrapper = element("span", "technology-badges");
  for (const technology of Array.isArray(unit.technologies) ? unit.technologies : []) {
    const badge = element("span", `technology ${technology}`, technology === "dotnet" ? ".NET" : technology.toUpperCase());
    wrapper.append(badge);
  }
  return wrapper;
}

function makeModule(module, units) {
  const section = element("section", "module");
  section.append(element("span", "badge", `SEMANA ${module.week} · CLASE Y PRÁCTICA`));
  section.append(element("h2", undefined, module.title));
  section.append(element("p", "module-copy", module.description));
  const list = element("ul", "lesson-list");
  for (const unit of units) {
    if (!isLocalHref(unit.href)) continue;
    const item = element("li");
    const itemLink = link(`○ ${unit.title}`, unit.href);
    item.append(itemLink, technologies(unit));
    list.append(item);
  }
  section.append(list);
  return section;
}

function makeSupportingPages() {
  const section = element("section", "supporting-pages");
  section.append(element("h2", undefined, "Cuaderno y material conservado"));
  section.append(element("p", undefined, "Estas páginas preservan material de consulta y de otras asignaturas; no forman parte de las prácticas vigentes de Programación Web."));
  const list = element("ul", "supporting-list");
  for (const page of supportingPages(course.pages, course.modules, course.currentWeek)) {
    if (!isLocalHref(page.href)) continue;
    const item = element("li");
    item.append(link(page.title, page.href, "text-link"));
    list.append(item);
  }
  section.append(list);
  return section;
}

function renderHome() {
  clearApp();
  const modules = courseModules();
  const query = search.value;
  const matches = filterUnits(modules, query);
  const hero = element("section", "hero");
  hero.setAttribute("aria-labelledby", "home-title");
  hero.append(element("p", "eyebrow", "PROGRAMACIÓN WEB · PHP · .NET"));
  const title = element("h1");
  title.id = "home-title";
  title.append("Practica PHP y .NET", document.createElement("br"), element("span", undefined, "paso a paso."));
  hero.append(title);
  hero.append(element("p", "hero-copy", "Clases y prácticas guiadas de Aplicaciones Web: tipos, variables y formularios con PHP y .NET."));
  const first = modules[0]?.units?.[0];
  if (first && isLocalHref(first.href)) hero.append(link("Empezar a practicar →", first.href, "cta"));
  hero.append(element("p", "totals", `Semana ${course.currentWeek} en curso · ${modules.length} módulos disponibles`));
  hero.append(element("p", "local-notice", "Uso local: este sitio es estático; no ejecuta PHP, no guarda progreso ni envía datos."));
  app.append(hero);

  const catalogSection = element("section", "catalog-section");
  catalogSection.append(catalogAnchor);
  catalogSection.append(element("h2", "section-title", query ? "Resultados de búsqueda" : "Índice de prácticas"));
  if (query && !matches.length) {
    catalogSection.append(element("p", "empty-state", "No encontramos clases o tecnologías con esa búsqueda. Prueba con PHP, .NET o una palabra del título."));
  } else {
    const catalog = element("div", "catalog");
    const groups = new Map();
    for (const entry of query ? matches : filterUnits(modules, "")) {
      if (!groups.has(entry.module.id)) groups.set(entry.module.id, { module: entry.module, units: [] });
      groups.get(entry.module.id).units.push(entry.unit);
    }
    for (const { module, units } of groups.values()) catalog.append(makeModule(module, units));
    catalogSection.append(catalog);
  }
  app.append(catalogSection, makeSupportingPages());
}

function renderLoadError() {
  clearApp();
  const section = element("section", "message-panel");
  section.setAttribute("role", "alert");
  section.append(element("h1", undefined, "No se pudo cargar el catálogo"));
  section.append(element("p", undefined, "Confirma que course.json esté junto a esta página e inténtalo nuevamente."));
  const retry = element("button", "cta", "Reintentar carga");
  retry.type = "button";
  retry.addEventListener("click", loadCourse);
  section.append(retry);
  app.append(section);
}

async function loadCourse() {
  clearApp();
  app.append(element("p", "loading", "Cargando las prácticas…"));
  try {
    const response = await fetch("./course.json");
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    if (data?.schemaVersion !== 1 || !Array.isArray(data.modules) || !Array.isArray(data.pages)) throw new Error("Formato incompatible");
    course = data;
    renderHome();
    if (window.location.hash === "#catalogo") catalogAnchor.scrollIntoView();
  } catch (error) {
    console.error("No se pudo cargar course.json", error);
    renderLoadError();
  }
}

search.addEventListener("input", () => { if (course) renderHome(); });
loadCourse();
