#!/usr/bin/env python3
"""Build the public documentation site from course/catalog.json (without Quarto)."""
from __future__ import annotations

import argparse
import html
import json
import os
import re
import shutil
import sys
import tempfile
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse

try:
    import markdown
except ImportError:
    markdown = None

ROOT = Path(__file__).resolve().parents[1]
GITHUB = "https://github.com/statick88/aplicaciones-web-php-csharp/blob/main/"
CITATION = re.compile(r"\[@([\w:-]+)(?:;\s*@([\w:-]+))*\]", re.S)
BIB_ENTRY = re.compile(r"@(\w+)\s*\{\s*([^,]+),\s*(.*?)\n\}", re.S)
FIELD = re.compile(r'(\w+)\s*=\s*({(?:[^{}]|{[^{}]*})*}|"[^"]*")', re.S)
FIGURE = re.compile(r"!\[([^]]*)\]\(([^)]+)\)\{([^}]*)\}")
IMAGE = re.compile(r"!\[[^]]*\]\(([^)]+)\)")
ATTR = re.compile(r'([\w-]+)=(?:"([^"]*)"|([^\s]+))|#([\w-]+)')
FRONT_MATTER = re.compile(r"\A---\s*\n.*?\n---\s*(?:\n|\Z)", re.S)
ATX_H1 = re.compile(r"^#\s+(.+?)\s*$", re.M)


def fail(message: str) -> int:
    print(f"build_site: {message}", file=sys.stderr)
    return 2


def catalog_data(root: Path) -> tuple[dict, dict[str, str]]:
    catalog = json.loads((root / "course/catalog.json").read_text(encoding="utf-8"))
    if catalog.get("schemaVersion") != 1:
        raise ValueError("course/catalog.json schemaVersion must be 1")
    pages = catalog.get("pages")
    if not isinstance(pages, list) or not pages:
        raise ValueError("course/catalog.json pages must be a non-empty list")
    mapping: dict[str, str] = {}
    for page in pages:
        source, href = page.get("source"), page.get("href")
        parsed_href = urlparse(href) if isinstance(href, str) else None
        source_path = (root / source).resolve() if isinstance(source, str) else None
        try:
            safe_source = source_path is not None and source_path.is_relative_to((root / "ebook").resolve())
        except OSError:
            safe_source = False
        decoded_href = unquote(parsed_href.path) if parsed_href else ""
        safe_href = (parsed_href is not None and not parsed_href.scheme and not parsed_href.netloc
                     and decoded_href.endswith(".html") and not Path(decoded_href).is_absolute()
                     and "\\" not in decoded_href and ".." not in Path(decoded_href).parts
                     and not parsed_href.query and not parsed_href.fragment)
        if not isinstance(source, str) or not source.endswith(".md") or not safe_source or not safe_href:
            raise ValueError("each page needs safe ebook/*.md source and safe relative *.html href")
        if source in mapping or href in mapping.values():
            raise ValueError(f"duplicate catalog page: {source if source in mapping else href}")
        if not source_path.is_file():
            raise ValueError(f"catalog source is missing: {source}")
        mapping[source] = href
    units = [unit for module in catalog.get("modules", []) for unit in module.get("units", [])]
    for unit in units:
        if mapping.get(unit.get("source")) != unit.get("href"):
            raise ValueError(f"module unit is not a catalog page: {unit.get('source')}")
    return catalog, mapping


def bibliography(root: Path) -> dict[str, dict[str, str]]:
    entries = {}
    for kind, key, body in BIB_ENTRY.findall((root / "ebook/references.bib").read_text(encoding="utf-8")):
        fields = {name.lower(): value.replace("\n", " ").strip().strip('{}"') for name, value in FIELD.findall(body)}
        fields["kind"] = kind
        entries[key.strip()] = fields
    return entries


def attrs(text: str) -> dict[str, str]:
    result = {}
    for name, quoted, bare, identifier in ATTR.findall(text):
        if identifier:
            result["id"] = identifier
        else:
            result[name] = quoted or bare
    return result


def html_attributes(data: dict[str, str], classes: list[str]) -> str:
    values = dict(data)
    if classes:
        values["class"] = " ".join(classes)
    return "".join(f' {name}="{html.escape(value, quote=True)}"' for name, value in values.items())


