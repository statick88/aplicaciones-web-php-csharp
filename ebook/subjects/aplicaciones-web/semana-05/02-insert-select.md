# Semana 5 · Clase 2: INSERT, SELECT y consultas verificables {#semana5-clase2-insert-select}

Esta lección sigue un registro desde Angular a una API PHP/PDO o .NET/EF Core y vuelve a un listado. Sus **ejemplos instructivos** no se ejecutan: no conectan, no insertan ni consultan datos reales.

## Objetivos

Al terminar podrás:

- explicar por qué los valores se parametrizan en PDO y EF Core;
- usar una transacción para conservar el principio todo o nada;
- leer un `SELECT` con `JOIN`, filtro, orden y paginación determinista;
- distinguir valores SQL de identificadores que requieren lista permitida;
- planear comprobaciones de API en Postman por estado y cuerpo esperado.

Fuentes: [MySQL INSERT](https://dev.mysql.com/doc/refman/8.4/en/insert.html), [MySQL SELECT](https://dev.mysql.com/doc/refman/8.4/en/select.html), [PDO::prepare](https://www.php.net/manual/es/pdo.prepare.php), [PDO y transacciones](https://www.php.net/manual/es/pdo.transactions.php), [consultas EF Core](https://learn.microsoft.com/en-us/ef/core/querying/) y [transacciones EF Core](https://learn.microsoft.com/en-us/ef/core/saving/transactions).

## 1. Registro: cliente, API y restricción

Angular recoge campos, llama `POST /api/productos` y muestra el resultado de la API; PHP o .NET valida autorización, forma y reglas antes de persistir. El estado `201 Created` significa que el contrato afirma creación; `400` comunica formato o regla inválida y `409` puede expresar un conflicto como un código único duplicado, según el contrato elegido.

```ts
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

type ProductoNuevo = { codigo: string; nombre: string; precio: number; categoriaId: number };

crear(producto: ProductoNuevo): Observable<{ id: number }> {
  return this.http.post<{ id: number }>('/api/productos', producto);
}
```

**Resultado previsto:** la petición se envía cuando el componente se suscribe. La validación de formulario evita errores previsibles, pero la API aún debe validar; `HttpClient` no persiste una fila por sí mismo.

## 2. INSERT: valores separados, estructura controlada

PDO prepara una consulta fija y enlaza valores. El ejemplo es de estudio; no tiene una conexión real:

```php
$sentencia = $pdo->prepare(
    'INSERT INTO productos (codigo, nombre, precio, categoria_id)
     VALUES (:codigo, :nombre, :precio, :categoria_id)'
);
$sentencia->execute([
    ':codigo' => $codigo,
    ':nombre' => $nombre,
    ':precio' => $precio,
    ':categoria_id' => $categoriaId,
]);
```

**Resultado previsto:** los cuatro valores se envían como valores ligados; una comilla dentro de `$nombre` no cambia la estructura SQL. No se construye SQL con interpolación o concatenación de entrada.

EF Core expresa la misma intención con entidad, contexto y `SaveChangesAsync`; el proveedor genera parámetros. También deben validarse reglas y manejarse conflictos de integridad sin devolver detalles internos.

```csharp
_context.Productos.Add(producto);
await _context.SaveChangesAsync();
// Resultado previsto: el proveedor parametriza valores al persistir la entidad válida.
```

Los marcadores representan **valores**, no identificadores SQL. Si una pantalla permite ordenar por `nombre` o `creado_en`, el servidor elige desde una lista cerrada; `ORDER BY :columna` no convierte una entrada en un identificador seguro.

## 3. Lote atómico: transacción y rollback

Una transacción evita el éxito parcial: si se crea una categoría y luego falla su producto, ambas operaciones deben revertirse. El flujo conceptual es `beginTransaction` → sentencias preparadas → `commit`; ante error, `rollBack` si la transacción sigue activa. En EF Core se abre una transacción explícita cuando varias llamadas a `SaveChangesAsync` sobre la misma base necesitan ese límite (no coordina automáticamente archivos ni servicios externos); se hace `CommitAsync` solo al final y `RollbackAsync` ante excepción.

```sql
START TRANSACTION;
-- INSERT parametrizados representados aquí solo como intención.
COMMIT;
-- Ante un fallo antes de confirmar: ROLLBACK.
```

**Resultado previsto:** tras un error, el lote no deja solo la categoría o solo algunos productos. DDL como `ALTER TABLE` puede tener reglas transaccionales distintas según motor; no se confunde con una transacción de DML. Ninguno de estos fragmentos se ejecuta.

## 4. SELECT con JOIN, filtro y orden estable

Una consulta de listado proyecta solo lo que muestra la interfaz y une categoría por su clave:

```sql
SELECT p.id, p.codigo, p.nombre, p.precio, c.nombre AS categoria
FROM productos AS p
INNER JOIN categorias AS c ON c.id = p.categoria_id
WHERE p.activo = TRUE
  AND (:q_vacio = '' OR p.nombre LIKE CONCAT('%', :q_filtro, '%'))
ORDER BY p.nombre ASC, p.id ASC
LIMIT :limite OFFSET :desplazamiento;
```

**Resultado previsto:** solo aparecen productos activos con categoría existente; el filtro busca el texto como valor; `nombre, id` da un orden determinista cuando dos nombres coinciden. El `JOIN` no autoriza el acceso: la API limita filas por usuario/organización antes de devolver datos.

En PHP se usa un nombre distinto por aparición del filtro para ser compatible con preparaciones nativas de PDO MySQL. Ambos reciben el mismo texto; `LIMIT` y `OFFSET` se ligan como enteros:

```php
$consulta->bindValue(':q_vacio', $q, PDO::PARAM_STR);
$consulta->bindValue(':q_filtro', $q, PDO::PARAM_STR);
$consulta->bindValue(':limite', $porPagina, PDO::PARAM_INT);
$consulta->bindValue(':desplazamiento', $offset, PDO::PARAM_INT);
```

**Resultado previsto:** MySQL recibe números enteros para esos límites. En .NET, una consulta LINQ parte de un `IQueryable` autorizado, filtra, aplica `OrderBy(...).ThenBy(...)`, y recién después `Skip(...).Take(...)`. EF Core parametriza los valores de filtro; no se pasa SQL crudo interpolado.

## 5. Paginación acotada y reproducible

La API normaliza entrada antes de calcular: `pagina = max(1, solicitada)` y `porPagina` se limita, por ejemplo, entre 1 y 100. Después calcula `offset = (pagina - 1) * porPagina` con un límite que evite desbordes. La respuesta declara `total`, `pagina`, `porPagina` e `items`; el total se obtiene con los mismos filtros y aislamiento que el listado.

| Solicitud | Resultado esperado |
|---|---|
| `?pagina=1&porPagina=10` | máximo 10 ítems, orden `nombre,id` |
| `?pagina=0` | API normaliza o rechaza según contrato, sin consulta ilimitada |
| `?porPagina=10000` | API limita o rechaza; nunca entrega una página no acotada |

El orden siempre precede a `LIMIT/OFFSET`; sin orden determinista puede repetirse u omitirse una fila entre páginas.

## 6. Comprobación con Postman

Postman comprueba una API en ejecución; esta tabla no prueba que exista una. Usar datos aislados y autorización de prueba evita afectar información ajena.

| Caso | Solicitud | Estado y evidencia esperados |
|---|---|---|
| creación válida | `POST /api/productos` con JSON válido | `201`, id creado y ubicación/representación según contrato |
| regla inválida | `POST` sin código | `400`, error accionable; no se afirma inserción |
| duplicado | `POST` con código ya existente | `409` o estado documentado, mensaje sin SQL interno |
| listado filtrado | `GET ?q=mart&pagina=1&porPagina=10` | `200`, `items` acotados, `total` y orden estable |
| falta autorización | `GET` o descarga sin credencial válida | `401`/`403` según autenticación/autorización |

No se prueban inyecciones enviando cadenas peligrosas contra sistemas ajenos. En un entorno autorizado se verifica que el filtro llega como parámetro y que no modifica estructura ni datos fuera del caso preparado.

## Práctica y soluciones

1. **Decide:** el usuario escribe `P-1'...` como código. **Solución:** PDO/EF lo tratan como valor ligado; la API valida la regla del código sin interpolarlo en SQL.
2. **Predice:** falla el segundo `INSERT` de un lote antes de `commit`. **Solución:** `rollback` deja el lote sin cambios confirmados.
3. **Corrige:** un listado usa `LIMIT` sin `ORDER BY`. **Solución:** agregar orden estable, por ejemplo `nombre ASC, id ASC`, antes de paginar.

## Cierre

INSERT parametrizado separa datos de instrucciones; una transacción conserva la unidad del lote; SELECT necesita filtros autorizados, orden estable y límites. Los ejemplos instructivos no se ejecutan ni son evidencia de una API o base de datos real.

## Autoevaluación {#s5c2-autoevaluacion}

### 1. Parámetros PDO
<!-- quiz: web-w5c2-pdo-parameters -->

### 2. EF Core
<!-- quiz: web-w5c2-ef-core -->

### 3. Rollback
<!-- quiz: web-w5c2-rollback -->

### 4. JOIN y filtro
<!-- quiz: web-w5c2-join-filter -->

### 5. Paginación
<!-- quiz: web-w5c2-pagination -->

### 6. Postman
<!-- quiz: web-w5c2-postman-status -->
