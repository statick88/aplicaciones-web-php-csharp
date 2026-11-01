"""Public HTTP regression tests for the isolated, stateless PHP method lab."""

import http.client
import json
import shutil
import socket
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "examples/http-methods"


class PhpHttpLab(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.temp.name) / "http-methods"
        shutil.copytree(SOURCE, cls.root)
        (Path(cls.temp.name) / "outside-private.txt").write_text("PRIVATE-LAB-SENTINEL")
        probe = socket.socket()
        probe.bind(("127.0.0.1", 0))
        cls.port = probe.getsockname()[1]
        probe.close()
        cls.server = subprocess.Popen(
            ["/usr/bin/php", "-S", f"127.0.0.1:{cls.port}", "-t", str(cls.root), str(cls.root / "router.php")],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
        )
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            try:
                connection = http.client.HTTPConnection("127.0.0.1", cls.port, timeout=1)
                connection.request("GET", "/api.php?tema=red")
                response = connection.getresponse()
                response.read()
                connection.close()
                break
            except OSError:
                time.sleep(0.05)
        else:
            cls.tearDownClass()
            raise RuntimeError("PHP lab server did not start")

    @classmethod
    def tearDownClass(cls):
        if getattr(cls, "server", None):
            cls.server.terminate()
            try:
                cls.server.wait(timeout=3)
            except subprocess.TimeoutExpired:
                cls.server.kill()
                cls.server.wait(timeout=3)
        if getattr(cls, "temp", None):
            cls.temp.cleanup()

    def request(self, method, target="/api.php", body=None, headers=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=3)
        connection.request(method, target, body=body, headers=headers or {})
        response = connection.getresponse()
        raw = response.read().decode("utf-8")
        result = (response.status, dict(response.getheaders()), raw)
        connection.close()
        return result

    def assert_json(self, method, expected_status, expected_body, **kwargs):
        status, headers, raw = self.request(method, **kwargs)
        self.assertEqual(status, expected_status)
        self.assertEqual(headers["Content-Type"], "application/json; charset=utf-8")
        self.assertEqual(json.loads(raw), expected_body)
        return raw

    def test_five_methods_report_their_php_data_origins(self):
        cases = (
            ("GET", {"target": "/api.php?tema=red&nivel=basico"}, 200,
             {"ok": True, "method": "GET", "source": "$_GET", "received": {"tema": "red", "nivel": "basico"}, "saved": False}),
            ("POST", {"body": "nombre=Ada&curso=Web", "headers": {"Content-Type": "application/x-www-form-urlencoded"}}, 200,
             {"ok": True, "method": "POST", "source": "$_POST", "received": {"nombre": "Ada", "curso": "Web"}, "saved": False}),
            ("PUT", {"body": '{"id":42,"nombre":"Libro"}', "headers": {"Content-Type": "application/json"}}, 200,
             {"ok": True, "method": "PUT", "source": "php://input + json_decode", "received": {"id": 42, "nombre": "Libro"}, "saved": False}),
            ("PATCH", {"body": '{"id":42,"precio":19.9}', "headers": {"Content-Type": "application/json"}}, 200,
             {"ok": True, "method": "PATCH", "source": "php://input + json_decode", "received": {"id": 42, "precio": 19.9}, "saved": False}),
            ("DELETE", {"target": "/api.php?id=42"}, 200,
             {"ok": True, "method": "DELETE", "source": "$_GET", "received": {"id": "42"}, "saved": False, "simulation": "No se eliminó ningún dato."}),
        )
        for method, kwargs, status, body in cases:
            with self.subTest(method=method):
                self.assert_json(method, status, body, **kwargs)

    def test_does_not_expose_php_version_header_on_success_or_error(self):
        for method, target, request_headers in (
            ("GET", "/api.php?tema=red", {}),
            ("GET", "/api.php?secreto=no", {"Host": "localhost"}),
        ):
            with self.subTest(target=target):
                _, response_headers, _ = self.request(method, target, headers=request_headers)
                self.assertNotIn("X-Powered-By", response_headers)

    def test_repeating_requests_is_stateless(self):
        kwargs = {"body": '{"id":42,"precio":19.9}', "headers": {"Content-Type": "application/json"}}
        first = self.assert_json("PATCH", 200, {"ok": True, "method": "PATCH", "source": "php://input + json_decode", "received": {"id": 42, "precio": 19.9}, "saved": False}, **kwargs)
        second = self.assert_json("PATCH", 200, {"ok": True, "method": "PATCH", "source": "php://input + json_decode", "received": {"id": 42, "precio": 19.9}, "saved": False}, **kwargs)
        self.assertEqual(first, second)

    def test_rejects_non_loopback_host_without_echoing_input(self):
        status, headers, raw = self.request("GET", "/api.php?secreto=no", headers={"Host": "localhost"})
        self.assertEqual(status, 403)
        self.assertEqual(headers["Content-Type"], "application/json; charset=utf-8")
        self.assertEqual(json.loads(raw), {"ok": False, "error": "Este laboratorio solo acepta el host 127.0.0.1."})
        self.assertNotIn("secreto", raw)

    def test_isolated_document_root_does_not_serve_parent_files(self):
        status, _, raw = self.request("GET", "/..%2Foutside-private.txt")
        self.assertEqual(status, 404)
        self.assertNotIn("PRIVATE-LAB-SENTINEL", raw)

    def test_rejects_unsupported_method_without_state_change(self):
        before = self.request("GET", "/api.php?tema=red")
        status, headers, raw = self.request("OPTIONS", "/api.php")
        after = self.request("GET", "/api.php?tema=red")
        self.assertEqual(status, 405)
        self.assertEqual(headers["Allow"], "GET, POST, PUT, PATCH, DELETE")
        self.assertEqual(json.loads(raw), {"ok": False, "error": "Método no permitido."})
        self.assertEqual(before, after)

    def test_rejects_wrong_media_type_and_malformed_json_without_state_change(self):
        baseline = self.request("GET", "/api.php?tema=red")
        for body, content_type, expected_status, expected_error in (
            ('{"id":42}', "text/plain", 415, "Usa Content-Type: application/json."),
            ('{"id":', "application/json", 400, "El cuerpo no contiene JSON válido."),
        ):
            with self.subTest(status=expected_status):
                status, _, raw = self.request("PUT", body=body, headers={"Content-Type": content_type})
                self.assertEqual(status, expected_status)
                self.assertEqual(json.loads(raw), {"ok": False, "error": expected_error})
                self.assertEqual(self.request("GET", "/api.php?tema=red"), baseline)


if __name__ == "__main__":
    unittest.main()