def convert_fences(text: str) -> str:
    """Turn Quarto div fences into HTML blocks that Markdown may render inside."""
    result: list[str] = []
    stack: list[str] = []
    for line in text.splitlines(keepends=True):
        match = re.match(r"^:::\s*\{([^}]*)\}\s*\n?$", line)
        if match:
            raw = match.group(1)
            classes = re.findall(r"\.([\w-]+)", raw)
            data = attrs(raw)
            if any(item.startswith("callout-") for item in classes):
                tag = "aside"
                classes.insert(0, "callout")
            else:
                tag = "div"
            result.append(f"<{tag}{html_attributes(data, classes)} markdown=\"1\">\n")
            stack.append(tag)
        elif re.match(r"^:::\s*\n?$", line) and stack:
            result.append(f"</{stack.pop()}>\n")
        else:
            result.append(line)
    return "".join(result)


def extract_heading(text: str) -> tuple[str, str]:
    """Remove the source H1 because the page template owns the document H1."""
    match = ATX_H1.search(text)
    if not match:
        return text, ""
    heading = match.group(1)
    identifier = ""
    id_match = re.search(r"\s+\{#([\w-]+)\}\s*$", heading)
    if id_match:
        identifier = id_match.group(1)
    return text[:match.start()] + text[match.end():], identifier


def preprocess(text: str, source: Path, mapping: dict[str, str], bib: dict[str, dict[str, str]]) -> tuple[str, str]:
    text = FRONT_MATTER.sub("", text, count=1)
    text, heading_id = extract_heading(text)

    def figure(match: re.Match) -> str:
        alt, target, raw = match.groups()
        data = attrs(raw)
        caption = data.get("fig-cap", alt)
        image_alt = data.get("fig-alt", alt)
        ident = f' id="{html.escape(data["id"], quote=True)}"' if data.get("id") else ""
        src = html.escape(rewrite_url(target, source, mapping), quote=True)
        return f'<figure{ident}><img src="{src}" alt="{html.escape(image_alt, quote=True)}"><figcaption>{html.escape(caption)}</figcaption></figure>'

    text = FIGURE.sub(figure, text)

    def cite(match: re.Match) -> str:
        keys = re.findall(r"@([\w:-]+)", match.group(0))
        unknown = [key for key in keys if key not in bib]
        if unknown:
            raise ValueError(f"citation missing from references.bib: @{unknown[0]}")
        return " ".join(f'<a class="citation" href="references.html#ref-{html.escape(key)}">[{html.escape(key)}]</a>' for key in keys)

    return convert_fences(CITATION.sub(cite, text)), heading_id


def rewrite_url(value: str, source: Path, mapping: dict[str, str]) -> str:
    parsed = urlparse(value)
    if parsed.scheme or parsed.netloc or not parsed.path:
        return value
    target = (source.parent / unquote(parsed.path)).resolve()
    try:
        relative = target.relative_to(ROOT).as_posix()
    except ValueError:
        return value
    if relative in mapping:
        base = mapping[relative]
    elif relative.startswith(("php/", "csharp/")):
        base = GITHUB + relative
    elif relative.startswith("ebook/assets/"):
        base = "assets/" + relative.removeprefix("ebook/assets/")
    elif relative.startswith("ebook/examples/http-methods/"):
        base = "examples/http-methods/" + relative.removeprefix("ebook/examples/http-methods/")
    else:
        return value
    return base + (("?" + parsed.query) if parsed.query else "") + (("#" + parsed.fragment) if parsed.fragment else "")


def relative_url(current: str, target: str) -> str:
    parsed = urlparse(target)
    relative = Path(os.path.relpath(parsed.path, Path(current).parent)).as_posix() if parsed.path else ""
    return relative + (("?" + parsed.query) if parsed.query else "") + (("#" + parsed.fragment) if parsed.fragment else "")


