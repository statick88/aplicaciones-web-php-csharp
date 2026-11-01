#!/usr/bin/env python3
"""Minimal structural checks for the subject- and week-based Quarto book."""

from __future__ import annotations

import argparse
from html.parser import HTMLParser
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse
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


class ImageAltChecker(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.missing: list[str] = []
        self.ids: set[str] = set()
        self.targets: list[str] = []
        self.bootstrap: list[dict[str, str | None]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "img" and not (values.get("alt") or "").strip():
            self.missing.append(values.get("src") or "sin src")
        for anchor in (values.get("id"), values.get("name") if tag == "a" else None):
            if anchor:
                self.ids.add(anchor)
        for attr in ("href", "src", "poster", "data"):
            if attr == "data" and tag != "object":
                continue
            if values.get(attr) and values[attr] not in self.targets:
                self.targets.append(values[attr])
        if tag == "link" and "stylesheet" in (values.get("rel") or "").split():
            if re.match(r"bootstrap(?!-icons)(?:[.-])", Path(urlparse(values.get("href") or "").path).name):
                self.bootstrap.append(values)

    handle_startendtag = handle_starttag


def configured_chapters(text: str) -> tuple[str, ...]:
    """Read scalar Quarto chapter, file, and file-based part entries.

    This bounded extraction supports the book structures used here, including
    nested lists; it is not a general YAML parser.
    """
    return tuple(dict.fromkeys(re.findall(
        r"(?m)^\s*(?:-\s*|(?:-\s*)?(?:file|part):\s*)[\"']?([^\s\"'#]+\.qmd)[\"']?\s*(?:#.*)?$", text)))


def check_rendered(chapters: tuple[str, ...], errors: list[str]) -> None:
    output = BOOK / "_book"
    documents: dict[Path, ImageAltChecker] = {}

    def document(path: Path) -> ImageAltChecker:
        if path not in documents:
            parsed = ImageAltChecker()
            parsed.feed(path.read_text(encoding="utf-8"))
            documents[path] = parsed
        return documents[path]

    for chapter in chapters:
        relative = str(Path(chapter).with_suffix(".html"))
        path = output / relative
        if not path.is_file():
            fail(errors, f"falta artefacto renderizado: ebook/_book/{relative}")
            continue
        html = document(path)
        for src in html.missing:
            fail(errors, f"imagen HTML sin texto alternativo en {relative}: {src}")
        for target in html.targets:
            parsed = urlparse(target)
            if parsed.scheme or parsed.netloc:
                continue
            destination = ((output / unquote(parsed.path).lstrip("/")) if parsed.path.startswith("/")
                           else (path.parent / unquote(parsed.path)) if parsed.path else path)
            destination = destination.resolve()
            if not destination.is_relative_to(output.resolve()):
                fail(errors, f"destino local fuera del libro en {relative}: {target}")
                continue
            if destination.is_dir():
                destination /= "index.html"
            if not destination.is_file():
                fail(errors, f"destino local inexistente en {relative}: {target}")
            elif parsed.fragment and destination.suffix == ".html":
                if unquote(parsed.fragment) not in document(destination).ids:
                    fail(errors, f"ancla local inexistente en {relative}: {target}")

        # The linked Bootstrap default palette matters, not Quarto's initial body class.
        if relative == "index.html" or html.bootstrap:
            solar = False
            if len(html.bootstrap) == 1:
                link = html.bootstrap[0]
                css = (path.parent / unquote(urlparse(link.get("href") or "").path)).resolve()
                if css.is_relative_to(output.resolve()) and css.is_file():
                    text = css.read_text(encoding="utf-8")
                    # First declarations are Bootstrap's default; later dark/light overrides do not count.
                    bg = re.search(r"--bs-body-bg:\s*([^;}]+)", text)
                    fg = re.search(r"--bs-body-color:\s*([^;}]+)", text)
                    solar = (link.get("data-mode") == "dark" and bg is not None and fg is not None
                             and bg[1].strip().lower() == "#002b36"
                             and fg[1].strip().lower() == "#adb5bd")
            if not solar:
                fail(errors, f"tema Solar oscuro no predeterminado en {relative}")

    pdf = output / "aplicaciones-web-php-csharp-semana1.pdf"
    if not pdf.is_file():
        fail(errors, f"falta PDF renderizado: {pdf.relative_to(ROOT)}")
    else:
        with pdf.open("rb") as stream:
            if stream.read(5) != b"%PDF-":
                fail(errors, f"firma PDF inválida: {pdf.relative_to(ROOT)}")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def local_path(target: str) -> bool:
    parsed = urlparse(target)
    return not parsed.scheme and not parsed.netloc and not target.startswith("#")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rendered", action="store_true",
                        help="comprueba páginas configuradas, enlaces, anclas, tema Solar oscuro y firma PDF")
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

    config = BOOK / "_quarto.yml"
    text = config.read_text(encoding="utf-8") if config.is_file() else ""
    chapters = tuple(dict.fromkeys((*CHAPTERS, *configured_chapters(text))))
    for chapter in chapters:
        if chapter not in CHAPTERS and not (BOOK / chapter).is_file():
            fail(errors, f"falta la superficie requerida: ebook/{chapter}")
    qmd_files = [BOOK / chapter for chapter in chapters if (BOOK / chapter).is_file()]
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

    if config.is_file():
        for chapter in CHAPTERS:
            if chapter not in text:
                fail(errors, f"capítulo no configurado: {chapter}")

    if args.rendered:
        check_rendered(chapters, errors)

    if errors:
        print("Comprobación estructural fallida:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Comprobación estructural correcta.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
