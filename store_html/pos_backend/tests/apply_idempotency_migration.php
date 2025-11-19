<?php
declare(strict_types=1);
/**
 * Apply idempotency_key migration to pass_redemption_batches
 *
 * This script:
 * 1. Adds idempotency_key field to pass_redemption_batches table
 * 2. Creates unique index on (member_pass_id, idempotency_key)
 *
 * Safe to run multiple times (will skip if already applied)
 */

header('Content-Type: text/plain; charset=utf-8');

echo "=== Applying Idempotency Migration ===\n";
echo "Date: " . date('Y-m-d H:i:s') . "\n\n";

try {
    require_once realpath(__DIR__ . '/../core/config.php');

    echo "Step 1: Checking if idempotency_key field exists...\n";

    $stmt = $pdo->query("DESCRIBE pass_redemption_batches");
    $fields = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $has_idempotency_key = false;
    foreach ($fields as $field) {
        if ($field['Field'] === 'idempotency_key') {
            $has_idempotency_key = true;
            break;
        }
    }

    if ($has_idempotency_key) {
        echo "✓ idempotency_key field already exists, skipping field creation.\n\n";
    } else {
        echo "✗ idempotency_key field does not exist, adding...\n";

        $sql_add_field = "
            ALTER TABLE `pass_redemption_batches`
            ADD COLUMN `idempotency_key` VARCHAR(255) NULL COMMENT '幂等键，防止重复提交' AFTER `batch_id`
        ";

        $pdo->exec($sql_add_field);
        echo "✓ idempotency_key field added successfully.\n\n";
    }

    echo "Step 2: Checking if unique index exists...\n";

    $stmt = $pdo->query("SHOW INDEX FROM pass_redemption_batches WHERE Key_name = 'idx_member_pass_idempotency'");
    $index = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($index) {
        echo "✓ Unique index 'idx_member_pass_idempotency' already exists, skipping index creation.\n\n";
    } else {
        echo "✗ Unique index does not exist, creating...\n";

        $sql_add_index = "
            CREATE UNIQUE INDEX `idx_member_pass_idempotency`
            ON `pass_redemption_batches` (`member_pass_id`, `idempotency_key`)
        ";

        $pdo->exec($sql_add_index);
        echo "✓ Unique index created successfully.\n\n";
    }

    echo "=== Migration Completed Successfully ===\n";
    echo "\nVerifying final structure...\n";

    $stmt = $pdo->query("SHOW CREATE TABLE pass_redemption_batches");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "\nTable structure:\n";
    echo $result['Create Table'] . "\n";

} catch (PDOException $e) {
    echo "\n!!! ERROR !!!\n";
    echo "Migration failed: " . $e->getMessage() . "\n";
    echo "Error Code: " . $e->getCode() . "\n";
    echo "\nPlease check the error and try again.\n";
    exit(1);
} catch (Throwable $e) {
    echo "\n!!! UNEXPECTED ERROR !!!\n";
    echo $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}