def render_page(text: str, source: Path, href: str, mapping: dict[str, str], bib: dict[str, dict[str, str]], template: str, catalog: dict) -> str:
    prepared, heading_id = preprocess(text, source, mapping, bib)
    body = markdown.markdown(prepared, extensions=["tables", "fenced_code", "attr_list", "toc", "md_in_html"], output_format="html5")
    if source.name == "references.md":
        items = []
        for key, entry in bib.items():
            title = html.escape(entry.get("title", key))
            author = html.escape(entry.get("author", ""))
            year = html.escape(entry.get("year", ""))
            url = entry.get("url")
            tail = f' <a href="{html.escape(url, quote=True)}">{html.escape(url)}</a>' if url else ""
            items.append(f'<li id="ref-{html.escape(key, quote=True)}">{author}. {title}. {year}.{tail}</li>')
        body += '<h2>Referencias</h2><ol class="references">' + "".join(items) + "</ol>"

    def url_attribute(match: re.Match) -> str:
        name, quote, value = match.group(1), match.group(2), html.unescape(match.group(3))
        rewritten = rewrite_url(value, source, mapping)
        parsed = urlparse(rewritten)
        if not (parsed.scheme or parsed.netloc) and parsed.path:
            rewritten = relative_url(href, rewritten)
        return f'{name}={quote}{html.escape(rewritten, quote=True)}{quote}'

    body = re.sub(r'\b(href|src)=(["\'])(.*?)\2', url_attribute, body)
    def sidebar_list(pages: list[dict]) -> str:
        items = []
        for page in pages:
            current = ' aria-current="page"' if page["href"] == href else ""
            url = html.escape(relative_url(href, page["href"]), quote=True)
            items.append(f'<li><a href="{url}"{current}>{html.escape(page["title"])}</a></li>')
        return '<ul class="sidebar-list">' + "".join(items) + '</ul>'

    nav_parts = ['<p class="eyebrow">RECORRIDO</p>']
    ordered_units = []
    context = "Material complementario"
    for module in catalog.get("modules", []):
        units = module.get("units", [])
        ordered_units.extend(units)
        label = f"Semana {module['week']} · {module['title']}"
        nav_parts.append(f'<h2 class="sidebar-module">{html.escape(module["title"])}</h2>')
        nav_parts.append(sidebar_list(units))
        if any(unit["href"] == href for unit in units):
            context = label
    unit_hrefs = {unit["href"] for unit in ordered_units}
    supplementary = [page for page in catalog["pages"] if page["href"] not in unit_hrefs]
    nav_parts.append('<h2 class="sidebar-module">Material complementario y otras asignaturas</h2>')
    nav_parts.append(sidebar_list(supplementary))
    nav = "".join(nav_parts)
    pages = ordered_units if href in unit_hrefs else supplementary
    position = next(i for i, page in enumerate(pages) if page["href"] == href)
    pagination = " ".join(f'<a class="secondary-cta" href="{html.escape(relative_url(href, pages[i]["href"]), quote=True)}">{label}</a>' for i, label in ((position - 1, "← Anterior"), (position + 1, "Siguiente →")) if 0 <= i < len(pages))
    title = next(page["title"] for page in pages if page["href"] == href)
    return (template.replace("{{root}}", "../" * len(Path(href).parents[:-1]))
            .replace("{{title}}", html.escape(title))
            .replace("{{heading_id}}", f' id="{html.escape(heading_id, quote=True)}"' if heading_id else "")
            .replace("{{content}}", body).replace("{{navigation}}", nav)
            .replace("{{pagination}}", pagination).replace("{{week}}", html.escape(context)))


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids: set[str] = set()
        self.urls: list[str] = []

    def handle_starttag(self, tag, attributes):
        data = dict(attributes)
        if data.get("id"):
            self.ids.add(data["id"])
        for key in ("href", "src"):
            if data.get(key):
                self.urls.append(data[key])


def validate(output: Path) -> list[str]:
    if not output.is_dir():
        return ["output directory does not exist"]
    output = output.resolve()
    docs: dict[Path, Links] = {}
    errors: list[str] = []
    for path in output.rglob("*.html"):
        parser = Links()
        parser.feed(path.read_text(encoding="utf-8"))
        docs[path.resolve()] = parser
    if not docs:
        return ["output contains no HTML documents"]
    for path, parser in docs.items():
        for value in parser.urls:
            parsed = urlparse(value)
            if parsed.scheme or parsed.netloc:
                continue
            target = path if not parsed.path else ((output / unquote(parsed.path).lstrip("/")) if parsed.path.startswith("/") else (path.parent / unquote(parsed.path)))
            target = target.resolve()
            if not target.exists():
                errors.append(f"{path.relative_to(output)}: missing destination {value}")
            elif parsed.fragment and target.suffix == ".html" and parsed.fragment not in docs.get(target, Links()).ids:
                errors.append(f"{path.relative_to(output)}: missing fragment {value}")
    return errors


