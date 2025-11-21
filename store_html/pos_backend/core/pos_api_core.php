<?php
/**
 * Toptea POS - 通用 API 核心引擎
 * 职责: 提供 run_api() 驱动基于注册表的 CRUD/自定义动作。
 * Version: 1.0.1
 * Date: 2025-11-09
 */

require_once realpath(__DIR__ . '/../helpers/pos_json_helper.php');
require_once realpath(__DIR__ . '/../helpers/pos_datetime_helper.php');
require_once realpath(__DIR__ . '/../services/PromotionEngine.php');

if (!defined('ROLE_STORE_USER'))    define('ROLE_STORE_USER', 'staff');
if (!defined('ROLE_STORE_MANAGER')) define('ROLE_STORE_MANAGER', 'manager');
if (!defined('ROLE_SUPER_ADMIN'))   define('ROLE_SUPER_ADMIN', 9);

/**
 * 运行注册表 API
 * @param array $registry ['resource' => ['auth_role'=>..., 'custom_actions'=>['act' => handlerName]]]
 * @param PDO   $pdo
 */
function run_api(array $registry, PDO $pdo): void {
    @session_start();

    $resource_name = $_GET['res'] ?? null;
    $action_name   = $_GET['act'] ?? null;

    if (!$resource_name || !$action_name) {
        json_error('无效的 API 请求：缺少 res 或 act 参数。', 400);
    }

    $config = $registry[$resource_name] ?? null;
    if ($config === null) {
        json_error("资源 '{$resource_name}' 未注册。", 404);
    }

    // 权限校验（门店侧只校验是否登录）
    $required_role = $config['auth_role'] ?? ROLE_STORE_USER;
    $logged_in     = isset($_SESSION['pos_user_id']);
    if (!$logged_in) json_error('未登录或会话失效。', 401);

    // 找处理器
    $handler_name = $config['custom_actions'][$action_name] ?? null;
    if (!$handler_name || !function_exists($handler_name)) {
        json_error("动作 '{$action_name}' 未定义。", 404);
    }

    // 解析请求体
    $input_data = get_request_data();

    // 执行
    try {
        call_user_func($handler_name, $pdo, $config, $input_data);
    } catch (Throwable $e) {
        // [FIX 2025-11-19] 增强错误日志，记录详细信息
        $error_details = [
            'type' => get_class($e),
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'resource' => $resource_name,
            'action' => $action_name,
            'trace' => $e->getTraceAsString()
        ];

        // 记录到错误日志
        error_log('[POS API ERROR] ' . json_encode($error_details, JSON_UNESCAPED_UNICODE));

        // 如果是数据库错误，尝试提取更多信息
        if ($e instanceof PDOException) {
            error_log('[POS API PDO] SQL State: ' . ($e->errorInfo[0] ?? 'N/A'));
            error_log('[POS API PDO] Driver Code: ' . ($e->errorInfo[1] ?? 'N/A'));
            error_log('[POS API PDO] Driver Msg: ' . ($e->errorInfo[2] ?? 'N/A'));
        }

        // 返回给客户端（开发环境可以返回详细错误，生产环境只返回简化消息）
        $is_dev = ($_SERVER['SERVER_NAME'] ?? '') === 'localhost' || strpos($_SERVER['SERVER_NAME'] ?? '', '127.0.0.1') !== false;
        if ($is_dev) {
            json_error('服务器内部错误: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine(), 500);
        } else {
            json_error('服务器内部错误，请稍后重试。', 500);
        }
    }
}
