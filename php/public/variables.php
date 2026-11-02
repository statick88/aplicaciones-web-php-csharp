<?php
declare(strict_types=1);

// S1C2 demo entry point (Apache docroot). Separates configuration, logic
// and presentation with require: a missing file stops the script, which is
// why require is preferred over include here (see ebook, Class 1).
require __DIR__ . '/../config/config.php';
require __DIR__ . '/../src/variables.php';
require __DIR__ . '/../views/variables.php';
