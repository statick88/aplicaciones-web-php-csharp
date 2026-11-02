<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Variables en PHP</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="card shadow">
            <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
                <h2 class="mb-0">Variables en PHP (S1C2)</h2>
                <a href="home.php" class="btn btn-sm btn-outline-light">Ejercicio facturas</a>
            </div>
            <div class="card-body">

                <h5>Declaración, tipos y conversiones</h5>
                <table class="table table-striped mb-0">
                    <thead>
                        <tr><th>Concepto</th><th>Código</th><th>Valor</th><th>Tipo (<code>gettype</code>)</th></tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>string</td>
                            <td><code>$curso = "Aplicaciones Web";</code></td>
                            <td><?= $curso ?></td>
                            <td><code><?= gettype($curso) ?></code></td>
                        </tr>
                        <tr>
                            <td>float</td>
                            <td><code>$nota = 9.5;</code></td>
                            <td><?= $nota ?></td>
                            <td><code><?= gettype($nota) ?></code></td>
                        </tr>
                        <tr>
                            <td>bool</td>
                            <td><code>$inscrito = true;</code></td>
                            <td><?= var_export($inscrito, true) ?></td>
                            <td><code><?= gettype($inscrito) ?></code></td>
                        </tr>
                        <tr>
                            <td>Conversión implícita</td>
                            <td><code>$sumaImplicita = "3" + 3;</code></td>
                            <td><?= $sumaImplicita ?></td>
                            <td><code><?= gettype($sumaImplicita) ?></code></td>
                        </tr>
                        <tr>
                            <td>Conversión explícita</td>
                            <td><code>$edadTexto = (string) 25;</code></td>
                            <td><?= $edadTexto ?></td>
                            <td><code><?= gettype($edadTexto) ?></code></td>
                        </tr>
                    </tbody>
                </table>

                <h5 class="mt-4">Constantes, nulos e interpolación</h5>
                <table class="table table-striped mb-0">
                    <thead>
                        <tr><th>Concepto</th><th>Código</th><th>Valor</th></tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><code>const</code> (config)</td>
                            <td><code>const CURSO = 'Aplicaciones Web';</code></td>
                            <td><?= CURSO ?></td>
                        </tr>
                        <tr>
                            <td><code>define()</code> (config)</td>
                            <td><code>define('ETIQUETA', 'Semana 1');</code></td>
                            <td><?= ETIQUETA ?></td>
                        </tr>
                        <tr>
                            <td>null</td>
                            <td><code>$docente = null;</code></td>
                            <td><?= var_export($docente, true) ?> <code>(<?= gettype($docente) ?>)</code></td>
                        </tr>
                        <tr>
                            <td>Interpolación</td>
                            <td><code>$saludo = "Estudiante: $curso";</code></td>
                            <td><?= $saludo ?></td>
                        </tr>
                        <tr>
                            <td><code>??</code> con null</td>
                            <td><code>$notaFinal = $docente ?? 'sin nota';</code></td>
                            <td><?= $notaFinal ?></td>
                        </tr>
                    </tbody>
                </table>

                <h5 class="mt-4">Ámbito de las variables</h5>
                <ul class="list-group">
                    <li class="list-group-item">
                        <strong>Global (nivel archivo):</strong> <code>$curso</code> existe en todo el archivo.
                    </li>
                    <li class="list-group-item">
                        <strong>Local (dentro de una función):</strong> sin <code>global</code> &rarr;
                        <code><?= sinGlobal() ?></code>; con <code>global $curso</code> &rarr;
                        <code><?= conGlobal() ?></code>
                    </li>
                    <li class="list-group-item">
                        <strong>Parámetro vs. global:</strong> <code>cursoDe("Aplicaciones Web")</code> &rarr;
                        <code><?= cursoDe('Aplicaciones Web') ?></code> (la función recibe su dependencia
                        como parámetro en lugar de leer <code>global</code>).
                    </li>
                    <li class="list-group-item">
                        <strong>"Bloque":</strong> PHP <strong>no</strong> tiene &aacute;mbito de bloque: tras el
                        <code>foreach</code>, <code>$valor</code> sigue valiendo
                        <code><?= $valorTrasElBucle ?></code> y <code>$recorrido</code> =
                        <code><?= $recorrido ?></code> (en C# <code>$valor</code> ya no existir&iacute;a fuera del bucle).
                    </li>
                </ul>

            </div>
        </div>
        <p class="text-center mt-3"><a href="index.php">Volver al inicio</a></p>
    </div>
</body>
</html>