def copy_public_assets(root: Path, output: Path, pages: list[dict]) -> None:
    """Copy only referenced editorial assets plus the intentionally public HTTP lab."""
    for page in pages:
        source = root / page["source"]
        for target in IMAGE.findall(source.read_text(encoding="utf-8")):
            asset = (source.parent / unquote(target)).resolve()
            try:
                relative = asset.relative_to(root / "ebook/assets")
            except ValueError:
                continue
            if asset.is_file():
                destination = output / "assets" / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(asset, destination)
    # Preserve the published PDF URL as an explicitly archived, immutable edition.
    archive = root / "ebook/downloads/aplicaciones-web-php-csharp-semana1.pdf"
    if archive.is_file():
        shutil.copy2(archive, output / archive.name)
    lab = root / "ebook/examples/http-methods"
    if lab.is_dir():
        shutil.copytree(lab, output / "examples/http-methods", dirs_exist_ok=True)


def output_path(output: Path) -> Path:
    output = output.absolute()
    for path in (output, *output.parents):
        if path.exists():
            if path.is_symlink():
                raise ValueError(f"output path is a symlink: {path}")
            if not path.is_dir():
                raise ValueError(f"output path is not a directory: {path}")
    return output


def publish(stage: Path, output: Path) -> None:
    files = [path for path in stage.rglob("*") if path.is_file()]
    for source in files:
        destination = output / source.relative_to(stage)
        for path in (destination.parent, *destination.parent.parents):
            if path == output.parent:
                break
            if path.exists() and (path.is_symlink() or not path.is_dir()):
                raise ValueError(f"output path is not a directory: {path}")
        if destination.is_symlink() or (destination.exists() and not destination.is_file()):
            raise ValueError(f"output path is not a file: {destination}")
    backup = stage / ".backup"; moved = []; written = []
    try:
        for source in files:
            destination = output / source.relative_to(stage)
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.exists():
                saved = backup / source.relative_to(stage); saved.parent.mkdir(parents=True, exist_ok=True)
                os.replace(destination, saved); moved.append((saved, destination))
            os.replace(source, destination); written.append(destination)
    except OSError:
        for destination in reversed(written):
            if destination.exists():
                destination.unlink()
        for saved, destination in reversed(moved):
            os.replace(saved, destination)
        raise


def build(root: Path, output: Path, check: bool = False) -> int:
    try:
        catalog, mapping = catalog_data(root)
        bib = bibliography(root)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return fail(str(exc))
    if check:
        errors = validate(output)
        if errors:
            return fail("invalid output:\n" + "\n".join(errors))
        print("Site output is valid.")
        return 0
    if markdown is None:
        return fail("Markdown is required; install requirements-docs.txt")
    template_path = root / "site/page.html"
    if not template_path.is_file():
        return fail("missing required template: site/page.html")
    try:
        output = output_path(output)
        output.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix=".build-site-", dir=output.parent) as temp:
            stage = Path(temp); template = template_path.read_text(encoding="utf-8")
            for page in catalog["pages"]:
                destination = stage / page["href"]; destination.parent.mkdir(parents=True, exist_ok=True)
                source = root / page["source"]
                destination.write_text(render_page(source.read_text(encoding="utf-8"), source, page["href"], mapping, bib, template, catalog), encoding="utf-8")
            for name in ("index.html", "app.mjs", "course-utils.mjs", "styles.css"):
                source = root / "site" / name
                if source.is_file(): shutil.copy2(source, stage / name)
            copy_public_assets(root, stage, catalog["pages"])
            public = {key: value for key, value in catalog.items() if key != "pages"}
            public["modules"] = [{key: value for key, value in module.items() if key != "source"} for module in catalog.get("modules", [])]
            for module in public["modules"]:
                module["units"] = [{key: value for key, value in unit.items() if key != "source"} for unit in module.get("units", [])]
            public["pages"] = [{key: value for key, value in page.items() if key != "source"} for page in catalog["pages"]]
            (stage / "course.json").write_text(json.dumps(public, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            (stage / ".nojekyll").write_text("", encoding="utf-8")
            errors = validate(stage)
            if errors: return fail("invalid output:\n" + "\n".join(errors))
            publish(stage, output)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return fail(str(exc))
    print("Site output is valid.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the static course site without Quarto.")
    parser.add_argument("--output", type=Path, required=True, help="destination directory (preserved on build failure, never cleaned)")
    parser.add_argument("--check", action="store_true", help="validate an existing output directory only")
    args = parser.parse_args()
    return build(ROOT, args.output, args.check)


if __name__ == "__main__":
    raise SystemExit(main())
