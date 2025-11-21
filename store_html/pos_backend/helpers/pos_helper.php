<?php
// pos_helper.php
// 核心助手函数

/**
 * 确保当前有一个活动的班次，否则抛出错误。
 * 这是所有销售和资金操作的保护锁。
 */
function ensure_active_shift_or_fail(PDO $pdo): int {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    $shift_id = (int)($_SESSION['pos_shift_id'] ?? 0);
    $store_id = (int)($_SESSION['pos_store_id'] ?? 0);
    $user_id = (int)($_SESSION['pos_user_id'] ?? 0);

    // [FIX 2025-11-20] 启用数据库验证，不再仅信任 session
    if ($shift_id > 0 && $store_id > 0 && $user_id > 0) {
        // 验证 shift_id 是否在数据库中且未关闭
        $stmt = $pdo->prepare("SELECT 1 FROM pos_shifts WHERE id = ? AND store_id = ? AND user_id = ? AND status = 'ACTIVE' AND end_time IS NULL");
        $stmt->execute([$shift_id, $store_id, $user_id]);
        if ($stmt->fetchColumn()) {
            // 班次有效，返回
            return $shift_id;
        }

        // [FIX 2025-11-20] 如果数据库中班次无效，清除 session
        error_log("[SHIFT_GUARD] Session shift_id={$shift_id} is invalid or ended, clearing session");
        unset($_SESSION['pos_shift_id']);
    }

    // 如果 session 中没有，或数据库验证失败，触发班次保护
    json_error('No active shift found. Please start a shift.', 403, ['error_code' => 'NO_ACTIVE_SHIFT']);
    exit;
}

/**
 * 计算EOD（日结）或班次交接的总额。
 *
 * @deprecated This function is deprecated and should not be used.
 * @see pos_repo::getInvoiceSummaryForPeriod() for the current implementation
 *
 * @param PDO $pdo 数据库连接
 * @param int $store_id 门店ID
 * @param string $start_time (UTC) 开始时间 (Y-m-d H:i:s)
 * @param string $end_time (UTC) 结束时间 (Y-m-d H:i:s)
 * @return array 包含总额的数组
 * @throws Exception Always throws exception indicating deprecation
 */
function calculate_eod_totals(PDO $pdo, int $store_id, string $start_time, string $end_time): array {
    // [SECURITY FIX 2025-11-21] 熔断废弃函数，防止引用不存在的 pos_invoice_payments 表
    // 该函数是旧实现残留，查询了不存在的表，会导致 SQLSTATE[42S02] 错误
    // 现行 EOD 实现位于：pos_backend/helpers/pos_repo.php::getInvoiceSummaryForPeriod()
    // 参考技术债文档：ISSUE-POS-DB-001

    throw new Exception(
        "DEPRECATED: calculate_eod_totals() is a legacy function that references non-existent table 'pos_invoice_payments'. " .
        "Use pos_repo::getInvoiceSummaryForPeriod() instead. See ISSUE-POS-DB-001 in technical debt documentation."
    );

    // ============================================================================
    // 原有实现已删除（~100 行 SQL 逻辑访问不存在的 pos_invoice_payments 表）
    // 如需查看历史实现，请参考 Git 历史记录
    // ============================================================================
}


/**
 * [GEMINI FIX 2025-11-16]
 * 添加 pos_registry_member_pass.php 所需的缺失函数 gen_uuid_v4。
 * 这是导致“创建会员”失败的根本原因。
 *
 * 生成一个符合 RFC 4122 标准的 Version 4 UUID。
 *
 * @return string 格式为 "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx" 的 UUID。
 * @throws Exception 如果无法收集到足够的加密随机数据。
 */
function gen_uuid_v4(): string {
    // 1. 生成 16 字节 (128 位) 的随机数据
    $data = random_bytes(16);

    // 2. 设置 UUID 版本 (Version 4)
    // 字节 6 (索引 6) 的高 4 位必须是 0100 (binary)
    $data[6] = chr(ord($data[6]) & 0x0f | 0x40);

    // 3. 设置 UUID 变体 (Variant 10xx)
    // 字节 8 (索引 8) 的高 2 位必须是 10 (binary)
    $data[8] = chr(ord($data[8]) & 0x3f | 0x80);

    // 4. 将 16 字节的二进制数据格式化为 36 个字符的十六进制字符串
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}