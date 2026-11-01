"""Portable Fira diagrams preserve editable text and genuine browser evidence."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

BOOK = Path(__file__).resolve().parents[1]
SVG = "{http://www.w3.org/2000/svg}"
LABEL_HASHES = {
    "request-response.svg": "a5485041be74b5ad72b63d8808836892a8e2ba0201a59b901139207cb1a931a1",
    "request-response-csharp.svg": "c982b4db92639f7bf14be195ad44a2607593ed101d042890a04d25ba9059c95d",
    "runtime-comparison.svg": "c735af57763601c7cd6de96bcd65c552c03d27540c76855abeb835a731a882cf",
    "runtime-csharp.svg": "ae7ffcad6b3eeaf85f86c10ea7d9ef4bb5f562881a4a1e9e02cb8900d1fdc1af",
    "scope.svg": "c6fd1e48d6d4dff530217d18efb1d2fe454ceb3ffd32150c88cba06daf58dcfa",
    "scope-csharp.svg": "56436a1820cba97b22819cb4b94b9f54a7c6c8c99f64cfaee4db3b42bc6e1388",
    "arquitectura-semana1.svg": "460f4d04a6459bf1a49271884c5bc25368e2518458c0cab3a1db03b617d98995",
    "arquitectura-semana2.svg": "6a4861da74fdf68992b7b437a3fab037ca6586a2903ffd172bae15256b972ba2",
}
CAPTURE_HASHES = {
    "http-lab-delete.png": "80c1ddee75534a008dc924a0cf7f65dce78d71840a8ad4f5de2e28caa105e730",
    "http-lab-get.png": "86df180c07b0c6a591a1e2d2ef3bea318922afb5c3ae1ddfe52a456a290e97be",
    "http-lab-patch.png": "eae9917b5c6415437591722760daabd1bcb30a919c95fb8b8a7bf0de2d8c1d35",
    "http-lab-post.png": "02b83a8f1a6b7eb48b2037ff80030d89799eb272a99b49e44caa7d8af216aa93",
    "http-lab-put.png": "3d23b043ffa0ad974d6bb42c0225468916f3096fdf7580f8d069a3b7d85935e7",
}



def digest(data):
    return hashlib.sha256(data).hexdigest()


PORTABLE = ('request-response.svg', 'request-response-csharp.svg', 'runtime-comparison.svg', 'runtime-csharp.svg', 'scope.svg', 'scope-csharp.svg', 'arquitectura-semana1.svg', 'arquitectura-semana2.svg')

class DiagramTypography(unittest.TestCase):
    def test_editable_sources_keep_every_original_label(self):
        for filename, expected in LABEL_HASHES.items():
            source = BOOK / "diagrams" / filename
            root = ET.parse(source).getroot()
            labels = [" ".join("".join(e.itertext()).split()) for e in root.iter(SVG + "text")]
            self.assertEqual(digest(json.dumps(labels, ensure_ascii=False).encode()), expected)
            self.assertIn("FiraCode Nerd Font", source.read_text())
            self.assertTrue(root.findtext(SVG + "title"))
            self.assertTrue(root.findtext(SVG + "desc"))


    def test_genuine_devtools_captures_are_unchanged(self):
        for filename, expected in CAPTURE_HASHES.items():
            self.assertEqual(digest((BOOK / "assets" / filename).read_bytes()), expected, filename)


    @unittest.skipUnless(shutil.which("rsvg-convert") and shutil.which("fc-match"), "Optional local diagram renderer is unavailable")
    def test_renderer_round_trip_and_stale_check_without_state_change(self):
        with tempfile.TemporaryDirectory() as tmp:
            book = Path(tmp) / "ebook"
            for directory in ["diagrams", "scripts", "assets/fonts/fira-code-nerd"]:
                shutil.copytree(BOOK / directory, book / directory)
            for name in (*LABEL_HASHES, *CAPTURE_HASHES):
                shutil.copy2(BOOK / "assets" / name, book / "assets" / name)
            command = [sys.executable, str(book / "scripts/render_diagram_fonts.py")]
            run = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual((run.returncode, run.stdout, run.stderr), (0, "Rendered 8 portable Fira diagrams.\n", ""))
            run = subprocess.run(command + ["--check"], capture_output=True, text=True)
            self.assertEqual((run.returncode, run.stdout, run.stderr), (0, "Checked 8 portable Fira diagrams.\n", ""))
            for name, sha in CAPTURE_HASHES.items():
                self.assertEqual(digest((book / "assets" / name).read_bytes()), sha)
            for name in LABEL_HASHES:
                root = ET.parse(book / "assets" / name).getroot()
                self.assertFalse(list(root.iter(SVG + "text")))
                self.assertTrue(list(root.iter(SVG + "path")))
            source = book / "diagrams/request-response.svg"
            source.write_bytes(source.read_bytes() + b"\n")
            before = {name: (book / "assets" / name).read_bytes() for name in (*LABEL_HASHES, *CAPTURE_HASHES)}
            run = subprocess.run([sys.executable, str(book / "scripts/render_diagram_fonts.py"), "--check"], capture_output=True, text=True)
            self.assertEqual((run.returncode, run.stdout, run.stderr), (1, "", "Stale diagram: request-response.svg\n"))
            self.assertEqual(before, {name: (book / "assets" / name).read_bytes() for name in (*LABEL_HASHES, *CAPTURE_HASHES)})


    def test_all_original_diagrams_have_portable_exact_fira_outlines(self):
        for filename in PORTABLE:
            expected = LABEL_HASHES[filename]
            with self.subTest(diagram=filename):
                output = ET.parse(BOOK / "assets" / filename).getroot()
                self.assertEqual(list(output.iter(SVG + "text")), [])
                self.assertEqual(list(output.iter(SVG + "image")), [])
                self.assertTrue(list(output.iter(SVG + "path")))
                self.assertEqual(output.get("role"), "img")
                self.assertTrue(output.find(SVG + "title").text)
                self.assertTrue(output.find(SVG + "desc").text)
                meta = json.loads(output.find(SVG + "metadata").text)
                self.assertEqual(meta["font_family"], "FiraCode Nerd Font")
                self.assertEqual(meta["rendering"], "glyph-outlines")
                self.assertEqual(digest(json.dumps(meta["labels"], ensure_ascii=False).encode()), expected)
                source = BOOK / "diagrams" / filename
                self.assertTrue(source.is_file())
                self.assertEqual(meta["source_sha256"], digest(source.read_bytes()))
                editable = ET.parse(source).getroot()
                labels = [" ".join("".join(e.itertext()).split()) for e in editable.iter(SVG + "text")]
                self.assertEqual(labels, meta["labels"])
                self.assertEqual(output.findtext(SVG + "title"), editable.findtext(SVG + "title"))
                self.assertEqual(output.findtext(SVG + "desc"), editable.findtext(SVG + "desc"))
                self.assertEqual(len(meta["font_sha256"]), 2)
                self.assertIn("FiraCode Nerd Font", source.read_text())
                for name, sha in meta["font_sha256"].items():
                    self.assertEqual(sha, digest((BOOK / "assets/fonts/fira-code-nerd" / name).read_bytes()))
                for element in output.iter():
                    for key, value in element.attrib.items():
                        if key.endswith("href"):
                            self.assertTrue(value.startswith("#"), value)


    def test_check_command_succeeds_without_writing(self):
        assets = {name: (BOOK / "assets" / name).read_bytes() for name in LABEL_HASHES}
        run = subprocess.run([sys.executable, str(BOOK / "scripts/render_diagram_fonts.py"), "--check"], capture_output=True, text=True)
        self.assertEqual((run.returncode, run.stdout, run.stderr), (0, "Checked 8 portable Fira diagrams.\n", ""))
        self.assertEqual(assets, {name: (BOOK / "assets" / name).read_bytes() for name in LABEL_HASHES})


if __name__ == "__main__":
    unittest.main()
