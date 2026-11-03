"""Week 2 checks through HTTP, with an isolated PHP session store."""
import http.cookiejar
import re
import socket
import subprocess
import tempfile
import time
import unittest
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args):
        return None


class Week2HTTP(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.store = tempfile.TemporaryDirectory(prefix='.week2-', dir=ROOT)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        cls.url = f'http://127.0.0.1:{port}'
        cls.server = subprocess.Popen(
            ['php', '-d', f'session.save_path={cls.store.name}', '-S',
             f'127.0.0.1:{port}', '-t', str(ROOT / 'public')],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(100):
            try:
                with urllib.request.urlopen(cls.url, timeout=1):
                    return
            except OSError:
                time.sleep(0.02)
        raise RuntimeError('PHP server did not start')

    @classmethod
    def tearDownClass(cls):
        cls.server.terminate()
        cls.server.wait(timeout=5)
        cls.store.cleanup()

    def setUp(self):
        self.client = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()), NoRedirect())

    def request(self, path='/semana2.php', data=None, method=None):
        if data is not None:
            data = {(k + '[]' if isinstance(v, list) else k): v
                    for k, v in data.items()}
        body = urllib.parse.urlencode(data, doseq=True).encode() if data is not None else None
        req = urllib.request.Request(self.url + path, data=body, method=method)
        try:
            response = self.client.open(req, timeout=3)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            return response.status, response.headers, response.read().decode()

    def form(self):
        status, _, body = self.request()
        self.assertEqual(status, 200)
        token = re.search(r'name="csrf" value="([a-f0-9]+)"', body)[1]
        return dict(csrf=token, nombre='Ana Pérez', correo='ana@correo.com',
                    edad='16', carrera='SOF', intereses=['web', 'datos'])

    def test_class1_browser_demo(self):
        status, _, body = self.request('/semana2-tipos.php')
        self.assertEqual(status, 200)
        for text in ['37.5', '33.75', 'Ambato', 'TypeError', 'ana.perez@correo.com', 'Eliminado: sí']:
            self.assertIn(text, body)

    def test_registration_between_files_and_prg(self):
        data = self.form()
        status, headers, _ = self.request('/semana2-registro.php', data)
        self.assertEqual(status, 303)
        self.assertEqual(headers['Location'], 'semana2.php')
        status, _, body = self.request()
        self.assertEqual(status, 200)
        self.assertIn('Registro correcto', body)
        self.assertIn('Clientes registrados: 1', body)
        self.assertIn('Ana Pérez', body)
        self.assertIn('web, datos', body)
        self.assertIn('16', body)
        self.assertIn('SOF', body)
        _, _, refreshed = self.request()
        self.assertIn('Clientes registrados: 1', refreshed)
        self.assertNotIn('Registro correcto', refreshed)
        _, _, filtered = self.request('/semana2.php?q=sin-coincidencia')
        self.assertNotIn('ana@correo.com', filtered)
        self.assertIn('Clientes registrados: 1', filtered)

    def test_self_processing_optional_age_and_escaping(self):
        data = self.form()
        data.update(nombre='<script>alert(1)</script>', edad='', intereses=[])
        self.assertEqual(self.request(data=data)[0], 303)
        _, _, body = self.request()
        self.assertIn('&lt;script&gt;alert(1)&lt;/script&gt;', body)
        self.assertNotIn('<script>', body)
        self.assertIn('Clientes registrados: 1', body)
        self.assertEqual(self.request(data={**data, 'edad': '99', 'carrera': 'SIS'})[0], 303)
        self.assertIn('Clientes registrados: 2', self.request()[2])

    def test_invalid_input_preserves_values_and_does_not_register(self):
        data = self.form()
        cases = [dict(nombre=''), dict(nombre='á' * 81), dict(correo='no-email'),
                 dict(edad='15'), dict(edad='100'), dict(carrera='XXX'),
                 {'nombre[]': 'Ana', 'nombre': None}, dict(correo=['a@b.com']),
                 dict(edad=['16']), dict(carrera=['SOF']), dict(intereses='web'),
                 dict(intereses=['web', 'otro']), {'intereses[0][]': 'web', 'intereses': None}]
        for change in cases:
            with self.subTest(change=change):
                payload = {k: v for k, v in {**data, **change}.items() if v is not None}
                status, _, body = self.request(data=payload)
                self.assertEqual(status, 422)
                self.assertIn('Revise los datos', body)
                self.assertNotIn('Fatal error', body)
                self.assertIn('Clientes registrados: 0', self.request()[2])
        self.assertIn('value="Ana Pérez"', self.request(data={**data, 'correo': 'bad'})[2])
        self.assertEqual(self.request(data={**data, 'nombre': 'á' * 80})[0], 303)

    def test_method_csrf_and_query_shape(self):
        data = self.form()
        self.assertEqual(self.request('/semana2-registro.php')[0], 405)
        status, headers, _ = self.request(method='PUT')
        self.assertEqual(status, 405)
        self.assertEqual(headers['Allow'], 'GET, POST')
        self.assertEqual(self.request(data={**data, 'csrf': 'bad'})[0], 403)
        self.assertIn('Clientes registrados: 0', self.request()[2])
        self.assertEqual(self.request('/semana2.php?q[]=x')[0], 422)
        _, _, body = self.request('/semana2.php?q=%3Cscript%3E')
        self.assertIn('&lt;script&gt;', body)
        self.assertNotIn('<script>', body)


if __name__ == '__main__':
    unittest.main()
