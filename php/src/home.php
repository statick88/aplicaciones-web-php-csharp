<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Facturas</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="card shadow">
            <div class="card-header bg-primary text-white">
                <h2>Ingreso de facturas</h2>
            </div>
            <div class="card-body">
                 <form method="post">
                    <!-- Numero de factura-->
                   <div class="mb-3">
                        <label for="numero_factura" class="form-label">Numero de factura</label>
                        <input type="text" name="numero_factura" class="form-control" required>
                   </div>
                    <!-- cedula-->
                     <div class="mb-3">
                        <label for="cedula" class="form-label">Cédula</label>
                        <input type="text" name="cedula" class="form-control" required>
                   </div>
                     <!-- nombre-->
                        <div class="mb-3">
                        <label for="nombre" class="form-label">Nombre</label>
                        <input type="text" name="nombre" class="form-control" required>
                   </div>
                      <!-- telefono-->
                      <div class="mb-3">
                        <label for="telefono" class="form-label">Teléfono</label>
                        <input type="text" name="telefono" class="form-control" required>
                   </div>
                       <!-- Direccion-->
                      <div class="mb-3">
                        <label for="direccion" class="form-label">Dirección</label>
                        <input type="text" name="direccion" class="form-control" required>
                   </div>
                        <!-- mail-->
                      <div class="mb-3">
                        <label for="mail" class="form-label">Correo Electrónico</label>
                        <input type="text" name="mail" class="form-control" required>
                   </div>
                   <div class="mb-3">
                        <button type="submit" class="btn btn-outline-success">
                            Guardar
                        </button>
                   </div>
                </form>
            </div>

        </div>

    </div>

   <?php
        if($_SERVER["REQUEST_METHOD"]=="POST"){
            // --- Persistencia en MariaDB (servicio db del compose) ---
            // Los valores entran CRUDOS por consulta parametrizada;
            // el escapado se hace al imprimirlos (htmlspecialchars más abajo).
            try {
                $dsn = sprintf(
                    "mysql:host=%s;dbname=%s;charset=utf8mb4",
                    getenv("DB_HOST") ?: "db",
                    getenv("DB_NAME") ?: "facturas"
                );
                $pdo = new PDO($dsn, getenv("DB_USER") ?: "app", getenv("DB_PASSWORD") ?: "Practicas2026!");
                $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                // Esquema idempotente (equivalente a Database.Migrate() en EF Core)
                $pdo->exec("CREATE TABLE IF NOT EXISTS facturas (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    numero_factura VARCHAR(20) NOT NULL,
                    cedula VARCHAR(20) NOT NULL,
                    nombre VARCHAR(100) NOT NULL,
                    telefono VARCHAR(30) NOT NULL,
                    direccion VARCHAR(150) NOT NULL,
                    mail VARCHAR(100) NOT NULL
                )");
                $stmt = $pdo->prepare(
                    "INSERT INTO facturas (numero_factura, cedula, nombre, telefono, direccion, mail)
                     VALUES (?, ?, ?, ?, ?, ?)"
                );
                $stmt->execute([
                    $_POST["numero_factura"], $_POST["cedula"], $_POST["nombre"],
                    $_POST["telefono"], $_POST["direccion"], $_POST["mail"],
                ]);
                $facturaId = $pdo->lastInsertId();
            } catch (PDOException $e) {
                $facturaId = null;
                $dbError = $e->getMessage();
            }
            $numero_factura = htmlspecialchars($_POST["numero_factura"]);
            $cedula = htmlspecialchars($_POST["cedula"]);
            $nombre = htmlspecialchars($_POST["nombre"]);
            $direccion = htmlspecialchars($_POST["direccion"]);
            $telefono = htmlspecialchars($_POST["telefono"]);
            $mail = htmlspecialchars($_POST["mail"]);
   ?>
    <div class="card mt-4 shadow">
        <div class="card-header bg-primary text-white">
            <h5 class="mb-0">Datos de la Factura</h5>
        </div>
        <div class="card-body">
            <p><strong>Numero:</strong> <?= $numero_factura ?> </p>
            <p><strong>Nombres:</strong> <?= $nombre ?> </p>
            <p><strong>Cédula:</strong> <?= $cedula ?> </p>
            <p><strong>Dirección:</strong> <?= $direccion ?> </p>
            <p><strong>Teléfono:</strong> <?= $telefono ?> </p>
            <p><strong>Correo Electrónico:</strong> <?= $mail ?> </p>
            <?php if ($facturaId !== null) { ?>
                <p class="text-success mb-0">Guardada en MariaDB (Id <?= $facturaId ?>)</p>
            <?php } else { ?>
                <p class="text-danger mb-0">No se pudo guardar en la base de datos: <?= htmlspecialchars($dbError) ?></p>
            <?php } ?>
        </div>
    </div>

<?php }else{?>
     <div class="card mt-4 shadow">
        <div class="card-header bg-danger text-white">
            <h1 class="mb-0">El metodo no es POST</h1>
        </div>

    </div>
<?php }  ?>

</body>
</html>
