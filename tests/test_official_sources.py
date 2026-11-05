"""Published study pages cite official or primary sources, not local source files."""
from pathlib import Path
from html.parser import HTMLParser
import json
import re
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
EBOOK = ROOT / "ebook"
PUBLISHED_PAGES = (
    EBOOK / "index.md",
    EBOOK / "answers.md",
    EBOOK / "references.md",
    *sorted((EBOOK / "chapters").glob("*.md")),
    EBOOK / "subjects/aplicaciones-web.md",
    *sorted((EBOOK / "subjects/aplicaciones-web").rglob("*.md")),
    EBOOK / "subjects/arquitectura-software.md",
    *sorted((EBOOK / "subjects/arquitectura-software").rglob("*.md")),
)


class OfficialSourcesTests(unittest.TestCase):
    def test_visible_provenance_never_presents_local_markdown_as_authority(self):
        for page in PUBLISHED_PAGES:
            with self.subTest(page=page.relative_to(ROOT)):
                source = page.read_text(encoding="utf-8")
                visible = re.sub(r"\]\([^)]+\)", "]", source)
                self.assertNotRegex(visible, r"(?i)(semana2(?:-clase2)?|README)\.md")
                self.assertNotIn("statick88", source.lower())
                self.assertNotRegex(source, r"https?://[^)\s]+\.md(?:[?#][^)\s]*)?")
                self.assertNotRegex(source, r"@(?:practice-repo|assignment-repo|course-web-week2-class[12])\b")

    def test_generated_reader_pages_never_link_markdown_or_personal_sources(self):
        class ReaderPage(HTMLParser):
            def __init__(self):
                super().__init__()
                self.links = []
                self.text = []
                self.skip = 0
            def handle_starttag(self, tag, attrs):
                if tag in ("script", "style"):
                    self.skip += 1
                link = dict(attrs).get("href")
                if link:
                    self.links.append(link)
            def handle_endtag(self, tag):
                if tag in ("script", "style"):
                    self.skip = max(0, self.skip - 1)
            def handle_data(self, text):
                if not self.skip:
                    self.text.append(text)
        with tempfile.TemporaryDirectory() as temporary:
            result = subprocess.run([sys.executable, "-B", str(ROOT / "tools/build_site.py"), "--output", temporary], capture_output=True, text=True)
            self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "Site output is valid.\n", ""))
            catalog = json.loads((ROOT / "course/catalog.json").read_text())
            for href in ["index.html"] + [page["href"] for page in catalog["pages"]]:
                with self.subTest(page=href):
                    page = ReaderPage()
                    page.feed((Path(temporary) / href).read_text())
                    self.assertNotRegex(" ".join(page.text), r"(?i)\b[\w-]+\.md\b")
                    for link in page.links:
                        self.assertNotRegex(link, r"(?i)\.md(?:[?#]|$)")
                        self.assertNotIn("github.com/statick88/", link)

    def test_every_citation_key_used_by_published_pages_exists(self):
        bibliography = (EBOOK / "references.bib").read_text(encoding="utf-8")
        known_keys = set(re.findall(r"^@\w+\{([^,]+),", bibliography, re.MULTILINE))
        for page in PUBLISHED_PAGES:
            citation_groups = re.findall(r"\[([^]]*@[^]]+)\]", page.read_text(encoding="utf-8"))
            cited_keys = {
                key
                for group in citation_groups
                for key in re.findall(r"@([\w-]+)", group)
            }
            with self.subTest(page=page.relative_to(ROOT)):
                self.assertTrue(cited_keys <= known_keys)


if __name__ == "__main__":
    unittest.main()
