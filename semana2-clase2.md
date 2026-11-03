
SEMANA 2
Clase 2

Envío de variables por formulario: métodos GET y POST
Objetivo de la Clase 2

APLICAR EL ENVÍO Y RECEPCIÓN DE VARIABLES MEDIANTE FORMULARIOS HTML USANDO LOS MÉTODOS D EENVIO DE DATOS ENTRE ARCHIVOS EN PHP, A TRAVÉS DE PRÁCTICAS GUIADAS CON VALIDACIÓN Y SANITIZACIÓN DE DATOS, PARA PROCESAR INFORMACIÓN DE USUARIOS DE FORMA CORRECTA Y SEGURA EN APLICACIONES WEB..
Resultado de Aprendizaje de la Clase 2

IFERENCIA ENTRE EL ENVIO DE DATOS SEGÚN SU USO, CONSTRUYE FORMULARIOS QUE ENVÍAN MÚLTIPLES VARIABLES, RECUPERA DATOS, VALIDA Y SANITIZA ENTRADAS, Y REGISTRA/CONSULTA INFORMACIÓN PROCESADA (EJ.: CLIENTE) EN UN FLUJO WEB BÁSICO
Temas a Tratar

SEMANA 2 | CLASE 2
1.4. ENVÍO DE VARIABLES POR FORMULARIO, MÉTODO GET Y POST
Ingeniería de Software
APLICACIONES WEB

Unidad de aprendizaje: Introducción a la creación de páginas dinámicas con PHP

Docente: Ing. Luis Llerena
Presentación de la clase

En esta clase se estudian los formularios HTML y sus atributos, las diferencias entre los métodos GET y POST, la recepción de datos con las superglobales de PHP, la validación y el saneamiento con la extensión filter, y el patrón Post/Redirect/Get.
Guía de navegación: Seleccione cada apartado para desplegar su contenido.
01 | Formularios HTML: el punto de entrada de los datos

Un formulario es el mecanismo estándar para que el usuario envíe información al servidor. El elemento <form> define a dónde se envían los datos (action) y cómo (method). Cada campo debe tener un atributo name: ese nombre es la clave con la que PHP recibirá el valor.
Atributo	Función	Ejemplo
action	Script que procesará los datos	action="guardar.php"
method	Método HTTP: get o post	method="post"
name	Nombre del dato enviado	name="correo"
enctype	Codificación; multipart/form-data para subir archivos	—
required, type, pattern	Validación en el navegador (no sustituye la del servidor)	type="email" required
Código de ejemplo

<!-- registro.html -->
<form action="registro.php" method="post">
  <label>Nombre: <input type="text" name="nombre" required maxlength="80"></label>
  <label>Correo: <input type="email" name="correo" required></label>
  <label>Edad:   <input type="number" name="edad" min="16" max="99"></label>

  <label>Carrera:
    <select name="carrera">
      <option value="SOF">Software</option>
      <option value="SIS">Sistemas</option>
    </select>
  </label>

  <!-- Varios valores con el mismo nombre: se agregan [] -->
  <p>Intereses:</p>
  <label><input type="checkbox" name="intereses[]" value="web"> Web</label>
  <label><input type="checkbox" name="intereses[]" value="movil"> Móvil</label>
  <label><input type="checkbox" name="intereses[]" value="datos"> Datos</label>

  <button type="submit">Registrar</button>
</form>

02 | Métodos GET y POST

El método define cómo viajan los datos en la petición HTTP y en qué superglobal los encuentra PHP:
Aspecto	GET	POST
Ubicación de los datos	En la URL: buscar.php?q=php&pag=2	En el cuerpo de la petición
Superglobal en PHP	$_GET	$_POST
Visibilidad	Visible en la barra de direcciones e historial	No visible en la URL
Tamaño	Limitado por la longitud de la URL	Mucho mayor; admite archivos
Se puede guardar como marcador	Sí	No
Uso correcto	Consultar, buscar, filtrar, paginar	Crear, modificar o eliminar datos; enviar contraseñas

