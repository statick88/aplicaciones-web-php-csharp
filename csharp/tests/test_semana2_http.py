"""Runtime HTTP checks for the Week 2 ASP.NET Core practice.

Set SEMANA2_BASE_URL (for example http://127.0.0.1:18083) to a deliberately
started practice server. The suite fails explicitly without that evidence;
it never treats a missing host as a skipped runtime proof.
"""

from __future__ import annotations

import html
import http.cookiejar
import os
import re
import unittest
import urllib.error
import urllib.parse
import urllib.request


BASE_URL = os.environ.get("SEMANA2_BASE_URL", "").rstrip("/")


class Semana2HttpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not BASE_URL:
            raise RuntimeError("SEMANA2_BASE_URL is required for HTTP runtime verification")

    def setUp(self) -> None:
        self.cookies = http.cookiejar.CookieJar()
        self.client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.cookies))

    def request(self, path: str, data: dict[str, object] | None = None, *, follow: bool = True):
        encoded = None if data is None else urllib.parse.urlencode(data, doseq=True).encode()
        request = urllib.request.Request(BASE_URL + path, data=encoded)
        if not follow:
            self.client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.cookies), NoRedirect())
        try:
            response = self.client.open(request)
        except urllib.error.HTTPError as error:
            response = error
        self.addCleanup(response.close)
        return response

    @staticmethod
    def text(response) -> str:
        return html.unescape(response.read().decode())

    def csrf(self) -> str:
        page = self.request("/Semana2").read().decode()
        token = re.search(r'name="__RequestVerificationToken" type="hidden" value="([^"]+)"', page)
        self.assertIsNotNone(token, "Razor form must emit an antiforgery token")
        return token.group(1)  # type: ignore[union-attr]

    def post_valid(self, path: str, *, nombre: str = "Ana Pérez", edad: str = ""):
        return self.request(path, {
            "__RequestVerificationToken": self.csrf(), "Nombre": nombre, "Correo": "ana@example.com",
            "Edad": edad, "Carrera": "SOF", "Intereses": ["web", "datos"],
        }, follow=False)

    def test_initial_form_defaults_to_software_without_blank_carrera_option(self) -> None:
        page = self.request("/Semana2").read().decode()
        self.assertIn('<option value="SOF" selected="selected">Software</option>', page)
        self.assertNotIn('<option value="" selected>', page)

    def test_class1_and_prior_landing_links(self) -> None:
        self.assertIn("Semana 2", self.text(self.request("/")))
        self.assertEqual(self.request("/Home/Variables").status, 200)
        self.assertIn("Max=10, valor=default", self.text(self.request("/Home/Constantes")))
        tipos = self.text(self.request("/Semana2/Tipos"))
        for expected in ("Dictionary", "Cliente inexistente", "actualizar 999=False", "ana.perez@correo.com", "subtotal=37.5", "total 10%=33.75", "int.Parse(\"1\") == int.Parse(\"01\") = True", "string.Equals(\"1\", \"01\", StringComparison.Ordinal) = False", "BuscarPorId(15)", "BuscarPorCedula(\"0102\")"):
            self.assertIn(expected, tipos)

    def test_valid_post_optional_age_boundaries_multiple_interests_and_prg(self) -> None:
        first = self.post_valid("/Semana2/Registrar", edad="16")
        self.assertEqual(first.status, 303)
        self.assertEqual(first.headers["Location"], "/Semana2")
        after = self.text(self.request(first.headers["Location"]))
        self.assertIn("Registro correcto", after)
        self.assertIn("Ana Pérez", after)
        self.assertIn("web, datos", after)
        # Reload is GET-only: it neither repeats the flash nor creates another record.
        refreshed = self.text(self.request("/Semana2"))
        self.assertNotIn("Registro correcto", refreshed)
        self.assertIn("Clientes registrados: 1", refreshed)
        second = self.post_valid("/Semana2", nombre="Luis", edad="99")
        self.assertEqual(second.status, 303)
        self.assertIn("Clientes registrados: 2", self.text(self.request("/Semana2")))
        optional = self.post_valid("/Semana2", nombre="Eva", edad="")
        self.assertEqual(optional.status, 303)
        self.assertIn("Edad: sin indicar", self.text(self.request("/Semana2")))

    def test_name_boundaries_and_invalid_ranges_preserve_data_without_writing(self) -> None:
        accepted = self.post_valid("/Semana2", nombre="A" * 80, edad="16")
        self.assertEqual(accepted.status, 303)
        self.assertIn("Clientes registrados: 1", self.text(self.request("/Semana2")))
        for edad in ("15", "100"):
            response = self.request("/Semana2", {
                "__RequestVerificationToken": self.csrf(), "Nombre": "A" * 81, "Correo": "ana@example.com",
                "Edad": edad, "Carrera": "SOF", "Intereses": ["web"],
            })
            body = self.text(response)
            self.assertEqual(response.status, 422)
            self.assertIn("El nombre es obligatorio (máximo 80 caracteres).", body)
            self.assertIn("La edad debe estar entre 16 y 99.", body)
            self.assertIn(f'value="{edad}"', body)
            self.assertIn("Clientes registrados: 1", body)

    def test_individual_invalid_fields_and_malformed_shapes_do_not_write(self) -> None:
        self.assertEqual(self.post_valid("/Semana2").status, 303)
        invalid_cases = [
            {"Nombre": "Email", "Correo": "not-email", "Edad": "", "Carrera": "SOF", "Intereses": ["web"]},
            {"Nombre": "Carrera", "Correo": "ok@example.com", "Edad": "", "Carrera": "OTHER", "Intereses": ["web"]},
            {"Nombre": "Interes", "Correo": "ok@example.com", "Edad": "", "Carrera": "SOF", "Intereses": ["evil"]},
        ]
        for fields in invalid_cases:
            fields["__RequestVerificationToken"] = self.csrf()
            response = self.request("/Semana2", fields)
            self.assertEqual(response.status, 422)
            self.assertIn("Clientes registrados: 1", self.text(response))
        malformed = self.request("/Semana2", {
            "__RequestVerificationToken": self.csrf(), "Nombre": ["Ana", "Otra"], "Correo": "ana@example.com",
            "Edad": "", "Carrera": "SOF", "Intereses[bad]": "web",
        })
        self.assertEqual(malformed.status, 422)
        self.assertIn("El campo debe ser texto.", self.text(malformed))
        self.assertIn("Clientes registrados: 1", self.text(self.request("/Semana2")))

    def test_malformed_interest_keys_are_rejected_on_both_post_routes_without_write(self) -> None:
        for path in ("/Semana2", "/Semana2/Registrar"):
            malformed = self.request(path, {
                "__RequestVerificationToken": self.csrf(), "Nombre": "Forma", "Correo": "forma@example.com",
                "Edad": "", "Carrera": "SOF", "Intereses[bad]": "evil",
            })
            self.assertEqual(malformed.status, 422)
            self.assertIn("Seleccione intereses válidos.", self.text(malformed))
            self.assertIn("Clientes registrados: 0", self.text(self.request("/Semana2")))
            bypass = self.request(path, {
                "__RequestVerificationToken": self.csrf(), "Nombre": "Mezcla", "Correo": "mezcla@example.com",
                "Edad": "", "Carrera": "SOF", "Intereses": ["web"], "Intereses[bad]": "evil",
            })
            self.assertEqual(bypass.status, 422)
            self.assertIn("Seleccione intereses válidos.", self.text(bypass))
            self.assertIn("Clientes registrados: 0", self.text(self.request("/Semana2")))

    def test_get_search_is_escaped_finds_and_excludes_without_mutation(self) -> None:
        self.assertEqual(self.post_valid("/Semana2", nombre="Ana Pérez").status, 303)
        found = self.text(self.request("/Semana2?q=ana"))
        self.assertIn("Ana Pérez", found)
        excluded = self.text(self.request("/Semana2?q=luis"))
        self.assertIn("Clientes registrados: 1", excluded)
        self.assertIn("No hay coincidencias.", excluded)
        raw = self.request("/Semana2?q=%3Cscript%3Ealert(1)%3C/script%3E").read().decode()
        self.assertNotIn("<script>alert(1)</script>", raw)
        self.assertIn("&lt;script&gt;alert(1)&lt;/script&gt;", raw)

    def test_invalid_csrf_both_routes_unsupported_methods_and_session_isolation(self) -> None:
        for path in ("/Semana2", "/Semana2/Registrar"):
            rejected = self.request(path, {
                "__RequestVerificationToken": "invalid", "Nombre": "Mallory", "Correo": "mallory@example.com",
                "Edad": "", "Carrera": "SOF", "Intereses": ["web"],
            })
            self.assertEqual(rejected.status, 400)
        self.assertEqual(self.post_valid("/Semana2").status, 303)
        self.assertIn("Clientes registrados: 1", self.text(self.request("/Semana2")))
        with urllib.request.urlopen(BASE_URL + "/Semana2") as other_response:
            other = html.unescape(other_response.read().decode())
        self.assertIn("Clientes registrados: 0", other)
        for path in ("/Semana2", "/Semana2/Registrar"):
            request = urllib.request.Request(BASE_URL + path, method="PUT")
            with self.assertRaises(urllib.error.HTTPError) as raised:
                self.client.open(request)
            self.assertEqual(raised.exception.code, 405)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


if __name__ == "__main__":
    unittest.main()
