import assert from "node:assert/strict";
import test from "node:test";
import { filterUnits, isLocalHref } from "./course-utils.mjs";

const modules = [
  {
    id: "week1",
    title: "Semana 1",
    units: [
      { id: "php", title: "Formularios PHP", href: "chapters/php.html", technologies: ["php"] },
      { id: "net", title: "Variables en .NET", href: "chapters/net.html", technologies: ["dotnet"] },
    ],
  },
];

test("filterUnits finds titles and technologies without changing the catalog", () => {
  assert.deepEqual(filterUnits(modules, "formu").map(({ unit }) => unit.id), ["php"]);
  assert.deepEqual(filterUnits(modules, " .NET ").map(({ unit }) => unit.id), ["net"]);
  assert.equal(modules[0].units.length, 2);
});

test("filterUnits returns all units for an empty search and none for an unknown term", () => {
  assert.equal(filterUnits(modules, "").length, 2);
  assert.equal(filterUnits(modules, "ruby").length, 0);
});

test("isLocalHref accepts normal Pages-relative documents and rejects external or unsafe URLs", () => {
  assert.equal(isLocalHref("subjects/aplicaciones-web.html"), true);
  assert.equal(isLocalHref("../cuaderno.html"), true);
  assert.equal(isLocalHref("https://example.test/page"), false);
  assert.equal(isLocalHref("//example.test/page"), false);
  assert.equal(isLocalHref("javascript:alert(1)"), false);
});
