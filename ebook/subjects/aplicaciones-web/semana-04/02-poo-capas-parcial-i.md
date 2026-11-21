# Semana 4 · Clase 2: POO, capas y repaso del Parcial I {#semana4-clase2-poo}

La POO organiza responsabilidades y hace explícitas las dependencias. Estos son **ejemplos instructivos**, no aplicaciones ejecutadas localmente: no hay credenciales, conexión activa, CRUD ni evidencia de persistencia. El repaso de Parcial I ayuda a estudiar y **no constituye una evaluación oficial**.

## Objetivos

Al terminar podrás:

- explicar clase, objeto, encapsulamiento, herencia e interfaz sin confundir sus papeles;
- reconocer el alcance y la cautela de hooks y visibilidad asimétrica de PHP 8.4;
- describir un repositorio PDO con sentencias preparadas e inyección de dependencias;
- seguir las capas, excepciones, MVC y Entity Framework sin exponer detalles técnicos a usuarios;
- organizar un repaso conceptual distinto de la evaluación oficial.

Fuentes: [POO de PHP](https://www.php.net/manual/es/language.oop5.php), [PHP 8.4: property hooks](https://www.php.net/manual/en/language.oop5.property-hooks.php), [PDO::prepare](https://www.php.net/manual/es/pdo.prepare.php), [inyección de dependencias en .NET](https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection) y [EF Core](https://learn.microsoft.com/en-us/ef/core/).

## 1. Encapsular estado y comportamiento

Una clase define datos y operaciones; un objeto es una instancia. Encapsular significa no permitir cambios arbitrarios al estado: un método verifica su precondición antes de cambiarlo.

```php
final class Producto
{
    public function __construct(private string $nombre, private int $stock) {}

    public function vender(int $cantidad): void
    {
        if ($cantidad <= 0 || $cantidad > $this->stock) {
            throw new InvalidArgumentException('Cantidad no disponible');
        }
        $this->stock -= $cantidad;
    }

    public function stock(): int { return $this->stock; }
}

$producto = new Producto('Teclado', 3);
$producto->vender(2);
echo $producto->stock(); // Salida prevista: 1
```

La predicción deriva de validar antes de restar. Lanzar una excepción no significa que una interfaz de usuario deba mostrar su detalle técnico: una capa superior decide el mensaje seguro.

### PHP 8.4: característica moderna, no requisito automático

PHP 8.4 introdujo property hooks y visibilidad asimétrica, por ejemplo una propiedad legible públicamente pero escribible solo dentro de la clase. Pueden centralizar una regla, pero exigen ejecutar PHP 8.4+ y diseñar con cuidado para no crear recursión en el hook ni dispersar reglas complejas en propiedades. Un constructor y métodos explícitos siguen siendo opciones claras cuando la versión desplegada o la regla lo requieren. No copies esa sintaxis a un entorno sin confirmar su versión.

## 2. Herencia e interfaces: reutilizar frente a contratar

La herencia especializa una base; una interfaz define los métodos que un consumidor necesita, sin imponer una jerarquía concreta. El polimorfismo permite tratar implementaciones distintas por el contrato.

```php
interface Exportable { public function aArreglo(): array; }

abstract class Persona implements Exportable
{
    public function __construct(protected string $nombre) {}
}

final class Estudiante extends Persona
{
    public function aArreglo(): array { return ['nombre' => $this->nombre, 'rol' => 'estudiante']; }
}

echo (new Estudiante('Ana'))->aArreglo()['rol']; // Salida prevista: estudiante
```

No uses herencia solo para compartir código incidental: favorece composición cuando la relación “es-un” no es estable. La interfaz `Exportable` permite depender de `aArreglo`, no de detalles privados de `Estudiante`.

## 3. Repositorio PDO e inyección de dependencias

Un repositorio concentra el acceso a una entidad. Recibir `PDO` en el constructor es **inyección de dependencias**: la clase usa una conexión provista en lugar de crearla internamente. Las sentencias preparadas enlazan valores y evitan concatenar entrada en SQL; no permiten parametrizar libremente nombres de tabla o columna.

```php
final class ClienteRepositorioPdo
{
    public function __construct(private PDO $pdo) {}

    public function buscarPorId(int $id): ?array
    {
        $consulta = $this->pdo->prepare(
            'SELECT id, nombre FROM clientes WHERE id = :id'
        );
        $consulta->execute(['id' => $id]);
        $fila = $consulta->fetch(PDO::FETCH_ASSOC);
        return $fila ?: null;
    }
}
```

No se ejecuta aquí: la salida depende de una base de datos que esta lección no configura. El SQL es fijo y `:id` representa un valor. Validar permisos, registrar fallos y escapar HTML al mostrar una fila siguen siendo responsabilidades separadas.

## 4. Capas y excepciones

Una división útil es: **presentación** recibe y muestra; **servicio** aplica reglas; **repositorio** accede a datos. La presentación captura excepciones esperables, ofrece un mensaje comprensible y evita revelar una consulta, ruta, clave o traza. El detalle técnico se registra en un canal controlado para diagnóstico.

```text
Formulario → controlador/presentación → servicio → repositorio PDO
                 ↑ error de validación        ↓ resultado o excepción técnica
```

Una excepción de validación puede volver al formulario con la regla; una excepción de infraestructura no debe convertirse en “guardado exitoso”. Capturar todo y ocultarlo tampoco es manejo correcto: separa la experiencia de usuario de la evidencia para operar el sistema.

## 5. MVC y Entity Framework en C#

En ASP.NET Core MVC, el **modelo** representa datos y reglas, la **vista** presenta y el **controlador** coordina la solicitud. DataAnnotations y `ModelState` participan en la validación del modelo. Entity Framework Core usa un `DbContext` y `DbSet<T>` para trabajar con entidades; el contexto se registra normalmente mediante inyección de dependencias.

```csharp
public class Cliente
{
    [Required]
    [EmailAddress]
    public string Correo { get; set; } = "";
}

// Predicción conceptual: un correo vacío deja ModelState inválido.
```

EF no reemplaza decisiones de autorización, validación de negocio ni el manejo de concurrencia. MVC tampoco obliga a que toda regla viva en un controlador: capas y servicios ayudan a mantener la coordinación separada de la lógica.

## Repaso guiado del Parcial I (solo estudio)

Usa esta lista para explicar decisiones, no para asumir el contenido, fecha o calificación de una evaluación oficial:

1. identifica entidad, clave, relación y restricción antes de escribir un CRUD;
2. distingue validación de formato, regla de negocio y restricción de base de datos;
3. explica por qué una operación de alquiler o reserva requiere controlar su estado y posibles conflictos;
4. ubica cada responsabilidad: formulario/MVC, servicio, repositorio/EF o PDO;
5. describe qué se comunica a quien usa el sistema y qué detalle queda para diagnóstico.

## Práctica y soluciones

1. **Caso:** vender 4 unidades con stock 3. **Solución:** el método rechaza antes de restar; el stock no debe terminar negativo.
2. **Caso:** el repositorio recibe `PDO`. **Solución:** es inyección de dependencias; facilita sustituir la dependencia en pruebas o configuración.
3. **Caso:** una inserción incumple una restricción. **Solución:** se informa un mensaje útil y se conserva el detalle técnico fuera de la respuesta pública.

## Cierre

Encapsulamiento protege invariantes; herencia e interfaz resuelven problemas distintos; repositorio, DI y capas separan responsabilidades. MVC y Entity Framework ofrecen una organización .NET, no una prueba de que un sistema haya sido ejecutado. Estos ejemplos instructivos no sustituyen la práctica ni la evaluación oficial.

## Autoevaluación {#s4c2-autoevaluacion}

### 1. Encapsulamiento
<!-- quiz: web-w4c2-encapsulation -->

### 2. PHP 8.4
<!-- quiz: web-w4c2-php84 -->

### 3. Interfaz
<!-- quiz: web-w4c2-interface -->

### 4. Repositorio PDO
<!-- quiz: web-w4c2-pdo-repository -->

### 5. Capas y excepciones
<!-- quiz: web-w4c2-layers-exceptions -->

### 6. MVC y EF
<!-- quiz: web-w4c2-mvc-ef -->
