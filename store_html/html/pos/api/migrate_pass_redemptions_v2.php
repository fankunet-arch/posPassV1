<?php
/**
 * Migration API v2: Fix BOTH pass_redemptions AND pass_redemption_batches tables
 * Date: 2025-11-20
 *
 * 访问: /pos/api/migrate_pass_redemptions_v2.php
 *
 * 作用: 修复两个表的 order_id 字段，允许它们为 NULL（用于 0元核销场景）
 * - pass_redemption_batches.order_id
 * - pass_redemptions.order_id 和 order_item_id
 */

// Load core config
require_once realpath(__DIR__ . '/../../../pos_backend/core/config.php');
require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_json_helper.php');

// Check if session is active (basic security)
session_start();
if (!isset($_SESSION['pos_user_id']) || !isset($_SESSION['pos_store_id'])) {
    json_error('未授权访问 (Unauthorized)', 401);
}

// Only allow specific users
$allowed_users = [1]; // 仅允许 user_id=1 执行迁移
if (!in_array($_SESSION['pos_user_id'], $allowed_users)) {
    json_error('权限不足 (Forbidden)', 403);
}

try {
    echo "<h1>Migration v2: Fix pass_redemption tables</h1>\n";
    echo "<pre>\n";

    // 1. Check current structure of pass_redemption_batches
    echo "=== 1. Checking pass_redemption_batches structure ===\n";
    $stmt = $pdo->query("DESCRIBE pass_redemption_batches");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $batch_order_id_nullable = false;
    foreach ($columns as $col) {
        if ($col['Field'] === 'order_id') {
            $batch_order_id_nullable = ($col['Null'] === 'YES');
            echo "  pass_redemption_batches.order_id: {$col['Type']} | NULL={$col['Null']}\n";
        }
    }

    // 2. Check current structure of pass_redemptions
    echo "\n=== 2. Checking pass_redemptions structure ===\n";
    $stmt = $pdo->query("DESCRIBE pass_redemptions");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $detail_order_id_nullable = false;
    $detail_order_item_id_nullable = false;
    foreach ($columns as $col) {
        if ($col['Field'] === 'order_id') {
            $detail_order_id_nullable = ($col['Null'] === 'YES');
            echo "  pass_redemptions.order_id: {$col['Type']} | NULL={$col['Null']}\n";
        }
        if ($col['Field'] === 'order_item_id') {
            $detail_order_item_id_nullable = ($col['Null'] === 'YES');
            echo "  pass_redemptions.order_item_id: {$col['Type']} | NULL={$col['Null']}\n";
        }
    }

    // 3. Run migration if needed
    $migration_needed = !$batch_order_id_nullable || !$detail_order_id_nullable || !$detail_order_item_id_nullable;

    if ($migration_needed) {
        echo "\n=== 3. Running migration ===\n";

        // Fix pass_redemption_batches.order_id
        if (!$batch_order_id_nullable) {
            echo "  Modifying pass_redemption_batches.order_id to allow NULL...\n";
            $pdo->exec("ALTER TABLE pass_redemption_batches MODIFY COLUMN order_id int UNSIGNED NULL COMMENT 'FK, 关联 pos_invoices.id (TP税票ID, 0元核销时为NULL)'");
            echo "  ✓ pass_redemption_batches.order_id modified\n";
        } else {
            echo "  ✓ pass_redemption_batches.order_id already allows NULL (skipped)\n";
        }

        // Fix pass_redemptions.order_id
        if (!$detail_order_id_nullable) {
            echo "  Modifying pass_redemptions.order_id to allow NULL...\n";
            $pdo->exec("ALTER TABLE pass_redemptions MODIFY COLUMN order_id int UNSIGNED NULL COMMENT 'FK, 关联 pos_invoices.id (TP税票ID, 0元核销时为NULL)'");
            echo "  ✓ pass_redemptions.order_id modified\n";
        } else {
            echo "  ✓ pass_redemptions.order_id already allows NULL (skipped)\n";
        }

        // Fix pass_redemptions.order_item_id
        if (!$detail_order_item_id_nullable) {
            echo "  Modifying pass_redemptions.order_item_id to allow NULL...\n";
            $pdo->exec("ALTER TABLE pass_redemptions MODIFY COLUMN order_item_id int UNSIGNED NULL COMMENT 'FK, 关联 pos_invoice_items.id (对应单品, 0元核销时为NULL)'");
            echo "  ✓ pass_redemptions.order_item_id modified\n";
        } else {
            echo "  ✓ pass_redemptions.order_item_id already allows NULL (skipped)\n";
        }

        echo "\n=== 4. Verifying changes ===\n";

        // Verify pass_redemption_batches
        $stmt = $pdo->query("DESCRIBE pass_redemption_batches");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($columns as $col) {
            if ($col['Field'] === 'order_id') {
                echo "  pass_redemption_batches.order_id: {$col['Type']} | NULL={$col['Null']}\n";
            }
        }

        // Verify pass_redemptions
        $stmt = $pdo->query("DESCRIBE pass_redemptions");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($columns as $col) {
            if (in_array($col['Field'], ['order_id', 'order_item_id'])) {
                echo "  pass_redemptions.{$col['Field']}: {$col['Type']} | NULL={$col['Null']}\n";
            }
        }

        echo "\n✓✓✓ Migration completed successfully! ✓✓✓\n";
    } else {
        echo "\n=== Migration not needed ===\n";
        echo "All order_id and order_item_id fields already allow NULL.\n";
    }

    echo "\n</pre>\n";
    echo "<p style='color: green; font-weight: bold;'>✓ 数据库迁移成功！您现在可以测试 0 元核销功能了。</p>\n";
    echo "<p style='color: orange;'>注意：如果仍然出现错误，请清除浏览器缓存并硬刷新页面 (Ctrl+Shift+R)</p>\n";

} catch (Exception $e) {
    echo "\n<p style='color: red; font-weight: bold;'>✗ Migration failed: " . htmlspecialchars($e->getMessage()) . "</p>\n";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>\n";
}
