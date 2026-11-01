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


if __name__ == "__main__":
    unittest.main()
