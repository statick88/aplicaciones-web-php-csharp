#!/usr/bin/env python3
"""Render the eight original diagrams as portable Fira glyph-outline SVGs."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

BOOK = Path(__file__).resolve().parents[1]
SVG = "{http://www.w3.org/2000/svg}"
FAMILY = "FiraCode Nerd Font"
DIAGRAMS = (
    "request-response.svg", "request-response-csharp.svg", "runtime-comparison.svg",
    "runtime-csharp.svg", "scope.svg", "scope-csharp.svg",
    "arquitectura-semana1.svg", "arquitectura-semana2.svg",
)
FONT_HASHES = {
    "FiraCodeNerdFont-Regular.ttf": "22d18aa0eac12ee0416e12dda68168d3610ce71521e6faf272b8615a6c5f0f30",
    "FiraCodeNerdFont-Bold.ttf": "cccf05a2ea6e63a00855afdf70ba84971310bbded6ed13f4cd9b226f49bd8b79",
}
ET.register_namespace("", SVG[1:-1])
ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def safe_svg(root, outlined=False):
    forbidden = {SVG + "script", SVG + "image", SVG + "foreignObject"}
    if outlined:
        forbidden.add(SVG + "text")
    for element in root.iter():
        if element.tag in forbidden:
            raise ValueError("Unsupported SVG content")
        for key, value in element.attrib.items():
            if key.endswith("href") and not value.startswith("#"):
                raise ValueError("External SVG resources are not allowed")


def inputs():
    fonts = BOOK / "assets/fonts/fira-code-nerd"
    for name, expected in FONT_HASHES.items():
        if digest((fonts / name).read_bytes()) != expected:
            raise ValueError("Bundled font changed: " + name)
    result = []
    for name in DIAGRAMS:
        source = BOOK / "diagrams" / name
        data = source.read_bytes()
        root = ET.fromstring(data)
        safe_svg(root)
        title, description = root.find(SVG + "title"), root.find(SVG + "desc")
        if title is None or description is None or not title.text or not description.text:
            raise ValueError("Missing accessible source description: " + name)
        labels = [" ".join("".join(e.itertext()).split()) for e in root.iter(SVG + "text")]
        if not labels or FAMILY not in data.decode():
            raise ValueError("Missing editable Fira text: " + name)
        meta = {"font_family": FAMILY, "rendering": "glyph-outlines", "source": "diagrams/" + name,
                "source_sha256": digest(data), "font_sha256": FONT_HASHES, "labels": labels,
                "title": title.text, "description": description.text}
        result.append((name, source, root, meta))
    return result


def check_output(path, expected):
    root = ET.parse(path).getroot()
    safe_svg(root, outlined=True)
    metadata = root.find(SVG + "metadata")
    if metadata is None:
        raise ValueError("Stale diagram: " + path.name)
    actual = json.loads(metadata.text)
    if any(actual.get(key) != value for key, value in expected.items()):
        raise ValueError("Stale diagram: " + path.name)
    if root.findtext(SVG + "title") != expected["title"] or root.findtext(SVG + "desc") != expected["description"]:
        raise ValueError("Changed accessible description: " + path.name)
    if not list(root.iter(SVG + "path")) or root.get("role") != "img":
        raise ValueError("Invalid portable diagram: " + path.name)


def render(prepared):
    for tool in ("rsvg-convert", "fc-match"):
        if shutil.which(tool) is None:
            raise ValueError("Required local rendering tool not found: " + tool)
    fonts = (BOOK / "assets/fonts/fira-code-nerd").resolve()
    scratch_root = BOOK.parent / ".atl"
    scratch_root.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="diagram-fonts-", dir=scratch_root) as tmp:
        tmp = Path(tmp)
        cache = tmp / "cache"
        cache.mkdir()
        config = tmp / "fonts.conf"
        config.write_text("<?xml version=\"1.0\"?><fontconfig><dir>" + escape(str(fonts)) +
                          "</dir><cachedir>" + escape(str(cache)) + "</cachedir></fontconfig>")
        env = dict(os.environ, FONTCONFIG_FILE=str(config), FONTCONFIG_PATH=str(tmp))
        for style in ("Regular", "Bold"):
            selected = subprocess.check_output(["fc-match", "-f", "%{file}", FAMILY + ":style=" + style], env=env).decode()
            if Path(selected).resolve() != fonts / ("FiraCodeNerdFont-" + style + ".ttf"):
                raise ValueError("Renderer did not select the bundled Fira " + style)
        # Validate and stage every output before replacing any public asset.
        for name, source, original, meta in prepared:
            output = tmp / name
            subprocess.run(["rsvg-convert", "--format=svg", "--output", str(output), str(source)], env=env, capture_output=True, check=True)
            root = ET.parse(output).getroot()
            root.set("width", original.get("width"))
            root.set("height", original.get("height"))
            root.set("role", "img")
            root.set("aria-labelledby", "diagram-title diagram-description")
            title = ET.Element(SVG + "title", id="diagram-title")
            title.text = original.find(SVG + "title").text
            desc = ET.Element(SVG + "desc", id="diagram-description")
            desc.text = original.find(SVG + "desc").text
            metadata = ET.Element(SVG + "metadata", id="diagram-typography")
            metadata.text = json.dumps(meta, ensure_ascii=False)
            root.insert(0, title)
            root.insert(1, desc)
            root.insert(2, metadata)
            ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
            check_output(output, meta)
        for name, _, _, _ in prepared:
            os.replace(tmp / name, BOOK / "assets" / name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate existing SVG outlines and source/font hashes without writing")
    args = parser.parse_args()
    try:
        prepared = inputs()
        if args.check:
            for name, _, _, meta in prepared:
                check_output(BOOK / "assets" / name, meta)
            print("Checked 8 portable Fira diagrams.")
        else:
            render(prepared)
            print("Rendered 8 portable Fira diagrams.")
    except (OSError, ValueError, ET.ParseError, subprocess.CalledProcessError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
