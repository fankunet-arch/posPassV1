<?php
/**
 * 完整的会员查找500错误诊断
 * 这个脚本会逐步检查所有可能导致500错误的环节
 * 访问：https://storev3.toptea.es/pos/api/diagnose_500.php?phone=YOUR_PHONE
 */

error_reporting(E_ALL);
ini_set('display_errors', '1');
header('Content-Type: text/html; charset=utf-8');

echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>会员查找500错误诊断</title></head><body>";
echo "<h1>会员查找500错误诊断</h1>";
echo "<pre style='background:#f5f5f5;padding:20px;border:1px solid #ccc;'>";

$test_phone = $_GET['phone'] ?? '123456';
echo "测试手机号: $test_phone\n";
echo "时间: " . date('Y-m-d H:i:s') . "\n";
echo str_repeat("=", 80) . "\n\n";

$errors = [];
$warnings = [];

// ===== 步骤1: 检查核心文件 =====
echo "【步骤1】检查核心文件...\n";
$core_files = [
    'config' => '../../../pos_backend/core/config.php',
    'json_helper' => '../../../pos_backend/helpers/pos_json_helper.php',
    'datetime_helper' => '../../../pos_backend/helpers/pos_datetime_helper.php',
    'helper' => '../../../pos_backend/helpers/pos_helper.php',
    'repo' => '../../../pos_backend/helpers/pos_repo.php',
    'repo_ext_pass' => '../../../pos_backend/helpers/pos_repo_ext_pass.php',
    'member_handler' => 'registries/pos_registry_member_pass.php',
];

foreach ($core_files as $name => $path) {
    $full_path = realpath(__DIR__ . '/' . $path);
    if (!$full_path || !file_exists($full_path)) {
        $errors[] = "文件不存在: $name ($path)";
        echo "  ❌ $name\n";
    } else {
        echo "  ✓ $name: $full_path\n";
    }
}

if (!empty($errors)) {
    echo "\n致命错误：核心文件缺失\n";
    foreach ($errors as $err) echo "  - $err\n";
    exit(1);
}

echo "\n";

// ===== 步骤2: 加载文件并检查语法 =====
echo "【步骤2】加载核心文件...\n";

try {
    // 模拟session
    @session_start();
    if (!isset($_SESSION['pos_user_id'])) {
        $_SESSION['pos_user_id'] = 1;
        $_SESSION['pos_store_id'] = 1;
        $_SESSION['pos_device_id'] = 1;
        $_SESSION['pos_lang'] = 'zh';
        echo "  ✓ 已设置测试session\n";
    }

    // 按顺序加载
    require_once realpath(__DIR__ . '/../../../pos_backend/core/config.php');
    echo "  ✓ config.php\n";

    require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_json_helper.php');
    echo "  ✓ pos_json_helper.php\n";

    require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_datetime_helper.php');
    echo "  ✓ pos_datetime_helper.php\n";

    require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_helper.php');
    echo "  ✓ pos_helper.php\n";

    require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_repo.php');
    echo "  ✓ pos_repo.php\n";

    require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_repo_ext_pass.php');
    echo "  ✓ pos_repo_ext_pass.php\n";

    require_once __DIR__ . '/registries/pos_registry_member_pass.php';
    echo "  ✓ pos_registry_member_pass.php\n";

} catch (Throwable $e) {
    echo "\n❌ 加载文件时出错:\n";
    echo "  类型: " . get_class($e) . "\n";
    echo "  消息: " . $e->getMessage() . "\n";
    echo "  文件: " . $e->getFile() . ":" . $e->getLine() . "\n";
    exit(1);
}

echo "\n";

// ===== 步骤3: 检查所有必需函数 =====
echo "【步骤3】检查所有必需函数...\n";

$required_functions = [
    // JSON helpers
    'json_ok', 'json_error', 'get_request_data',
    // Datetime helpers
    'utc_now',
    // Member handlers
    'handle_member_find', 'handle_member_create',
    // Pass helpers
    'get_member_active_passes',
];

foreach ($required_functions as $func) {
    if (!function_exists($func)) {
        $errors[] = "函数不存在: $func";
        echo "  ❌ $func\n";
    } else {
        echo "  ✓ $func\n";
    }
}

if (!empty($errors)) {
    echo "\n致命错误：必需函数缺失\n";
    foreach ($errors as $err) echo "  - $err\n";
    exit(1);
}

echo "\n";

// ===== 步骤4: 检查数据库连接 =====
echo "【步骤4】检查数据库连接...\n";

if (!isset($pdo)) {
    echo "  ❌ \$pdo 未定义\n";
    exit(1);
}

