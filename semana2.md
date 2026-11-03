
SEMANA 2
Clase 1

Tipos de datos simples y variables de variables
Objetivo de la Clase 1

DISTINGUE TIPOS DE DATOS SIMPLES EN PHP, DECLARA Y MANIPULA VARIABLES Y VARIABLES DE VARIABLES CON BUENAS PRÁCTICAS, Y DESARROLLA UNA CLASE CLIENTE EN POO INTEGRANDO MÉTODOS CRUD FUNCIONALES PARA REGISTRAR, CONSULTAR, ACTUALIZAR Y ELIMINAR INFORMACIÓN DE CLIENTES.
Resultado de Aprendizaje de la Clase 1

USA LOS PROCESOS DE INSTALACIÓN DE SOFTWARE Y LA EVOLUCIÓN DE PHP Y .NET, IDENTIFICANDO SUS PRINCIPALES CARACTERÍSTICAS, DIFERENCIAS Y APLICACIONES, PARA UNA CORRECTA TOMA DE DECISIONES EN EL DESARROLLO DE APLICACIONES WEB.
Temas a Tratar

SEMANA 2 | CLASE 1
1.3. TIPOS DE DATOS SIMPLES, VARIABLES DE VARIABLES
Ingeniería de Software
APLICACIONES WEB

Unidad de aprendizaje: Introducción a la creación de páginas dinámicas con PHP

Docente: Ing. Luis Llerena
Presentación de la clase

En esta clase se estudian los tipos de datos escalares de PHP, la conversión automática y explícita entre tipos, las declaraciones de tipo con modo estricto, las variables de variables y su alternativa con arreglos, y el uso de tipos simples dentro de una clase Cliente.
Guía de navegación: Seleccione cada apartado para desplegar su contenido.
01 | Tipos de datos simples en PHP

Los tipos simples o escalares almacenan un único valor. PHP los asigna automáticamente según el valor, pero conocerlos es indispensable para validar entradas, hacer cálculos correctos y guardar los datos en la base de datos con el formato adecuado.
Tipo	Descripción	Ejemplos	Función de verificación
int	Números enteros (64 bits en sistemas actuales)	42, -7, 0x1A, 1_000_000	is_int()
float	Números con decimales	3.14, 1.5e3	is_float()
string	Cadenas de texto	'hola', "Hola $nombre"	is_string()
bool	Verdadero o falso	true, false	is_bool()
null	Ausencia de valor	null	is_null()
Código de ejemplo

<?php
$cantidad = 3;                 // int
$precio   = 12.50;             // float
$producto = "Teclado USB";     // string
$enStock  = true;              // bool
$descuento = null;             // null

$subtotal = $cantidad * $precio;          // int * float = float (37.5)
echo "Producto: $producto<br>";
echo "Subtotal: " . number_format($subtotal, 2) . "<br>";

var_dump($cantidad, $precio, $enStock, $descuento);
// int(3) float(12.5) bool(true) NULL

echo PHP_INT_MAX;        // mayor entero disponible
echo PHP_FLOAT_EPSILON;  // precisión mínima de los float

    Para recordar: los float se almacenan en binario y pueden generar pequeños errores de redondeo (0.1 + 0.2 no es exactamente 0.3). Para dinero se redondea con round() o se trabaja en centavos como enteros.

02 | Conversión de tipos

PHP convierte tipos de forma automática (type juggling) cuando una operación lo requiere, por ejemplo al sumar un número con una cadena numérica. También se pueden convertir de forma explícita con un cast. Los datos de formularios siempre llegan como texto, por lo que la conversión es parte de toda validación.

<?php
// Conversión automática
var_dump("10" + 5);       // int(15)
var_dump("3.5" * 2);      // float(7)
var_dump(10 . "");        // string(2) "10"

// Conversión explícita (cast)
$texto = "125abc";
var_dump((int) $texto);        // int(125)
var_dump((float) "8,5");       // float(8): la coma no es separador decimal
var_dump((bool) "0");          // bool(false)
var_dump((string) 3.0);        // string(1) "3"

// Valores que se consideran false
var_dump((bool) 0, (bool) "", (bool) [], (bool) null);   // todos false

// Comparación flexible (==) y estricta (===)
var_dump(0 == "a");       // false en PHP 8
var_dump("1" == "01");    // true  (compara como números)
var_dump("1" === "01");   // false (mismo tipo y valor exigidos)

Operador	Compara	Recomendación
==	Solo el valor, convirtiendo tipos si es necesario	Evitarlo con datos del usuario
===	Valor y tipo	Preferirlo siempre
03 | Declaraciones de tipo y modo estricto

Desde PHP 7 se pueden declarar los tipos de los parámetros, de los valores de retorno y de las propiedades. Con declare(strict_types=1); al inicio del archivo PHP deja de convertir automáticamente y lanza un TypeError si el tipo no coincide, lo que detecta errores antes de que lleguen a la base de datos.

<?php
declare(strict_types=1);

function calcularTotal(int $cantidad, float $precio, ?float $descuento = null): float
{
    $total = $cantidad * $precio;
    if ($descuento !== null) {
        $total -= $total * $descuento;
    }
    return round($total, 2);
}