<!-- Búsqueda con GET: el resultado se puede compartir por enlace -->
<form action="buscar.php" method="get">
  <input type="search" name="q" placeholder="Buscar producto">
  <button>Buscar</button>
</form>
<!-- Genera: buscar.php?q=teclado -->

<!-- Enlace con parámetros GET -->
<a href="producto.php?id=15&amp;origen=catalogo">Ver producto 15</a>
<?php
// buscar.php
$termino = $_GET['q'] ?? '';          // ?? evita el aviso si el parámetro no existe
$pagina  = (int) ($_GET['pag'] ?? 1);
echo "Resultados para: " . htmlspecialchars($termino) . " (página $pagina)";

    Para recordar: aunque POST no muestra los datos en la URL, no los cifra. La confidencialidad la proporciona HTTPS; por eso todo formulario con datos personales o contraseñas debe servirse sobre HTTPS.

03 | Recepción de los datos en PHP

PHP coloca los datos recibidos en arreglos asociativos superglobales. Antes de usarlos se comprueba que la petición sea del método esperado y que cada campo exista. Las casillas marcadas con [] llegan como un arreglo.

<?php
// registro.php
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);          // método no permitido
    exit('Acceso no válido');
}

$nombre    = trim($_POST['nombre'] ?? '');
$correo    = trim($_POST['correo'] ?? '');
$edad      = $_POST['edad'] ?? null;
$carrera   = $_POST['carrera'] ?? '';
$intereses = $_POST['intereses'] ?? [];   // arreglo de casillas marcadas

echo "<h2>Datos recibidos</h2>";
echo "<p>Nombre: "  . htmlspecialchars($nombre) . "</p>";
echo "<p>Correo: "  . htmlspecialchars($correo) . "</p>";
echo "<p>Carrera: " . htmlspecialchars($carrera) . "</p>";
echo "<p>Intereses: " . htmlspecialchars(implode(', ', $intereses)) . "</p>";

// Para depuración durante el desarrollo
// echo '<pre>' . print_r($_POST, true) . '</pre>';

Superglobal	Contenido
$_GET	Parámetros de la URL
$_POST	Campos de un formulario enviado por POST
$_REQUEST	Combinación de GET, POST y cookies (se evita por ambigua)
$_FILES	Archivos subidos con multipart/form-data
$_SERVER	Información de la petición y del servidor
04 | Validación y saneamiento de datos

Todo dato que llega del navegador puede ser manipulado, aunque el formulario tenga validaciones HTML. Por eso el servidor siempre debe validar (comprobar que el dato cumple las reglas) y sanear (limpiarlo o escaparlo antes de mostrarlo o guardarlo). La extensión filter de PHP facilita ambas tareas.

<?php
$errores = [];

$nombre = trim($_POST['nombre'] ?? '');
if ($nombre === '' || mb_strlen($nombre) > 80) {
    $errores['nombre'] = 'El nombre es obligatorio (máximo 80 caracteres).';
}

$correo = filter_input(INPUT_POST, 'correo', FILTER_VALIDATE_EMAIL);
if ($correo === false || $correo === null) {
    $errores['correo'] = 'Ingrese un correo válido.';
}

$edad = filter_input(INPUT_POST, 'edad', FILTER_VALIDATE_INT,
        ['options' => ['min_range' => 16, 'max_range' => 99]]);
if ($edad === false) {
    $errores['edad'] = 'La edad debe estar entre 16 y 99.';
}

$carrerasValidas = ['SOF', 'SIS'];
$carrera = $_POST['carrera'] ?? '';
if (!in_array($carrera, $carrerasValidas, true)) {   // lista blanca
    $errores['carrera'] = 'Carrera no válida.';
}

if ($errores) {
    foreach ($errores as $msg) echo '<p class="error">' . htmlspecialchars($msg) . '</p>';
} else {
    echo '<p>Registro correcto de ' . htmlspecialchars($nombre) . '</p>';
}

