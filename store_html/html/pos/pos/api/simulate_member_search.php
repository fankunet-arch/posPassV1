<?php
/**
 * 模拟真实的会员查找请求
 * 这个脚本会完全模拟前端发送的请求，帮助定位500错误的真正原因
 *
 * 访问：https://storev3.toptea.es/pos/api/simulate_member_search.php?phone=YOUR_PHONE
 */

// 启用所有错误显示
error_reporting(E_ALL);
ini_set('display_errors', '1');

// 设置内容类型
header('Content-Type: text/html; charset=utf-8');

echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>模拟会员查找</title></head><body>";
echo "<h1>模拟会员查找 - 完整流程测试</h1>";
echo "<style>
body { font-family: monospace; padding: 20px; }
.step { margin: 20px 0; padding: 15px; border: 1px solid #ddd; background: #f9f9f9; }
.success { color: green; }
.error { color: red; }
.warning { color: orange; }
pre { background: #fff; padding: 10px; border: 1px solid #ccc; overflow-x: auto; }
</style>";

$test_phone = $_GET['phone'] ?? '123456';

echo "<div class='step'>";
echo "<h2>📝 测试参数</h2>";
echo "<p>手机号: <strong>$test_phone</strong></p>";
echo "<p>时间: " . date('Y-m-d H:i:s') . "</p>";
echo "</div>";

// ===== 步骤1: 模拟session =====
echo "<div class='step'>";
echo "<h2>🔐 步骤1: Session 设置</h2>";

@session_start();
if (!isset($_SESSION['pos_user_id'])) {
    echo "<p class='warning'>⚠️  Session未设置，创建测试session</p>";
    $_SESSION['pos_user_id'] = 1;
    $_SESSION['pos_store_id'] = 1;
    $_SESSION['pos_device_id'] = 1;
    $_SESSION['pos_lang'] = 'zh';
} else {
    echo "<p class='success'>✓ Session已存在</p>";
}

echo "<pre>";
echo "pos_user_id: " . ($_SESSION['pos_user_id'] ?? 'N/A') . "\n";
echo "pos_store_id: " . ($_SESSION['pos_store_id'] ?? 'N/A') . "\n";
echo "pos_lang: " . ($_SESSION['pos_lang'] ?? 'N/A');
echo "</pre>";
echo "</div>";

// ===== 步骤2: 加载核心文件 =====
echo "<div class='step'>";
echo "<h2>📦 步骤2: 加载核心文件</h2>";

try {
    require_once realpath(__DIR__ . '/../../../pos_backend/core/config.php');
    echo "<p class='success'>✓ config.php</p>";

    require_once realpath(__DIR__ . '/../../../pos_backend/helpers/pos_json_helper.php');
    echo "<p class='success'>✓ pos_json_helper.php</p>";

    require_once realpath(__DIR__ . '/../../../pos_backend/core/pos_api_core.php');
    echo "<p class='success'>✓ pos_api_core.php</p>";

    // 加载注册表
    $registry_main = require __DIR__ . '/registries/pos_registry.php';
    echo "<p class='success'>✓ pos_registry.php</p>";

    echo "<p>已注册资源: " . implode(', ', array_keys($registry_main)) . "</p>";

} catch (Throwable $e) {
    echo "<p class='error'>❌ 加载失败: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
    echo "</div></body></html>";
    exit(1);
}

echo "</div>";

// ===== 步骤3: 检查member资源配置 =====
echo "<div class='step'>";
echo "<h2>🔍 步骤3: 检查 member 资源配置</h2>";

if (!isset($registry_main['member'])) {
    echo "<p class='error'>❌ member 资源未注册！</p>";
    echo "</div></body></html>";
    exit(1);
}

$config = $registry_main['member'];
echo "<p class='success'>✓ member 资源已注册</p>";
echo "<pre>";
echo "auth_role: " . ($config['auth_role'] ?? 'N/A') . "\n";
echo "custom_actions:\n";
foreach ($config['custom_actions'] as $action => $handler) {
    $exists = function_exists($handler);
    echo "  $action => $handler ... " . ($exists ? "✓" : "❌ 函数不存在") . "\n";
}
echo "</pre>";

$handler_name = $config['custom_actions']['find'] ?? null;
if (!$handler_name) {
    echo "<p class='error'>❌ find action 未定义！</p>";
    echo "</div></body></html>";
    exit(1);
}

if (!function_exists($handler_name)) {
    echo "<p class='error'>❌ handler 函数 $handler_name 不存在！</p>";
    echo "</div></body></html>";
    exit(1);
}

echo "<p class='success'>✓ handler 函数 $handler_name 存在</p>";
echo "</div>";

// ===== 步骤4: 模拟请求数据 =====
echo "<div class='step'>";
echo "<h2>📨 步骤4: 构造请求数据</h2>";

// 模拟前端发送的JSON POST数据
$input_data = ['phone' => $test_phone];
echo "<p>模拟的 input_data:</p>";
echo "<pre>" . json_encode($input_data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "</pre>";
echo "</div>";

// ===== 步骤5: 执行handler =====
echo "<div class='step'>";
echo "<h2>⚙️  步骤5: 执行 handler</h2>";
echo "<p>调用: <code>$handler_name(\$pdo, \$config, \$input_data)</code></p>";

// 捕获所有输出和异常
ob_start();
$exception_caught = null;

try {
    call_user_func($handler_name, $pdo, $config, $input_data);
    $output = ob_get_clean();
    $success = true;
} catch (Throwable $e) {
    $output = ob_get_clean();
    $exception_caught = $e;
    $success = false;
}

if ($success) {
    echo "<p class='success'>✓ Handler 执行成功（未抛出异常）</p>";
    echo "<h3>返回的内容：</h3>";
    echo "<pre>" . htmlspecialchars($output) . "</pre>";

    // 尝试解析JSON
    $json = json_decode($output, true);
    if ($json) {
        echo "<h3>解析后的JSON：</h3>";
        echo "<pre>" . json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "</pre>";

        if ($json['status'] === 'success') {
            echo "<p class='success'>✅ 查询成功！会员已找到</p>";
        } elseif ($json['status'] === 'error' && $json['message'] === 'Member not found.') {
            echo "<p class='warning'>ℹ️  未找到会员（这是正常的业务逻辑）</p>";
        } else {
            echo "<p class='warning'>⚠️  其他响应：" . htmlspecialchars($json['message']) . "</p>";
        }
    } else {
        echo "<p class='error'>❌ 无法解析JSON：" . json_last_error_msg() . "</p>";
    }

} else {
    echo "<p class='error'>❌ Handler 抛出异常！</p>";
    echo "<h3>异常详情：</h3>";
    echo "<pre>";
    echo "类型: " . get_class($exception_caught) . "\n";
    echo "消息: " . htmlspecialchars($exception_caught->getMessage()) . "\n";
    echo "文件: " . $exception_caught->getFile() . "\n";
    echo "行号: " . $exception_caught->getLine() . "\n";
    echo "</pre>";

    // 如果是数据库异常，显示SQL信息
    if ($exception_caught instanceof PDOException) {
        echo "<h3>数据库错误详情：</h3>";
        echo "<pre>";
        echo "SQL State: " . ($exception_caught->errorInfo[0] ?? 'N/A') . "\n";
        echo "Driver Error Code: " . ($exception_caught->errorInfo[1] ?? 'N/A') . "\n";
        echo "Driver Error Message: " . ($exception_caught->errorInfo[2] ?? 'N/A') . "\n";
        echo "</pre>";
    }

    echo "<h3>堆栈跟踪：</h3>";
    echo "<pre>" . htmlspecialchars($exception_caught->getTraceAsString()) . "</pre>";

    echo "<h3>🔍 分析建议：</h3>";
    echo "<ul>";

    $msg = $exception_caught->getMessage();
    if (strpos($msg, "Table") !== false && strpos($msg, "doesn't exist") !== false) {
        echo "<li>错误原因：数据库表不存在</li>";
        echo "<li>解决方案：需要创建缺失的数据库表</li>";
    } elseif (strpos($msg, "Unknown column") !== false) {
        echo "<li>错误原因：数据库字段不存在或拼写错误</li>";
        echo "<li>解决方案：检查数据库表结构，确保字段名匹配</li>";
    } elseif (strpos($msg, "Call to undefined function") !== false) {
        echo "<li>错误原因：调用了不存在的函数</li>";
        echo "<li>解决方案：检查是否缺少 require 语句</li>";
    } else {
        echo "<li>错误原因：其他问题（见上方异常详情）</li>";
    }

    echo "</ul>";
}

echo "</div>";

// ===== 总结 =====
echo "<div class='step'>";
echo "<h2>📊 测试总结</h2>";

if ($success) {
    echo "<p class='success' style='font-size: 18px;'>✅ 测试通过！会员查找功能正常工作</p>";
    echo "<p>如果实际环境仍然报500错误，可能原因：</p>";
    echo "<ul>";
    echo "<li>Session 问题：实际请求未登录或session失效</li>";
    echo "<li>权限问题：实际请求的用户没有访问权限</li>";
    echo "<li>数据不同：实际数据库中的数据导致其他问题</li>";
    echo "<li>PHP配置不同：生产环境的PHP版本或配置不同</li>";
    echo "</ul>";
} else {
    echo "<p class='error' style='font-size: 18px;'>❌ 测试失败！这就是导致500错误的原因</p>";
    echo "<p><strong>请参考上方的异常详情和分析建议进行修复</strong></p>";
}

echo "</div>";

echo "</body></html>";
