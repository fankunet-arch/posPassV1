<?php
/**
 * Check pass_redemption_batches table structure
 */
require_once realpath(__DIR__ . '/../core/config.php');

echo "=== Checking pass_redemption_batches table structure ===\n\n";

try {
    $stmt = $pdo->query("SHOW CREATE TABLE pass_redemption_batches");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo $result['Create Table'] . "\n\n";

    echo "=== Checking for idempotency_key field ===\n";
    $stmt = $pdo->query("DESCRIBE pass_redemption_batches");
    $fields = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $has_idempotency_key = false;
    foreach ($fields as $field) {
        if ($field['Field'] === 'idempotency_key') {
            $has_idempotency_key = true;
            echo "✓ idempotency_key field EXISTS\n";
            echo "  Type: {$field['Type']}\n";
            echo "  Null: {$field['Null']}\n";
            echo "  Key: {$field['Key']}\n";
        }
    }

    if (!$has_idempotency_key) {
        echo "✗ idempotency_key field DOES NOT EXIST\n";
        echo "  This field needs to be added for proper idempotency support.\n";
    }

    echo "\n=== Checking indexes ===\n";
    $stmt = $pdo->query("SHOW INDEX FROM pass_redemption_batches");
    $indexes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($indexes as $idx) {
        echo "Index: {$idx['Key_name']}, Column: {$idx['Column_name']}, Unique: {$idx['Non_unique']}\n";
    }

} catch (PDOException $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