echo calcularTotal(3, 12.5);           // 37.5
echo calcularTotal(3, 12.5, 0.10);     // 33.75
// echo calcularTotal("3", 12.5);      // TypeError por el modo estricto

// Tipos unión (8.0): acepta int o string
function buscarCliente(int|string $clave): string {
    return is_int($clave) ? "Buscar por id $clave" : "Buscar por cédula $clave";
}

04 | Variables de variables

Una variable de variable usa el valor de una variable como nombre de otra, con la sintaxis $$nombre. Es una característica propia de PHP que permite crear nombres de variables dinámicamente. Se usa con prudencia: en la mayoría de casos un arreglo asociativo resuelve lo mismo de forma más clara y segura.

<?php
$campo = "ciudad";
$$campo = "Ambato";          // crea la variable $ciudad
echo $ciudad;                // Ambato
echo ${$campo};              // Ambato (forma con llaves, más legible)

// Construir nombres dinámicos
for ($i = 1; $i <= 3; $i++) {
    ${"nota$i"} = $i * 3;     // $nota1, $nota2, $nota3
}
echo $nota1 + $nota2 + $nota3;   // 18

// Propiedades y métodos dinámicos en objetos
$obj = new stdClass();
$propiedad = "telefono";
$obj->$propiedad = "0991234567";
echo $obj->telefono;

// Alternativa recomendada: arreglo asociativo
$datos = [];
$datos[$campo] = "Ambato";
echo $datos['ciudad'];

Enfoque	Ventaja	Riesgo
Variables de variables	Nombres generados en tiempo de ejecución	Código difícil de leer; peligroso con datos del usuario
Arreglo asociativo	Claro, recorrible con foreach, convertible a JSON	Ninguno relevante

    Precaución: nunca se crean variables de variables a partir de datos del usuario (por ejemplo $$_GET['x']), porque permitiría sobrescribir variables internas del script.

05 | Tipos simples dentro de un objeto: la clase Cliente

Los tipos simples se combinan en una clase para representar una entidad del sistema. La clase Cliente declara sus propiedades con tipo y agrupa las operaciones básicas de gestión (registrar, consultar, actualizar y eliminar) sobre una colección en memoria, que en las siguientes unidades se reemplazará por una tabla MySQL.

<?php
declare(strict_types=1);

class Cliente
{
    public function __construct(
        public int $id,
        public string $nombre,
        public string $correo,
        public bool $activo = true,
        public ?string $telefono = null,
    ) {}
}

class ClienteRepositorioMemoria
{
    /** @var array<int, Cliente> */
    private array $clientes = [];

    public function registrar(Cliente $c): void       { $this->clientes[$c->id] = $c; }
    public function consultar(int $id): ?Cliente      { return $this->clientes[$id] ?? null; }
    public function listar(): array                   { return array_values($this->clientes); }
    public function eliminar(int $id): bool
    {
        if (!isset($this->clientes[$id])) return false;
        unset($this->clientes[$id]);
        return true;
    }
    public function actualizarCorreo(int $id, string $correo): bool
    {
        $c = $this->consultar($id);
        if ($c === null) return false;
        $c->correo = $correo;
        return true;
    }
}

$repo = new ClienteRepositorioMemoria();
$repo->registrar(new Cliente(1, "Ana Pérez", "ana@correo.com"));
$repo->registrar(new Cliente(2, "Luis Torres", "luis@correo.com", telefono: "0987654321"));
$repo->actualizarCorreo(1, "ana.perez@correo.com");

foreach ($repo->listar() as $c) {
    echo "{$c->id} - {$c->nombre} - {$c->correo}<br>";
}

06 | Material de apoyo

    Código fuente del curso (GitHub): https://github.com/lleroc/web
    < 

07 | Recursos audiovisuales
RECURSO AUDIOVISUAL 01
Variables en PHP 8
Video

Oregoom Academy. (2025, 12 de mayo). (11) - Variables en PHP - Curso de PHP 8 [Video]. YouTube. https://www.youtube.com/watch?v=5Cs7pQs4xjk
RECURSO AUDIOVISUAL 02
Variables, tipos de datos y constantes en PHP
Video

Miguel Mateo. (2024, 10 de junio). PHP: Variables, tipos de datos y constantes [Video]. YouTube. https://www.youtube.com/watch?v=7b5fnzBDQlM
Orientación académica: Se recomienda revisar los materiales audiovisuales y relacionar los procedimientos presentados con los conceptos estudiados en clase.
08 | Bibliografía y fuentes de consulta
Referencias bibliográficas (APA 7)

    The PHP Documentation Group. (2026). Manual de PHP: Los tipos. https://www.php.net/manual/es/language.types.php
    The PHP Documentation Group. (2026). Manual de PHP: Variables variables. https://www.php.net/manual/es/language.variables.variable.php
    The PHP Documentation Group. (2026). Manual de PHP: Declaraciones de tipo. https://www.php.net/manual/es/language.types.declarations.php
    Coronado García, B. (2024). Desarrollo de aplicaciones web en el entorno servidor. UF1844 (1.ª ed.). Editorial Tutor Formación. https://elibro.net/es/lc/uniandesecuador/titulos/273999


