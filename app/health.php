<?php
declare(strict_types=1);
require __DIR__ . '/bootstrap.php';

// Simple health endpoint: HTTP 200 when PHP and the database both work, 500 otherwise.
header('Content-Type: text/plain');

$count = db()->query('SELECT COUNT(*) FROM students')->fetchColumn();

echo "OK\n";
echo 'PHP version: ' . PHP_VERSION . "\n";
echo "Database: connected\n";
echo 'Records in students table: ' . $count . "\n";
echo 'Time: ' . date('c') . "\n";
