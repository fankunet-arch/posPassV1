#!/usr/bin/env php
<?php
/**
 * POS 班次数据完整性检查工具
 *
 * 目的：检查历史数据中是否存在"已结束但财务字段为空"的班次
 * 阶段：L4-2B-POS-EOD-MINI
 * 相关：ISSUE-POS-EOD-001
 *
 * 本脚本为只读模式（SELECT ONLY），不做任何数据修改。
 * 输出满足以下条件的 pos_shifts 记录：
 *   - status = 'ENDED'（已结束的班次）
 *   - expected_cash IS NULL 或 cash_variance IS NULL 或 payment_summary IS NULL
 *
 * 使用方法：
 *   php check_shift_cash_completeness.php
 *
 * 输出：
 *   - 控制台输出表格格式的结果
 *   - 统计信息：总共多少个不完整班次
 *
 * 注意：
 *   - 真正的数据回填/修复会在另一个阶段单独立项
 *   - 本工具仅用于评估历史数据质量
 */

// 设置错误报告
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 加载数据库配置
$config_path = __DIR__ . '/../../html/pos/config/db_config.php';
if (!file_exists($config_path)) {
    echo "[ERROR] Database configuration file not found: {$config_path}\n";
    echo "[HINT] Please ensure the config file exists and is accessible.\n";
    exit(1);
}

require_once $config_path;

// 连接数据库
try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
} catch (PDOException $e) {
    echo "[ERROR] Database connection failed: " . $e->getMessage() . "\n";
    exit(1);
}

echo "=================================================================\n";
echo "POS 班次数据完整性检查工具\n";
echo "L4-2B-POS-EOD-MINI / ISSUE-POS-EOD-001\n";
echo "=================================================================\n\n";

// 查询不完整的班次记录
$sql = "
    SELECT
        s.id AS shift_id,
        s.store_id,
        s.user_id,
        s.start_time,
        s.end_time,
        s.status,
        s.starting_float,
        s.counted_cash,
        s.expected_cash,
        s.cash_variance,
        s.payment_summary,
        CASE
            WHEN s.expected_cash IS NULL THEN 'YES'
            ELSE 'NO'
        END AS missing_expected_cash,
        CASE
            WHEN s.cash_variance IS NULL THEN 'YES'
            ELSE 'NO'
        END AS missing_cash_variance,
        CASE
            WHEN s.payment_summary IS NULL THEN 'YES'
            ELSE 'NO'
        END AS missing_payment_summary
    FROM pos_shifts s
    WHERE s.status = 'ENDED'
      AND (
          s.expected_cash IS NULL
          OR s.cash_variance IS NULL
          OR s.payment_summary IS NULL
      )
    ORDER BY s.start_time DESC
    LIMIT 1000
";

try {
    $stmt = $pdo->query($sql);
    $incomplete_shifts = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    echo "[ERROR] Query failed: " . $e->getMessage() . "\n";
    exit(1);
}

// 输出结果
if (empty($incomplete_shifts)) {
    echo "[SUCCESS] 所有已结束的班次 (status='ENDED') 都已包含完整的财务字段。\n";
    echo "          没有需要修复的历史数据。\n\n";
} else {
    $count = count($incomplete_shifts);
    echo "[WARNING] 发现 {$count} 个已结束但财务字段不完整的班次。\n\n";

    echo "字段说明：\n";
    echo "  - shift_id:               班次ID\n";
    echo "  - store_id:               门店ID\n";
    echo "  - start_time / end_time:  开始/结束时间 (UTC)\n";
    echo "  - counted_cash:           清点现金\n";
    echo "  - expected_cash:          系统理论现金\n";
    echo "  - cash_variance:          现金差异\n";
    echo "  - payment_summary:        支付方式汇总 (JSON)\n";
    echo "  - missing_*:              该字段是否缺失 (YES/NO)\n\n";

    // 输出表格头
    printf(
        "%-10s %-10s %-20s %-20s %-15s %-15s %-15s %-10s %-10s %-10s\n",
        "shift_id", "store_id", "start_time", "end_time",
        "counted_cash", "expected_cash", "cash_variance",
        "miss_exp", "miss_var", "miss_pay"
    );
    echo str_repeat("-", 150) . "\n";

    // 输出每一行
    foreach ($incomplete_shifts as $shift) {
        printf(
            "%-10s %-10s %-20s %-20s %-15s %-15s %-15s %-10s %-10s %-10s\n",
            $shift['shift_id'],
            $shift['store_id'],
            $shift['start_time'],
            $shift['end_time'],
            $shift['counted_cash'] ?? 'NULL',
            $shift['expected_cash'] ?? 'NULL',
            $shift['cash_variance'] ?? 'NULL',
            $shift['missing_expected_cash'],
            $shift['missing_cash_variance'],
            $shift['missing_payment_summary']
        );
    }

    echo "\n";
    echo "[INFO] 共 {$count} 条不完整记录（最多显示前1000条）。\n";
    echo "[INFO] 这些班次在正常关班时未写入 expected_cash / cash_variance / payment_summary。\n";
    echo "[INFO] 代码修复后，新的关班操作将自动写入这些字段。\n";
    echo "[INFO] 历史数据的回填/修复将在后续专门的数据迁移阶段处理。\n\n";
}

// 统计总班次数
try {
    $stmt_total = $pdo->query("SELECT COUNT(*) FROM pos_shifts WHERE status = 'ENDED'");
    $total_ended_shifts = (int)$stmt_total->fetchColumn();

    echo "=================================================================\n";
    echo "统计摘要：\n";
    echo "  - 总已结束班次数量：{$total_ended_shifts}\n";
    if (!empty($incomplete_shifts)) {
        $incomplete_count = count($incomplete_shifts);
        $complete_count = $total_ended_shifts - $incomplete_count;
        $incomplete_pct = $total_ended_shifts > 0 ? round(($incomplete_count / $total_ended_shifts) * 100, 2) : 0;
        echo "  - 字段完整的班次：{$complete_count}\n";
        echo "  - 字段不完整的班次：{$incomplete_count} ({$incomplete_pct}%)\n";
    }
    echo "=================================================================\n\n";
} catch (PDOException $e) {
    echo "[WARNING] Could not fetch total count: " . $e->getMessage() . "\n";
}

echo "[DONE] 检查完成。\n";
exit(0);
