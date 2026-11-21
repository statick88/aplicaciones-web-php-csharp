# Semana 5 · Clase 1: tablas, mantenimiento y archivos {#semana5-clase1-tablas}

Esta lección separa el mantenimiento de la estructura, los datos y los archivos. Son **ejemplos instructivos**: no se ejecutan, no abren una base de datos, no suben archivos ni representan endpoints listos para publicar.

## Objetivos

Al terminar podrás:

- distinguir DDL de DML y relacionar CRUD con una API;
- elegir restricciones que mantengan la integridad de productos y categorías;
- explicar `ALTER TABLE` y migraciones versionadas en PHP y .NET;
- describir una carga Angular con `FormData` y sus controles obligatorios en PHP o .NET;
- decidir qué metadatos se guardan y qué controles preceden a una descarga.

Fuentes: [MySQL: CREATE TABLE](https://dev.mysql.com/doc/refman/8.4/en/create-table.html), [ALTER TABLE](https://dev.mysql.com/doc/refman/8.4/en/alter-table.html), [Angular HTTP](https://angular.dev/guide/http/making-requests), [PHP: cargas de archivos](https://www.php.net/manual/es/features.file-upload.post-method.php) y [ASP.NET Core: cargas de archivos](https://learn.microsoft.com/en-us/aspnet/core/mvc/models/file-uploads).

## 1. Dos niveles de mantenimiento

**DDL** define o modifica la estructura: `CREATE`, `ALTER`, índices y claves. **DML** opera filas: `INSERT`, `SELECT`, `UPDATE` y `DELETE`. CRUD nombra esas cuatro operaciones de datos; no autoriza por sí mismo una petición.

| CRUD | SQL | HTTP habitual | Responsabilidad del servidor |
|---|---|---|---|
| Crear | `INSERT` | `POST` | validar y crear |
| Leer | `SELECT` | `GET` | autorizar y filtrar |
| Actualizar | `UPDATE` | `PUT`/`PATCH` | validar el cambio |
| Eliminar | `DELETE` | `DELETE` | autorizar y conservar trazabilidad |

Un modelo mínimo ilustra restricciones en MySQL:

```sql
CREATE TABLE categorias (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE productos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(20) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
  stock INT NOT NULL DEFAULT 0,
  categoria_id INT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_producto_categoria
    FOREIGN KEY (categoria_id) REFERENCES categorias(id)
) ENGINE=InnoDB;
```

**Resultado previsto:** un producto no puede carecer de código, repetirlo, tener precio negativo ni referir una categoría inexistente. La validación Angular mejora la experiencia, pero las restricciones y la validación del backend son la barrera que queda ante una petición manipulada.

## 2. Tipos y restricciones trabajan juntos

`DECIMAL(10,2)` evita los redondeos de `FLOAT` para dinero; `VARCHAR(20)` expresa un límite de texto; una clave foránea expresa una relación. `UNIQUE` resuelve concurrencia mejor que una comprobación previa aislada. La aplicación traduce el error a un mensaje útil, sin exponer SQL o configuración.

| Regla | MySQL | PHP / PDO | .NET / EF Core |
|---|---|---|---|
| obligatorio | `NOT NULL` | validar antes de ejecutar | `[Required]` y `ModelState` |
| único | `UNIQUE` | capturar conflicto de integridad | índice único y `DbUpdateException` |
| rango | `CHECK` | validar rango | `[Range]` y restricción |
| relación | `FOREIGN KEY` | valor válido y consulta preparada | propiedad/FK y modelo |

La regla tiene capas complementarias; ninguna hace innecesaria a las otras.

## 3. Evolución: ALTER y migraciones

`ALTER TABLE` cambia una estructura existente. Estos comandos modifican el esquema si se ejecutan; aquí se presentan únicamente para estudio y **no se ejecutan**:

```sql
ALTER TABLE productos ADD COLUMN descripcion TEXT NULL;
ALTER TABLE productos MODIFY COLUMN nombre VARCHAR(150) NOT NULL;
CREATE INDEX ix_productos_categoria_activo ON productos (categoria_id, activo);
-- DROP COLUMN elimina datos: se analiza y respalda antes de aplicarlo.
```

**Resultado previsto:** la primera sentencia agrega una columna opcional; la segunda amplía el límite; el índice favorece búsquedas que empiecen por `categoria_id`. Un `DROP` no es un “deshacer” seguro.

Una migración convierte el cambio en historial revisable. En un backend PHP se versiona un archivo SQL numerado, por ejemplo `003_agregar_descripcion.sql`, y un registro de migraciones evita repetirlo. En .NET, EF Core compara el modelo y la última migración; se revisa la migración generada y se versiona junto al código. La migración no debe aplicarse desde una lección ni con credenciales compartidas.

> **Diferencia de proveedor:** EF Core no es MySQL. Un proyecto que use el proveedor SQL Server genera dialecto y tipos propios de SQL Server; el backend de clase con MySQL requiere el proveedor y la configuración que ya haya elegido su aplicación. No se agrega una dependencia solo para copiar este ejemplo.

## 4. Angular: FormData y envío explícito

En una aplicación standalone, `HttpClient` se configura una vez en los proveedores. El `HttpClient` inyectado genera **Observables fríos**: una solicitud se envía al hacer `subscribe`; otra suscripción repite la solicitud. Por ello una acción de “Subir” debe suscribirse una vez y gestionar su estado.

```ts
import { provideHttpClient, HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

// app.config.ts
export const appConfig = { providers: [provideHttpClient()] };

// Servicio con HttpClient inyectado en el constructor.
subir(archivo: File): Observable<{ id: number }> {
  const cuerpo = new FormData();
  cuerpo.append('archivo', archivo, archivo.name);
  return this.http.post<{ id: number }>('/api/adjuntos', cuerpo);
}
```

**Resultado previsto:** al suscribirse, Angular serializa `FormData` como `multipart/form-data`. No se fija manualmente `Content-Type`: el navegador añade el límite (*boundary*) correcto. `accept` y el tamaño comprobados en el componente solo orientan al usuario; no son controles de seguridad.

Para filtros de lectura, `HttpParams` es inmutable: `set` devuelve otra instancia.

```ts
import { HttpParams } from '@angular/common/http';

let params = new HttpParams();
params = params.set('pagina', '1').set('porPagina', '10');
// Resultado previsto: params contiene ambos parámetros; ignorar el retorno no los agrega.
```

## 5. Algoritmo de recepción segura (no es código publicable)

No copies un endpoint incompleto de carga. PHP con `$_FILES` y .NET con `IFormFile` deben implementar el mismo algoritmo completo:

1. autenticar y autorizar la acción y la entidad objetivo antes de aceptar contenido;
2. rechazar archivo ausente, error de transporte o tamaño mayor al límite del servidor;
3. obtener el MIME desde el contenido en el servidor, compararlo con una lista permitida y comprobar la extensión permitida; MIME declarado y extensión no bastan por separado;
4. generar un nombre aleatorio del servidor; no construir una ruta desde el nombre ni desde un campo del cliente;
5. almacenar fuera de la raíz pública o en blob privado, con permisos y límites; analizar malware cuando el contexto lo requiera;
6. registrar metadatos (id, nombre original para presentación controlada, nombre interno, tamaño, MIME detectado, dueño, fecha) en una operación consistente;
7. descargar por id, volver a autorizar al solicitante, localizar por el nombre interno y devolver una respuesta segura.

**Omisiones deliberadas:** límites del proxy, análisis antivirus, cuotas, borrado/retención, auditoría, cifrado, gestión de secretos, CSRF/CORS y recuperación de fallos dependen del sistema. Por eso este algoritmo no es una implementación ejecutable ni una receta suficiente para producción.

PHP usaría `is_uploaded_file`, detección MIME del servidor y `move_uploaded_file`; .NET limitaría `IFormFile.Length`, no confiaría en `ContentType`, generaría nombre con `Path.GetRandomFileName`/GUID y usaría almacenamiento inyectado. En ambos casos, una descarga no debe servir una ruta proporcionada por URL.

## 6. Local o blob: decisión trazable

| Opción | Ventaja | Riesgo que debe resolverse |
|---|---|---|
| disco privado del servidor | simple para una instancia | copias, crecimiento y varias instancias |
| blob privado | durabilidad y escala | credenciales, coste, políticas y enlaces de acceso |

La base de datos normalmente conserva los metadatos y la referencia, no el archivo completo. Esa decisión debe incluir respaldo, retención y quién puede descargar; no se deduce solo de que una carga haya respondido `200`.

## Práctica y soluciones

1. **Clasifica:** agregar `descripcion` a una tabla. **Solución:** DDL; cambia la estructura y debe entrar en una migración versionada.
2. **Predice:** llega `precio = -2` a una API. **Solución:** debe rechazarse por validación del servidor y por `CHECK`; Angular no es suficiente.
3. **Decide:** el navegador declara `image/png`, pero el contenido detectado no es PNG. **Solución:** rechazar; se acepta el tipo verificado por el servidor y la extensión permitida, no la declaración del cliente.

## Cierre

DDL cambia estructura y DML cambia filas; las restricciones mantienen reglas aun ante clientes no confiables. `FormData` transporta un archivo, pero la aceptación exige controles de servidor, autorización y almacenamiento diseñado. Estos ejemplos instructivos no se ejecutan ni sustituyen una revisión de seguridad.

## Autoevaluación {#s5c1-autoevaluacion}

### 1. DDL y DML
<!-- quiz: web-w5c1-ddl-dml -->

### 2. Restricción de integridad
<!-- quiz: web-w5c1-constraint -->

### 3. Migración versionada
<!-- quiz: web-w5c1-migration -->

### 4. FormData
<!-- quiz: web-w5c1-formdata -->

### 5. Validación de archivos
<!-- quiz: web-w5c1-upload-controls -->

### 6. Descarga autorizada
<!-- quiz: web-w5c1-download-auth -->
