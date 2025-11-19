<?php
declare(strict_types=1);
/**
 * P3 (核销) 综合测试脚本
 *
 * 涵盖三大验收场景：
 * 1. 正常核销：足够余额、在限额内、幂等键未使用
 * 2. 重复点击：相同 idempotency_key 重放
 * 3. 超限场景：超出每日/每单限额
 *
 * 警告：此脚本会向数据库写入真实数据！仅用于测试环境！
 */

header('Content-Type: text/plain; charset=utf-8');

echo "=== P3 次卡核销综合测试 ===\n";
echo "Date: " . date('Y-m-d H:i:s') . "\n\n";

try {
    require_once realpath(__DIR__ . '/../core/config.php');
    require_once realpath(__DIR__ . '/../helpers/pos_helper.php');
} catch (Throwable $e) {
    echo "FATAL: Failed to load dependencies.\n";
    echo $e->getMessage() . "\n";
    exit(1);
}

// Test constants (adjust based on your test data)
const TEST_MEMBER_ID = 1;
const TEST_STORE_ID = 1;
const TEST_USER_ID = 1;
const TEST_MEMBER_PASS_ID = 1;

// Mock cart for testing
$test_cart = [
    [
        'id' => 'cart1',
        'product_id' => 1,
        'variant_id' => 1,
        'title' => 'Test Drink A',
        'title_zh' => '测试饮品A',
        'title_es' => 'Bebida de prueba A',
        'variant_name' => 'Large',
        'variant_name_zh' => '大杯',
        'variant_name_es' => 'Grande',
        'product_code' => 'A1',
        'cup_code' => '1',
        'qty' => 2,
        'base_price_eur' => 5.00,
        'unit_price_eur' => 5.70,
        'ice' => '1',
        'sugar' => '1',
        'addons' => [
            ['key' => 'free_1', 'price' => 0.00],
            ['key' => 'paid_1', 'price' => 0.70]
        ]
    ]
];

$test_payment = [
    'total' => 1.40,
    'paid' => 1.40,
    'change' => 0.0,
    'summary' => [['method' => 'Cash', 'amount' => 1.40]]
];

$all_tests_passed = true;

// ========== TEST 1: 正常核销 ==========
echo "\n========== TEST 1: 正常核销 ==========\n";
try {
    $pdo->beginTransaction();

    $store_config = get_store_config_full($pdo, TEST_STORE_ID);
    $vat_rate = (float)($store_config['default_vat_rate'] ?? 21.0);
    $global_free_addon_limit = (int)($store_config['global_free_addon_limit'] ?? 0);

    $tags_map = get_cart_item_tags($pdo, [1]);
    $addon_defs = get_addons_with_tags($pdo);

    $alloc = calculate_redeem_allocation($pdo, $test_cart, $tags_map, $addon_defs, $global_free_addon_limit);

    $pass_check = get_member_pass_for_update($pdo, TEST_MEMBER_PASS_ID, TEST_MEMBER_ID);
    if (!$pass_check) {
        throw new Exception("Pass not found or invalid");
    }

    echo "Pass status: remaining_uses={$pass_check['remaining_uses']}, " .
         "max_per_order={$pass_check['max_uses_per_order']}, " .
         "daily_remaining=" . ($pass_check['daily_uses_remaining'] ?? 'unlimited') . "\n";

    validate_redeem_limits($pdo, $test_cart, $tags_map, $pass_check);
    echo "✓ Limits validation passed\n";

    $context = [
        'store_id' => TEST_STORE_ID,
        'user_id' => TEST_USER_ID,
        'device_id' => 'test_device_1',
        'member_id' => TEST_MEMBER_ID,
        'pass_id' => TEST_MEMBER_PASS_ID,
        'idempotency_key' => 'test-normal-' . bin2hex(random_bytes(8)),
        'store_config' => $store_config,
        'vat_rate' => $vat_rate
    ];

    $result = create_redeem_records($pdo, $context, $alloc, $test_cart, $tags_map, $addon_defs, $test_payment);

    if ($result['idempotency_used']) {
        throw new Exception("Should not use idempotency for first request");
    }

    echo "✓ Transaction completed\n";
    echo "  - Invoice TP: " . ($result['invoice_number_tp'] ?: 'null') . "\n";
    echo "  - Invoice VR: " . ($result['invoice_number_vr'] ?: 'null') . "\n";
    echo "  - Print jobs: " . count($result['print_jobs']) . "\n";

    $pdo->rollBack();
    echo "✓ TEST 1 PASSED\n";

} catch (Throwable $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    echo "✗ TEST 1 FAILED: " . $e->getMessage() . "\n";
    $all_tests_passed = false;
}

