# Laboratorio local de métodos HTTP

Este ejemplo envía cinco peticiones ficticias a un endpoint PHP **sin persistencia**. `DELETE` es una simulación: no hay base de datos, sesiones, archivos, contadores ni datos reales.

## Ejecutar con límites locales

Desde la raíz del repositorio:

```bash
php -S 127.0.0.1:8088 -t ebook/examples/http-methods ebook/examples/http-methods/router.php
```

Abre <http://127.0.0.1:8088/>. Usa exactamente `127.0.0.1`: el servidor queda enlazado solo a loopback, el document root queda aislado en esta carpeta, `router.php` limita las rutas públicas y `api.php` rechaza otro host o dirección remota. No omitas el router, no uses `0.0.0.0`, no sirvas la raíz del repositorio y no agregues cabeceras, cookies o datos personales.

Se necesita PHP local. El ejemplo no funciona al abrir `index.html` con `file://` ni en GitHub Pages, porque ambos carecen de un servidor PHP.

## Observar en DevTools

1. Abre DevTools (`F12` o `Ctrl+Shift+I`) y selecciona **Network / Red**.
2. Activa **Preserve log** si quieres conservar las cinco filas.
3. Pulsa cada botón y filtra por `api.php`.
4. Selecciona una fila y revisa **Headers**, **Payload** y **Response**.
5. Detén el servidor con `Ctrl+C` al terminar.
