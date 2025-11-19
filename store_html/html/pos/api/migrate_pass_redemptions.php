<?php
/**
 * Migration API: Fix pass_redemptions table
 * Date: 2025-11-19
 *
 * 访问: /pos/api/migrate_pass_redemptions.php
 *
 * 作用: 修复 pass_redemptions 表的 order_id 和 order_item_id 字段，
 * 允许它们为 NULL（用于 0元核销场景）
 */

// Load core config
require_once realpath(__DIR__ . '/../../../pos_backend/core/config.php');
require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_json_helper.php');

// Check if session is active (basic security)
session_start();
if (!isset($_SESSION['pos_user_id']) || !isset($_SESSION['pos_store_id'])) {
    json_error('未授权访问 (Unauthorized)', 401);
}

// Only allow specific users (optional: add role check here)
$allowed_users = [1]; // 仅允许 user_id=1 执行迁移
if (!in_array($_SESSION['pos_user_id'], $allowed_users)) {
    json_error('权限不足 (Forbidden)', 403);
}

try {
    echo "<h1>Migration: Fix pass_redemptions table</h1>\n";
    echo "<pre>\n";

    // 1. Check current structure
    echo "=== 1. Checking current table structure ===\n";
    $stmt = $pdo->query("DESCRIBE pass_redemptions");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $order_id_nullable = false;
    $order_item_id_nullable = false;

    foreach ($columns as $col) {
        if ($col['Field'] === 'order_id') {
            $order_id_nullable = ($col['Null'] === 'YES');
            echo "  order_id: {$col['Type']} | NULL={$col['Null']}\n";
        }
        if ($col['Field'] === 'order_item_id') {
            $order_item_id_nullable = ($col['Null'] === 'YES');
            echo "  order_item_id: {$col['Type']} | NULL={$col['Null']}\n";
        }
    }

    // 2. Run migration if needed
    if (!$order_id_nullable || !$order_item_id_nullable) {
        echo "\n=== 2. Running migration ===\n";

        if (!$order_id_nullable) {
            echo "  Modifying order_id to allow NULL...\n";
            $pdo->exec("ALTER TABLE pass_redemptions MODIFY COLUMN order_id int UNSIGNED NULL COMMENT 'FK, 关联 pos_invoices.id (TP税票ID, 0元核销时为NULL)'");
            echo "  ✓ order_id modified\n";
        } else {
            echo "  ✓ order_id already allows NULL (skipped)\n";
        }

        if (!$order_item_id_nullable) {
            echo "  Modifying order_item_id to allow NULL...\n";
            $pdo->exec("ALTER TABLE pass_redemptions MODIFY COLUMN order_item_id int UNSIGNED NULL COMMENT 'FK, 关联 pos_invoice_items.id (对应单品, 0元核销时为NULL)'");
            echo "  ✓ order_item_id modified\n";
        } else {
            echo "  ✓ order_item_id already allows NULL (skipped)\n";
        }

        echo "\n=== 3. Verifying changes ===\n";
        $stmt = $pdo->query("DESCRIBE pass_redemptions");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($columns as $col) {
            if (in_array($col['Field'], ['order_id', 'order_item_id'])) {
                echo "  {$col['Field']}: {$col['Type']} | NULL={$col['Null']}\n";
            }
        }

        echo "\n✓✓✓ Migration completed successfully! ✓✓✓\n";
    } else {
        echo "\n=== Migration not needed ===\n";
        echo "Both order_id and order_item_id already allow NULL.\n";
    }

    echo "\n</pre>\n";
    echo "<p style='color: green; font-weight: bold;'>✓ 数据库迁移成功！您现在可以测试 0 元核销功能了。</p>\n";

} catch (Exception $e) {
    echo "\n<p style='color: red; font-weight: bold;'>✗ Migration failed: " . htmlspecialchars($e->getMessage()) . "</p>\n";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>\n";
}