try {
    $stmt = $pdo->query("SELECT DATABASE() as db, VERSION() as ver");
    $info = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "  ✓ 数据库: {$info['db']}\n";
    echo "  ✓ 版本: {$info['ver']}\n";
} catch (PDOException $e) {
    echo "  ❌ 数据库连接失败: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\n";

// ===== 步骤5: 检查数据库表结构 =====
echo "【步骤5】检查数据库表结构...\n";

$required_tables = ['pos_members', 'pos_member_levels'];

foreach ($required_tables as $table) {
    try {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if (!$stmt->fetch()) {
            $errors[] = "表不存在: $table";
            echo "  ❌ $table (不存在)\n";
            continue;
        }

        // 检查字段
        $stmt = $pdo->query("DESCRIBE $table");
        $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "  ✓ $table (" . count($columns) . " 字段)\n";

        // 检查关键字段
        if ($table === 'pos_members') {
            $expected = ['id', 'phone_number', 'first_name', 'last_name', 'email', 'member_level_id', 'is_active'];
            foreach ($expected as $col) {
                if (!in_array($col, $columns)) {
                    $warnings[] = "表 $table 缺少字段: $col";
                    echo "    ⚠️  缺少字段: $col\n";
                }
            }
        }

        if ($table === 'pos_member_levels') {
            $expected = ['id', 'level_name_zh', 'level_name_es'];
            foreach ($expected as $col) {
                if (!in_array($col, $columns)) {
                    $warnings[] = "表 $table 缺少字段: $col";
                    echo "    ⚠️  缺少字段: $col\n";
                }
            }
        }

    } catch (PDOException $e) {
        $errors[] = "检查表 $table 失败: " . $e->getMessage();
        echo "  ❌ $table: " . $e->getMessage() . "\n";
    }
}

echo "\n";

// ===== 步骤6: 测试SQL查询 =====
echo "【步骤6】测试会员查找SQL...\n";

$sql = "
    SELECT m.*, ml.level_name_zh, ml.level_name_es
    FROM pos_members m
    LEFT JOIN pos_member_levels ml ON m.member_level_id = ml.id
    WHERE TRIM(m.phone_number) = ?
      AND m.is_active = 1
";

echo "SQL: " . preg_replace('/\s+/', ' ', $sql) . "\n";
echo "参数: ['$test_phone']\n\n";

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$test_phone]);
    $member = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($member) {
        echo "  ✓ 查询成功，找到会员\n";
        echo "    ID: " . $member['id'] . "\n";
        echo "    手机: " . ($member['phone_number'] ?? 'N/A') . "\n";
        echo "    姓名: " . trim(($member['first_name'] ?? '') . ' ' . ($member['last_name'] ?? '')) . "\n";
        echo "    等级: " . ($member['level_name_zh'] ?? 'N/A') . "\n";
    } else {
        echo "  ℹ️  未找到会员 (这是正常的)\n";
    }
} catch (PDOException $e) {
    echo "  ❌ SQL执行失败\n";
    echo "    错误: " . $e->getMessage() . "\n";
    echo "    SQL State: " . ($e->errorInfo[0] ?? 'N/A') . "\n";
    echo "    Driver Code: " . ($e->errorInfo[1] ?? 'N/A') . "\n";
    $errors[] = "SQL查询失败: " . $e->getMessage();
}

echo "\n";

// ===== 步骤7: 测试 get_member_active_passes =====
if (isset($member) && $member) {
    echo "【步骤7】测试获取会员次卡...\n";
    try {
        $passes = get_member_active_passes($pdo, (int)$member['id']);
        echo "  ✓ 次卡查询成功\n";
        echo "    数量: " . count($passes) . "\n";
    } catch (Throwable $e) {
        echo "  ❌ 次卡查询失败\n";
        echo "    错误: " . $e->getMessage() . "\n";
        echo "    文件: " . $e->getFile() . ":" . $e->getLine() . "\n";
        $errors[] = "get_member_active_passes 失败: " . $e->getMessage();
    }
    echo "\n";
}

// ===== 步骤8: 完整测试 handle_member_find =====
echo "【步骤8】完整测试 handle_member_find...\n";

try {
    $input_data = ['phone' => $test_phone];
    $config = [];

    echo "  调用 handle_member_find(\$pdo, \$config, ['phone' => '$test_phone'])...\n";

    ob_start();
    handle_member_find($pdo, $config, $input_data);
    $output = ob_get_clean();

    echo "  ✓ 函数执行成功\n";
    echo "  返回的JSON:\n";
    $json = json_decode($output, true);
    if ($json) {
        echo "    status: " . ($json['status'] ?? 'N/A') . "\n";
        echo "    message: " . ($json['message'] ?? 'N/A') . "\n";
        if (isset($json['data'])) {
            echo "    data: (存在)\n";
        }
    } else {
        echo "    ⚠️  JSON解析失败\n";
        echo "    原始输出: " . substr($output, 0, 200) . "\n";
    }

} catch (Throwable $e) {
    ob_end_clean();
    echo "  ❌ 函数执行失败\n";
    echo "    类型: " . get_class($e) . "\n";
    echo "    消息: " . $e->getMessage() . "\n";
    echo "    文件: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "\n    堆栈跟踪:\n";
    $trace_lines = explode("\n", $e->getTraceAsString());
    foreach ($trace_lines as $line) {
        echo "      $line\n";
    }
    $errors[] = "handle_member_find 抛出异常: " . $e->getMessage();
}

echo "\n";

// ===== 总结 =====
echo str_repeat("=", 80) . "\n";
echo "【诊断总结】\n\n";

if (!empty($errors)) {
    echo "❌ 发现 " . count($errors) . " 个错误:\n";
    foreach ($errors as $i => $err) {
        echo "  " . ($i + 1) . ". $err\n";
    }
} else {
    echo "✅ 没有发现错误\n";
}

if (!empty($warnings)) {
    echo "\n⚠️  发现 " . count($warnings) . " 个警告:\n";
    foreach ($warnings as $i => $warn) {
        echo "  " . ($i + 1) . ". $warn\n";
    }
}

if (empty($errors)) {
    echo "\n结论: 代码层面没有问题，500错误可能来自:\n";
    echo "  1. 生产环境的数据库配置不同\n";
    echo "  2. PHP版本或扩展问题\n";
    echo "  3. 权限问题\n";
    echo "  4. 需要查看服务器的实际错误日志\n";
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "</pre></body></html>";
