<?php

declare(strict_types=1);

// Edit this file while the container is running and refresh the browser:
// the change shows up immediately, no rebuild needed.
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PHP Practice</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 4rem auto; padding: 0 1rem; }
        code { background: #f2f2f2; padding: 0.15rem 0.35rem; border-radius: 4px; }
    </style>
</head>
<body>
    <h1>PHP is running in Docker</h1>
    <p>PHP version: <code><?= PHP_VERSION ?></code></p>
    <p>Server time: <code><?= date('Y-m-d H:i:s') ?></code></p>
    <p>Now edit <code>src/index.php</code> and refresh this page.</p>
    <p>Practice: <a href="variables.php"><code>variables.php</code></a> (S1C2 variables &amp; scope) &middot; <a href="home.php"><code>home.php</code></a> (invoice exercise)</p>
</body>
</html>
