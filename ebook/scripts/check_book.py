#!/usr/bin/env python3
"""Minimal structural checks for the Week 1 Quarto book."""

from __future__ import annotations

import argparse
from html.parser import HTMLParser
import re
import sys
from pathlib import Path
from urllib.parse import urlparse
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
BOOK = ROOT / "ebook"
CHAPTERS = (
    "index.qmd",
    "chapters/01-web-foundations.qmd",
    "chapters/02-variables-types-scope.qmd",
    "chapters/03-week1-practice-review.qmd",
    "chapters/04-development-environment.qmd",
    "answers.qmd",
    "references.qmd",
)
SURFACES = ("_quarto.yml", "references.bib", "assets/styles.css", *CHAPTERS)
SVGS = ("assets/request-response.svg", "assets/runtime-comparison.svg", "assets/scope.svg")
IMAGE_RE = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)")
CITE_RE = re.compile(r"(?<!\w)@([A-Za-z0-9_:-]+)")
BIB_RE = re.compile(r"@\w+\s*\{\s*([^,\s]+)", re.I)
TODO_RE = re.compile(r"(?m)^\s*(?:<!--\s*)?(?:TODO|TBD|PLACEHOLDER)(?:\s*[:>]|\s*$)")
FUTURE_WEEK_RE = re.compile(r"chapters/(?:0[5-9]|[1-9]\d)-|semana\s+[2-9]\b", re.I)


class ImageAltChecker(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.missing: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "img" and not (values.get("alt") or "").strip():
            self.missing.append(values.get("src") or "sin src")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def local_path(target: str) -> bool:
    parsed = urlparse(target)
    return not parsed.scheme and not parsed.netloc and not target.startswith("#")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rendered", action="store_true", help="comprueba artefactos ya renderizados")
    args = parser.parse_args()
    errors: list[str] = []

    for relative in SURFACES:
        if not (BOOK / relative).is_file():
            fail(errors, f"falta la superficie requerida: ebook/{relative}")
    for relative in SVGS:
        path = BOOK / relative
        if not path.is_file():
            fail(errors, f"falta el SVG requerido: ebook/{relative}")
        else:
            try:
                ET.parse(path)
            except ET.ParseError as exc:
                fail(errors, f"SVG inválido ebook/{relative}: {exc}")

    qmd_files = [BOOK / chapter for chapter in CHAPTERS if (BOOK / chapter).is_file()]
    keys = set()
    bib = BOOK / "references.bib"
    if bib.is_file():
        keys = set(BIB_RE.findall(bib.read_text(encoding="utf-8")))

    for qmd in qmd_files:
        content = qmd.read_text(encoding="utf-8")
        if TODO_RE.search(content):
            fail(errors, f"marcador pendiente en {qmd.relative_to(ROOT)}")
        for key in CITE_RE.findall(content):
            if key not in keys:
                fail(errors, f"cita sin entrada bibliográfica @{key} en {qmd.relative_to(ROOT)}")
        for alt, target in IMAGE_RE.findall(content):
            if not alt.strip():
                fail(errors, f"imagen sin texto alternativo en {qmd.relative_to(ROOT)}: {target}")
            target = target.split()[0]
            if local_path(target) and not (qmd.parent / target).resolve().is_file():
                fail(errors, f"imagen local inexistente en {qmd.relative_to(ROOT)}: {target}")

    demo = BOOK / "chapters/02-variables-types-scope.qmd"
    if demo.is_file():
        content = demo.read_text(encoding="utf-8")
        image = "csharp-app:latest"
        prerequisite = "docker compose -f csharp/compose.yaml build app"
        if image in content and prerequisite not in content[:content.index(image)]:
            fail(errors, "el demo público de C# usa csharp-app:latest sin explicar cómo construir la imagen")

    config = BOOK / "_quarto.yml"
    if config.is_file():
        text = config.read_text(encoding="utf-8")
        if FUTURE_WEEK_RE.search(text):
            fail(errors, "la configuración incluye capítulos de semanas futuras")
        for chapter in CHAPTERS:
            if chapter not in text:
                fail(errors, f"capítulo no configurado: {chapter}")

    if args.rendered:
        rendered = ("index.html", "chapters/01-web-foundations.html", "chapters/02-variables-types-scope.html", "chapters/03-week1-practice-review.html", "chapters/04-development-environment.html")
        for relative in rendered:
            html_path = BOOK / "_book" / relative
            if not html_path.is_file():
                fail(errors, f"falta artefacto renderizado: ebook/_book/{relative}")
            else:
                images = ImageAltChecker()
                images.feed(html_path.read_text(encoding="utf-8"))
                for src in images.missing:
                    fail(errors, f"imagen HTML sin texto alternativo en {relative}: {src}")
        pdf = BOOK / "_book" / "aplicaciones-web-php-csharp-semana1.pdf"
        if not pdf.is_file():
            fail(errors, f"falta PDF renderizado: {pdf.relative_to(ROOT)}")

    if errors:
        print("Comprobación estructural fallida:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Comprobación estructural correcta.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