Filtro	Valida o convierte
FILTER_VALIDATE_INT	Entero, con rango opcional
FILTER_VALIDATE_FLOAT	Número decimal
FILTER_VALIDATE_EMAIL	Correo electrónico
FILTER_VALIDATE_URL	Dirección web
FILTER_VALIDATE_BOOLEAN	Valores como on, yes, 1
htmlspecialchars()	Escapa < > & " antes de mostrar texto (previene XSS)
05 | Formulario que se procesa a sí mismo y patrón PRG

Es común que un mismo archivo muestre el formulario y lo procese. Si hay errores, el formulario se vuelve a mostrar con los valores ya escritos; si todo es correcto, se aplica el patrón Post/Redirect/Get: tras procesar el POST se redirige a otra página con GET, de modo que recargar la página no reenvía el formulario.

<?php
// contacto.php
$errores = [];
$valores = ['nombre' => '', 'correo' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $valores['nombre'] = trim($_POST['nombre'] ?? '');
    $valores['correo'] = trim($_POST['correo'] ?? '');

    if ($valores['nombre'] === '') $errores['nombre'] = 'Nombre obligatorio';
    if (!filter_var($valores['correo'], FILTER_VALIDATE_EMAIL)) $errores['correo'] = 'Correo inválido';

    if (!$errores) {
        // ... guardar los datos ...
        header('Location: contacto.php?ok=1');   // Post/Redirect/Get
        exit;
    }
}
$e = fn(string $v) => htmlspecialchars($v, ENT_QUOTES, 'UTF-8');
?>
<?php if (isset($_GET['ok'])): ?>
  <p class="exito">Mensaje enviado correctamente.</p>
<?php endif; ?>

<form method="post" action="contacto.php" novalidate>
  <input name="nombre" value="<?= $e($valores['nombre']) ?>" placeholder="Nombre">
  <small><?= $e($errores['nombre'] ?? '') ?></small>

  <input name="correo" value="<?= $e($valores['correo']) ?>" placeholder="Correo">
  <small><?= $e($errores['correo'] ?? '') ?></small>

  <button>Enviar</button>
</form>

06 | Material de apoyo

    Código fuente del curso (GitHub): https://github.com/lleroc/web

07 | Recursos audiovisuales
RECURSO AUDIOVISUAL 01
Diferencia entre GET y POST
Video

Informatica Studios. (2023, 14 de noviembre). 40 - Diferencia entre el método GET y POST - Formularios | Curso de PHP desde cero [Video]. YouTube. https://www.youtube.com/watch?v=0mHCedEBt3U
RECURSO AUDIOVISUAL 02
Formularios GET y POST: validación y seguridad
Video

Richard Barolin. (2025, 11 de marzo). Curso programación PHP #9: Formularios GET, POST, validación y seguridad [Video]. YouTube. https://www.youtube.com/watch?v=AFiDN9SQOdM
Orientación académica: Se recomienda revisar los materiales audiovisuales y relacionar los procedimientos presentados con los conceptos estudiados en clase.
08 | Bibliografía y fuentes de consulta
Referencias bibliográficas (APA 7)

    The PHP Documentation Group. (2026). Manual de PHP: Tratar con formularios. https://www.php.net/manual/es/tutorial.forms.php
    The PHP Documentation Group. (2026). Manual de PHP: filter_input. https://www.php.net/manual/es/function.filter-input.php
    The PHP Documentation Group. (2026). Manual de PHP: htmlspecialchars. https://www.php.net/manual/es/function.htmlspecialchars.php
    Colaboradores de MDN. (2026, 12 de septiembre). Sending form data. MDN Web Docs. https://developer.mozilla.org/es/docs/Learn_web_development/Extensions/Forms/Sending_and_retrieving_form_data
    Colaboradores de MDN. (2025, 7 de julio). Métodos de petición HTTP. MDN Web Docs. https://developer.mozilla.org/es/docs/Web/HTTP/Reference/Methods
    Fernández Casado, P. E. (2023). Construcción y diseño de páginas web con HTML, CSS y JavaScript (1.ª ed.). RA-MA Editorial. https://elibro.net/es/lc/uniandesecuador/titulos/235052

APLICACIONES WEB
Carrera de Ingeniería de Software
Ing. Luis Llerena | Material académico de apoyo