// ========== TEST 2: 重复点击（幂等性） ==========
echo "\n========== TEST 2: 重复点击（幂等性） ==========\n";
try {
    $pdo->beginTransaction();

    $store_config = get_store_config_full($pdo, TEST_STORE_ID);
    $vat_rate = (float)($store_config['default_vat_rate'] ?? 21.0);
    $global_free_addon_limit = (int)($store_config['global_free_addon_limit'] ?? 0);

    $tags_map = get_cart_item_tags($pdo, [1]);
    $addon_defs = get_addons_with_tags($pdo);

    $alloc = calculate_redeem_allocation($pdo, $test_cart, $tags_map, $addon_defs, $global_free_addon_limit);

    $pass_check = get_member_pass_for_update($pdo, TEST_MEMBER_PASS_ID, TEST_MEMBER_ID);
    validate_redeem_limits($pdo, $test_cart, $tags_map, $pass_check);

    $idempotency_key = 'test-idempotency-' . bin2hex(random_bytes(8));

    $context = [
        'store_id' => TEST_STORE_ID,
        'user_id' => TEST_USER_ID,
        'device_id' => 'test_device_2',
        'member_id' => TEST_MEMBER_ID,
        'pass_id' => TEST_MEMBER_PASS_ID,
        'idempotency_key' => $idempotency_key,
        'store_config' => $store_config,
        'vat_rate' => $vat_rate
    ];

    // First request
    echo "First request...\n";
    $result1 = create_redeem_records($pdo, $context, $alloc, $test_cart, $tags_map, $addon_defs, $test_payment);

    if ($result1['idempotency_used']) {
        throw new Exception("First request should not use idempotency");
    }
    echo "✓ First request succeeded\n";

    // Second request with SAME idempotency_key
    echo "Second request (same idempotency_key)...\n";
    $result2 = create_redeem_records($pdo, $context, $alloc, $test_cart, $tags_map, $addon_defs, $test_payment);

    if (!$result2['idempotency_used']) {
        throw new Exception("Second request should use idempotency");
    }

    echo "✓ Second request returned cached result\n";
    echo "  - Invoice TP matches: " . ($result1['invoice_number_tp'] === $result2['invoice_number_tp'] ? 'YES' : 'NO') . "\n";
    echo "  - Invoice VR matches: " . ($result1['invoice_number_vr'] === $result2['invoice_number_vr'] ? 'YES' : 'NO') . "\n";
    echo "  - Print jobs (2nd): " . count($result2['print_jobs']) . " (should be 0)\n";

    if (count($result2['print_jobs']) > 0) {
        throw new Exception("Should not generate print jobs for cached request");
    }

    $pdo->rollBack();
    echo "✓ TEST 2 PASSED\n";

} catch (Throwable $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    echo "✗ TEST 2 FAILED: " . $e->getMessage() . "\n";
    $all_tests_passed = false;
}

// ========== TEST 3: 超出每单限额 ==========
echo "\n========== TEST 3: 超出每单限额 ==========\n";
try {
    $pdo->beginTransaction();

    $store_config = get_store_config_full($pdo, TEST_STORE_ID);
    $tags_map = get_cart_item_tags($pdo, [1]);

    $pass_check = get_member_pass_for_update($pdo, TEST_MEMBER_PASS_ID, TEST_MEMBER_ID);

    // Create a cart that exceeds max_uses_per_order
    $large_cart = [
        [
            'id' => 'cart1',
            'product_id' => 1,
            'variant_id' => 1,
            'title' => 'Test Drink',
            'title_zh' => '测试饮品',
            'title_es' => 'Bebida',
            'variant_name' => 'Large',
            'variant_name_zh' => '大杯',
            'variant_name_es' => 'Grande',
            'product_code' => 'A1',
            'cup_code' => '1',
            'qty' => 100, // Intentionally large
            'base_price_eur' => 5.00,
            'unit_price_eur' => 5.00,
            'ice' => '1',
            'sugar' => '1',
            'addons' => []
        ]
    ];

    $should_fail = false;
    try {
        validate_redeem_limits($pdo, $large_cart, $tags_map, $pass_check);
    } catch (Exception $e) {
        $should_fail = true;
        echo "✓ Validation correctly rejected: " . $e->getMessage() . "\n";
    }

    if (!$should_fail) {
        throw new Exception("Should have failed validation for exceeding limits");
    }

    $pdo->rollBack();
    echo "✓ TEST 3 PASSED\n";

} catch (Throwable $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    echo "✗ TEST 3 FAILED: " . $e->getMessage() . "\n";
    $all_tests_passed = false;
}

// ========== SUMMARY ==========
echo "\n========== 测试总结 ==========\n";
if ($all_tests_passed) {
    echo "✓✓✓ 所有测试通过！✓✓✓\n";
    exit(0);
} else {
    echo "✗✗✗ 部分测试失败，请检查日志 ✗✗✗\n";
    exit(1);
}
