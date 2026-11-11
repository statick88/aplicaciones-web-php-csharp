"""Public HTTP checks for the Week 3 Clientes MVC CRUD.

Run against an isolated, migration-enabled app with SEMANA3_BASE_URL set.
"""

import html
from html.parser import HTMLParser
import http.cookiejar
import os
import re
import unittest
import urllib.error
import urllib.parse
import urllib.request


class FormParser(HTMLParser):
    def __init__(self, source):
        super().__init__()
        self.inputs = {}
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "input" and attrs.get("name"):
            self.inputs[attrs["name"]] = attrs.get("value", "")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, newurl):
        return None


class ClientesHttpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = os.environ["SEMANA3_BASE_URL"].rstrip("/")

    def setUp(self):
        self.client = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()), NoRedirect()
        )
        self.created = []

    def request(self, path, fields=None):
        data = None if fields is None else urllib.parse.urlencode(fields).encode()
        request = urllib.request.Request(self.base + path, data=data)
        try:
            response = self.client.open(request, timeout=15)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            return response.code, response.read().decode(), response.headers

    def token(self, path):
        status, body, _ = self.request(path)
        self.assertEqual(200, status, body)
        return FormParser(body).inputs["__RequestVerificationToken"]

    def fields(self):
        return {
            "Cedula": "1801234567", "Nombres": "Ana", "Apellidos": "Perez",
            "Correo": "ana@example.test", "Telefono": "0991234567",
            "Direccion": "Calle Ficticia 123", "Ciudad": "Ambato",
            "Provincia": "Tungurahua", "FechaNacimiento": "2000-05-12",
            "Activo": "true",
        }

    def create(self):
        fields = self.fields()
        fields["__RequestVerificationToken"] = self.token("/Clientes/Create")
        status, body, headers = self.request("/Clientes/Create", fields)
        self.assertEqual(302, status, body)
        location = headers["Location"]
        self.assertRegex(location, r"^/Clientes/Details/\d+$")
        identifier = int(location.rsplit("/", 1)[1])
        self.created.append(identifier)
        return identifier

    def tearDown(self):
        for identifier in self.created:
            path = f"/Clientes/Delete/{identifier}"
            status, _, _ = self.request(path)
            if status == 200:
                token = self.token(path)
                self.request(path, {"__RequestVerificationToken": token})

    def test_crud_persists_all_ten_fields(self):
        identifier = self.create()
        status, body, _ = self.request(f"/Clientes/Details/{identifier}")
        self.assertEqual(200, status)
        for name, value in self.fields().items():
            expected = "Activo" if name == "Activo" else value
            self.assertIn(html.escape(expected), body, name)
        status, body, _ = self.request("/Clientes")
        self.assertEqual(200, status)
        self.assertIn(f'/Clientes/Details/{identifier}', body)
        edited = {
            "Cedula": "1712345678", "Nombres": "Beatriz", "Apellidos": "Lopez",
            "Correo": "beatriz@example.test", "Telefono": "0987654321",
            "Direccion": "Avenida Nueva 456", "Ciudad": "Quito",
            "Provincia": "Pichincha", "FechaNacimiento": "1998-11-20",
            "Activo": "false",
        }
        edited["__RequestVerificationToken"] = self.token(f"/Clientes/Edit/{identifier}")
        # A posted Id must never redirect the update to another row.
        edited["Id"] = "2147483647"
        status, body, headers = self.request(f"/Clientes/Edit/{identifier}", edited)
        self.assertEqual(302, status, body)
        self.assertEqual(f"/Clientes/Details/{identifier}", headers["Location"])
        status, body, _ = self.request(f"/Clientes/Details/{identifier}")
        self.assertEqual(200, status)
        for name, value in edited.items():
            if name in ("__RequestVerificationToken", "Id"):
                continue
            expected = "Inactivo" if name == "Activo" else value
            self.assertIn(html.escape(expected), body, name)
        self.assertNotIn("Ambato", body)
        token = self.token(f"/Clientes/Delete/{identifier}")
        self.assertEqual(200, self.request(f"/Clientes/Details/{identifier}")[0])
        status, body, headers = self.request(
            f"/Clientes/Delete/{identifier}", {"__RequestVerificationToken": token}
        )
        self.assertEqual(302, status, body)
        self.assertEqual("/Clientes", headers["Location"])
        self.assertEqual(404, self.request(f"/Clientes/Details/{identifier}")[0])
        self.assertNotIn(f'/Clientes/Details/{identifier}', self.request("/Clientes")[1])

    def test_invalid_create_and_edit_preserve_records(self):
        identifier = self.create()
        before_list = self.request("/Clientes")[1]
        before_detail = self.request(f"/Clientes/Details/{identifier}")[1]
        for field, value in (("Nombres", ""), ("Correo", "invalid"),
                             ("Cedula", "123"), ("Ciudad", "x" * 81),
                             ("FechaNacimiento", "not-a-date")):
            for path in ("/Clientes/Create", f"/Clientes/Edit/{identifier}"):
                with self.subTest(field=field, path=path):
                    invalid = {**self.fields(), field: value}
                    invalid["__RequestVerificationToken"] = self.token(path)
                    status, body, _ = self.request(path, invalid)
                    self.assertEqual(200, status, body)
                    self.assertRegex(body, r'class="[^"]*\bvalidation-summary-errors\b[^"]*"')
                    self.assertEqual(before_list, self.request("/Clientes")[1])
                    self.assertEqual(before_detail, self.request(f"/Clientes/Details/{identifier}")[1])

        invalid = {**self.fields(), "Correo": "invalid"}
        invalid["__RequestVerificationToken"] = self.token(f"/Clientes/Edit/{identifier}")
        status, body, _ = self.request(f"/Clientes/Edit/{identifier}", invalid)
        self.assertEqual(200, status, body)
        action = re.search(r'<form[^>]+action="([^"]+)"', body).group(1)
        self.assertEqual(f"/Clientes/Edit/{identifier}", action)
        corrected = self.fields()
        corrected["__RequestVerificationToken"] = FormParser(body).inputs["__RequestVerificationToken"]
        status, body, headers = self.request(action, corrected)
        self.assertEqual(302, status, body)
        self.assertEqual(f"/Clientes/Details/{identifier}", headers["Location"])

    def test_missing_ids_and_antiforgery(self):
        identifier = self.create()
        before = self.request(f"/Clientes/Details/{identifier}")[1]
        for action in ("Details", "Edit", "Delete"):
            self.assertEqual(404, self.request(f"/Clientes/{action}/2147483647")[0])
        for path in ("/Clientes/Create", f"/Clientes/Edit/{identifier}",
                     f"/Clientes/Delete/{identifier}"):
            self.assertEqual(400, self.request(path, self.fields())[0])
            self.assertEqual(before, self.request(f"/Clientes/Details/{identifier}")[1])

    def test_uniandes_brand_is_present_on_crud_pages(self):
        identifier = self.create()
        paths = ["/Clientes", "/Clientes/Create"] + [
            f"/Clientes/{action}/{identifier}" for action in ("Details", "Edit", "Delete")
        ]
        for path in paths:
            with self.subTest(path=path):
                status, body, _ = self.request(path)
                self.assertEqual(200, status)
                self.assertIn('alt="UNIANDES', body)
                self.assertIn(
                    'src="https://www.uniandes.edu.ec/wp-content/uploads/2020/12/logo-uniandes-inspira-.png"',
                    body,
                )

    def test_clientes_shell_is_semantic_and_uses_remote_visual_language(self):
        identifier = self.create()
        paths = ["/Clientes", "/Clientes/Create"] + [
            f"/Clientes/{action}/{identifier}" for action in ("Details", "Edit", "Delete")
        ]
        for path in paths:
            with self.subTest(path=path):
                status, body, _ = self.request(path)
                self.assertEqual(200, status)
                self.assertIn('<meta name="viewport" content="width=device-width, initial-scale=1"', body)
                self.assertIn('class="skip-link" href="#contenido-principal"', body)
                self.assertIn('<main id="contenido-principal" tabindex="-1">', body)
                self.assertIn('--background: #0e0c15', body)
                self.assertIn('--brand: #512bd4', body)
                self.assertIn('Clientes</a>', body)
                self.assertIn('Crear cliente</a>', body)
                self.assertIn('Inicio</a>', body)
        status, body, _ = self.request("/Clientes/Create")
        self.assertEqual(200, status)
        self.assertIn('<fieldset class="form-group">', body)
        self.assertIn('<legend>Identificación</legend>', body)
        self.assertIn('<legend>Contacto</legend>', body)
        self.assertIn('<legend>Ubicación</legend>', body)

    def test_html_output_is_encoded(self):
        identifier = self.create()
        fields = {**self.fields(), "Nombres": '<script>alert("test")</script>'}
        fields["__RequestVerificationToken"] = self.token(f"/Clientes/Edit/{identifier}")
        self.assertEqual(302, self.request(f"/Clientes/Edit/{identifier}", fields)[0])
        for path in ("/Clientes", f"/Clientes/Details/{identifier}"):
            status, body, _ = self.request(path)
            self.assertEqual(200, status)
            self.assertNotIn("<script>alert", body)
            self.assertIn("&lt;script&gt;", body)


if __name__ == "__main__":
    unittest.main()
