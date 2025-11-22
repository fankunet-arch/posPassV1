<?php
/**
 * Toptea Store POS - Member & Pass Handlers
 * Extracted from pos_registry.php
 *
 * [GEMINI FIX 2025-11-16] (应用修复)
 * 1. 修复 handle_member_create 的数据结构解析
 * 前端 (member.js) 发送: { data: { phone_number: '...' } }
 * 本文件 (v1) 期望: { phone_number: '...' }
 * -> 已修复为优先读取 'data' 键，并回退到扁平结构，以实现最大兼容。
 * 2. 修复 `handle_member_create` 中 INSERT 语句使用 `NOW()` 而不是 `UTC_TIMESTAMP()` 的问题。
 */

/* -------------------------------------------------------------------------- */
/* Handlers: 迁移自 /pos/api/pos_member_handler.php                */
/* -------------------------------------------------------------------------- */
function handle_member_find(PDO $pdo, array $config, array $input_data): void {
    // 1. 读取手机号（兼容 JSON 和 GET）
    $phone = trim($input_data['phone'] ?? $_GET['phone'] ?? '');
    if (empty($phone)) {
        json_error('Phone number is required.', 400);
    }

    // 2. 查询会员
    // [RCA FIX] 这里不要再用 m.deleted_at 了，基准库里没有这个字段 / 或者数据不规范，
    // 改为：
    //   - 用 TRIM(phone_number) 做等值匹配
    //   - 只要 is_active = 1 就视为有效会员
    $stmt = $pdo->prepare("
        SELECT m.*, ml.level_name_zh, ml.level_name_es
        FROM pos_members m
        LEFT JOIN pos_member_levels ml ON m.member_level_id = ml.id
        WHERE TRIM(m.phone_number) = ?
          AND m.is_active = 1
    ");
    $stmt->execute([$phone]);
    $member = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($member) {
        // 3. 附加该会员的有效次卡列表（如果 helper 存在）
        // [FIX 2025-11-19] 增加容错：即使次卡查询失败，也不影响会员基础信息返回
        if (function_exists('get_member_active_passes')) {
            try {
                $member['passes'] = get_member_active_passes($pdo, (int)$member['id']);
            } catch (Throwable $e) {
                // 记录错误但不抛出，避免影响会员查找
                error_log('[MEMBER_FIND] get_member_active_passes failed: ' . $e->getMessage());
                error_log('[MEMBER_FIND] File: ' . $e->getFile() . ':' . $e->getLine());
                $member['passes'] = []; // 降级处理：返回空数组
            }
        } else {
            $member['passes'] = [];
        }

        // 4. 清理可能是无效日期字符串的字段（防止后续版本对日期做处理时踩雷）
        $date_fields_to_clean = ['birthdate', 'created_at', 'updated_at'];
        foreach ($date_fields_to_clean as $field) {
            if (isset($member[$field])) {
                $date_str = (string)$member[$field];
                if ($date_str === '0000-00-00' || $date_str === '0000-00-00 00:00:00' || $date_str === '') {
                    $member[$field] = null;
                }
            }
        }

        json_ok($member, 'Member found.');
    } else {
        json_error('Member not found.', 404);
    }
}


function handle_member_create(PDO $pdo, array $config, array $input_data): void {

    // [GEMINI FIX 2025-11-16] 修复前端 (member.js) 与后端的数据结构不匹配
    // member.js 发送 { data: { phone_number: ... } }
    // 此处优先检查 'data' 键，如果不存在，则回退到根 $input_data
    $data = $input_data['data'] ?? $input_data;

    // [POS-MEMBER-CREATE-001 FIX] 字段归一化：空字符串转换为 NULL
    $phone = trim($data['phone_number'] ?? $data['phone'] ?? '');
    $first_name_raw = trim($data['first_name'] ?? '');
    $last_name_raw = trim($data['last_name'] ?? '');
    $email_raw = trim($data['email'] ?? '');
    $birthdate_raw = trim($data['birthdate'] ?? '');

    if (empty($phone)) json_error('Phone number is required.', 400);

    // 归一化：空字符串转 NULL（符合数据库设计和业务逻辑）
    $first_name = ($first_name_raw === '') ? null : $first_name_raw;
    $last_name = ($last_name_raw === '') ? null : $last_name_raw;
    $email = ($email_raw === '') ? null : $email_raw;
    $birthdate = ($birthdate_raw === '') ? null : $birthdate_raw;

    // 依赖: gen_uuid_v4 (来自 pos_helper.php)
    if (!function_exists('gen_uuid_v4')) json_error('Missing dependency: gen_uuid_v4', 500);
    $member_uuid = gen_uuid_v4();

    try {
        $pdo->beginTransaction();

        $sql = "
            INSERT INTO pos_members (
                member_uuid, 
                first_name, 
                last_name, 
                phone_number, 
                email, 
                birthdate,
                member_level_id, 
                points_balance,
                created_at, 
                updated_at
            ) VALUES (
                :uuid, 
                :first_name, 
                :last_name, 
                :phone, 
                :email, 
                :birthdate,
                1, 
                0,
                UTC_TIMESTAMP(), 
                UTC_TIMESTAMP()
            )
        ";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':uuid' => $member_uuid,
            ':first_name' => $first_name,
            ':last_name' => $last_name,
            ':phone' => $phone,
            ':email' => $email,
            ':birthdate' => $birthdate, // 已在上方归一化处理（空字符串转NULL）
        ]);
        
        $member_id = $pdo->lastInsertId();
        
        $pdo->commit();
        
        // 成功后，按 "find" 接口的格式返回完整数据
        $stmt_find = $pdo->prepare("
            SELECT m.*, ml.level_name_zh, ml.level_name_es
            FROM pos_members m
            LEFT JOIN pos_member_levels ml ON m.member_level_id = ml.id
            WHERE m.id = ?
        ");
        $stmt_find->execute([$member_id]);
        $new_member = $stmt_find->fetch(PDO::FETCH_ASSOC);

        if ($new_member) {
            $new_member['passes'] = []; // 新会员没有次卡
            json_ok($new_member, 'Member created successfully.');
        } else {
            // 正常情况不会发生
            json_error('Failed to retrieve created member.', 500);
        }

    } catch (PDOException $e) {
        $pdo->rollBack();

        // [POS-MEMBER-CREATE-001 FIX] 详细记录数据库错误，便于排查
        $error_code = $e->errorInfo[1] ?? 0;
        $sql_state = $e->errorInfo[0] ?? 'N/A';
        error_log("[MEMBER_CREATE_ERROR] PDOException caught");
        error_log("[MEMBER_CREATE_ERROR] SQLSTATE: {$sql_state}");
        error_log("[MEMBER_CREATE_ERROR] Error Code: {$error_code}");
        error_log("[MEMBER_CREATE_ERROR] Message: " . $e->getMessage());
        error_log("[MEMBER_CREATE_ERROR] Phone: {$phone}");
        error_log("[MEMBER_CREATE_ERROR] Birthdate: " . var_export($birthdate, true));

        // 检查是否为唯一约束冲突 (1062)
        if ($error_code == 1062) {
            // 手机号重复，返回业务错误而不是500
            json_error('Phone number already registered.', 409);
        }

        // 检查是否为外键约束错误 (1452)
        if ($error_code == 1452) {
            error_log("[MEMBER_CREATE_ERROR] Foreign key constraint violation - member_level_id may be invalid");
            json_error('Failed to create member: Invalid member level configuration.', 500);
        }

        // 其他数据库错误
        json_error('Failed to create member: DB Error.', 500);

    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("[MEMBER_CREATE_ERROR] Exception: " . $e->getMessage());
        error_log("[MEMBER_CREATE_ERROR] Trace: " . $e->getTraceAsString());
        json_error('Failed to create member: Server Error.', 500);
    }
}

/* -------------------------------------------------------------------------- */
/* Handlers: B1 次卡售卖 (Pass Purchase)                             */
/* -------------------------------------------------------------------------- */
/**
 * B1: 次卡售卖
 * * 逻辑:
 * 1. (A) 校验权限/班次 (网关已做/Helper已做)
 * 2. (A) 校验输入 (cart_item, member_id)
 * 3. (B) 启动事务
 * 4. (B) [REPO] 检查会员是否存在 (get_member_by_id)
 * 5. (B) [REPO] 检查次卡定义是否存在 (get_pass_plan_by_sku)
 * 6. (A) [HELPER] 检查购买限制 (check_pass_purchase_limits)
 * 7. (B) [HELPER] 分配 VR (VeriFactu) 票号 (allocate_vr_invoice_number)
 * 8. (B) [HELPER] 写入数据库 (topup_orders, member_passes) (create_pass_records)
 * 9. (B) (B3 阶段) 记录支付详情到 topup_orders
 * 10.(B) 提交事务
 * 11.(A) 准备打印数据 (build_pass_vr_receipt)
 * 12.(A) 返回 json_ok
 */
function handle_pass_purchase(PDO $pdo, array $config, array $input_data): void {
    // 依赖:
    //   pos_helper.php (ensure_active_shift_or_fail, gen_uuid_v4)
    //   pos_repo.php (get_member_by_id, get_store_config_full)
    //   pos_repo_ext_pass.php (get_pass_plan_by_sku)
    //   pos_pass_helper.php (check_pass_purchase_limits, allocate_vr_invoice_number, create_pass_records)
    //   pos_json_helper.php (json_ok, json_error)

    // 1. 检查依赖
    $deps = [
        'ensure_active_shift_or_fail', 'gen_uuid_v4',
        'get_member_by_id', 'get_store_config_full',
        'get_pass_plan_by_sku',
        'check_pass_purchase_limits', 'allocate_vr_invoice_number', 'create_pass_records',
        'json_ok', 'json_error'
    ];
    foreach ($deps as $dep) {
        if (!function_exists($dep)) json_error("Missing dependency: $dep", 500);
    }

    // 1. 校验班次
    ensure_active_shift_or_fail($pdo);

    $store_id = (int)$_SESSION['pos_store_id'];
    $user_id = (int)$_SESSION['pos_user_id'];
    $device_id = (int)($_SESSION['pos_device_id'] ?? 0);

    // 2. 校验输入
    $cart_item = $input_data['cart_item'] ?? null;
    $member_id = (int)($input_data['member_id'] ?? 0);
    $secondary_phone_input = trim($input_data['secondary_phone_input'] ?? '');
    $payment_method = strtolower(trim($input_data['payment']['summary'][0]['method'] ?? ''));

    if (!$cart_item || !is_array($cart_item) || !$member_id) {
        json_error('Invalid input: cart_item and member_id are required.', 400);
    }
    if (empty($cart_item['sku'])) {
        json_error('Invalid input: cart_item must have a sku.', 400);
    }

    // ==== 4.1 PRE-PURCHASE VALIDATION ====

    // Validate: Order contains only the pass item, no other products
    // This is critical: pass purchases MUST be isolated from normal product sales

    // Check for regular cart items (from normal cart flow OR from promo_result)
    $cart = $input_data['cart'] ?? [];
    $promo_result = $input_data['promo_result'] ?? null;

    // If promo_result has a cart, use that (it's the calculated cart from frontend)
    if ($promo_result && isset($promo_result['cart']) && is_array($promo_result['cart'])) {
        $cart = $promo_result['cart'];
    }

    // Validate cart is empty - pass purchase must be standalone
    if (!empty($cart) && count($cart) > 0) {
        $lang = $_SESSION['pos_lang'] ?? 'zh';
        if ($lang === 'es') {
            json_error('Para comprar una tarjeta promocional, el pedido no puede contener otros productos. Por favor, finalice o vacíe el pedido actual.', 400);
        } else {
            json_error('购买优惠卡时，订单中不能包含其他商品，请先完成或清空当前订单。', 400);
        }
    }

    // Validate: No discounts/coupons/points applied
    if ($promo_result) {
        $has_discounts = false;
        if (isset($promo_result['coupon_discount']) && $promo_result['coupon_discount'] > 0) {
            $has_discounts = true;
        }
        if (isset($promo_result['points_discount']) && $promo_result['points_discount'] > 0) {
            $has_discounts = true;
        }
        if (isset($promo_result['promo_discount']) && $promo_result['promo_discount'] > 0) {
            $has_discounts = true;
        }
        if (isset($promo_result['discount_amount']) && $promo_result['discount_amount'] > 0) {
            $has_discounts = true;
        }

        if ($has_discounts) {
            $lang = $_SESSION['pos_lang'] ?? 'zh';
            if ($lang === 'es') {
                json_error('No se permiten cupones, descuentos ni puntos al comprar una tarjeta promocional. Por favor, elimine todas las promociones del pedido.', 400);
            } else {
                json_error('购买优惠卡时不允许使用优惠券、折扣或积分，请先取消订单中的所有优惠。', 400);
            }
        }
    }

    try {
        // 3. 启动事务
        $pdo->beginTransaction();

        // 4. 检查会员
        $member = get_member_by_id($pdo, $member_id);
        if (!$member) {
            json_error('Member not found.', 404);
        }

        // ==== 4.2 MEMBER REQUIREMENT AND SECONDARY PHONE VERIFICATION ====

        // Compare secondary_phone_input with member's stored phone
        $member_phone = trim($member['phone_number'] ?? $member['phone'] ?? '');

        // Sanitize both phone numbers for comparison (remove spaces, dashes, etc.)
        $sanitized_input = preg_replace('/[^\d+]/', '', $secondary_phone_input);
        $sanitized_member = preg_replace('/[^\d+]/', '', $member_phone);

        if ($sanitized_input !== $sanitized_member) {
            $pdo->rollBack();
            $lang = $_SESSION['pos_lang'] ?? 'zh';
            if ($lang === 'es') {
                json_error('El número de teléfono introducido en la segunda verificación no coincide con el miembro actualmente conectado. Si desea cambiar de cliente, primero cierre la sesión del miembro actual y vuelva a iniciar sesión con el número correcto antes de realizar la compra.', 400);
            } else {
                json_error('二次输入的手机号与当前登录会员不一致。如需更换会员，请先退出当前会员，再用正确手机号登录后重新购买。', 400);
            }
        }

        // ==== 4.3 PAYMENT METHOD VALIDATION (Cash / Card only) ====

        if ($payment_method !== 'cash' && $payment_method !== 'card') {
            $pdo->rollBack();
            $lang = $_SESSION['pos_lang'] ?? 'zh';
            if ($lang === 'es') {
                json_error('La compra de tarjetas promocionales solo admite efectivo o tarjeta bancaria. Por favor, cambie el método de pago.', 400);
            } else {
                json_error('购买优惠卡仅支持现金或银行卡支付，请更改支付方式。', 400);
            }
        }

        // 5. 检查次卡定义 (依赖: pos_repo_ext_pass.php)
        $plan_details = get_pass_plan_by_sku($pdo, $cart_item['sku']);
        if (!$plan_details) {
            json_error('Pass plan not found for sku: ' . $cart_item['sku'], 404);
        }

        // ==== 5.1 [POS-PASS-PRICE-FIX-MINI] LOCK PRICE TO DB SALE_PRICE ====
        // CRITICAL SECURITY FIX: VR amount MUST come from DB, not frontend
        // Pass sale price is single source of truth from pass_plans.sale_price

        // 5.1a. Extract DB sale price (SSOT)
        $unit_price_from_db = (float)($plan_details['sale_price'] ?? 0);
        if ($unit_price_from_db <= 0) {
            json_error('Invalid configuration: pass sale_price is not configured or is zero.', 500);
        }

        // 5.1b. Extract quantity
        $qty = isset($cart_item['qty']) ? (int)$cart_item['qty'] : 1;
        if ($qty <= 0) {
            json_error('Invalid quantity: must be greater than zero.', 400);
        }

        // 5.1c. Calculate total based on DB price (not frontend)
        $amount_total_from_db = round($unit_price_from_db * $qty, 2);

        // 5.1d. Optional: Detect and log price mismatch (do NOT reject order)
        if (isset($cart_item['price'])) {
            $client_price = (float)$cart_item['price'];
            $price_diff = abs($client_price - $unit_price_from_db);
            if ($price_diff > 0.01) {
                // WARNING: Frontend price differs from DB - potential tampering or bug
                error_log("[PASS_PURCHASE_PRICE_MISMATCH] store_id={$store_id}, " .
                          "member_id={$member_id}, " .
                          "sku={$cart_item['sku']}, " .
                          "frontend_price={$client_price}, " .
                          "db_sale_price={$unit_price_from_db}, " .
                          "diff={$price_diff}");
            }
        }

        // 5.1e. Override cart_item with DB-verified price (CRITICAL)
        // This ensures create_pass_records receives ONLY DB-sourced pricing
        $cart_item['price'] = $unit_price_from_db;
        $cart_item['total'] = $amount_total_from_db;
        $cart_item['qty'] = $qty; // Normalize qty as well

        // ==== END PRICE FIX ====

        // 6. 检查购买限制 (依赖: pos_pass_helper.php)
        // B1 阶段简化: 暂不实现复杂的限制
        // check_pass_purchase_limits($pdo, $member_id, $plan_details);

        // 7. 分配 VR 票号
        // 7a. 获取门店配置 (依赖: pos_repo.php)
        $store_config = get_store_config_full($pdo, $store_id);
        if (empty($store_config['invoice_prefix'])) {
            json_error('Store invoice_prefix (VR Series) is not configured.', 500);
        }
        // 7b. 分配 (依赖: pos_pass_helper.php)
        [$vr_series, $vr_number] = allocate_vr_invoice_number($pdo, $store_config['invoice_prefix']);
        $vr_info = ['series' => $vr_series, 'number' => $vr_number];

        // 8. 写入数据库 (topup_orders, member_passes) (依赖: pos_pass_helper.php)
        $context = [
            'store_id' => $store_id,
            'user_id' => $user_id,
            'device_id' => $device_id,
            'member_id' => $member_id
        ];
        $member_pass_id = create_pass_records($pdo, $context, $vr_info, $cart_item, $plan_details);

        // 9. Record payment details (from input)
        // TODO: Store payment details in topup_orders if needed

        // 10. 提交事务
        $pdo->commit();

        // 11. 准备打印数据 (B1 阶段可选, B2 必须)
        $print_jobs = [
            // [TODO B2] 在此构建 VR 售卡小票
        ];

        // ==== 4.5 RESPONSE AND ACTIONS ====

        // Mask phone for display (show first 3 and last 4 digits)
        $phone_masked = $member_phone;
        if (strlen($member_phone) > 7) {
            $phone_masked = substr($member_phone, 0, 3) . '****' . substr($member_phone, -4);
        }

        json_ok([
            'success' => true,
            'message' => 'PASS_PURCHASE_SUCCESS',
            'actions' => [
                'LOGOUT_MEMBER',
                'CLEAR_ORDER',
                'RESET_TO_HOME',
                'SHOW_PASS_SUCCESS_PAGE'
            ],
            'data' => [
                'pass_id' => $member_pass_id,
                'member_id' => $member_id,
                'phone_masked' => $phone_masked,
                'vr_invoice_number' => $vr_info['series'] . '-' . $vr_info['number']
            ],
            'print_jobs' => $print_jobs
        ], 'Pass purchase successful.');

    } catch (PDOException $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();

        // [FIX 500 ERROR 2025-11-19] 详细记录数据库错误
        error_log('[PASS_PURCHASE] PDOException: ' . $e->getMessage());
        error_log('[PASS_PURCHASE] SQL State: ' . ($e->errorInfo[0] ?? 'N/A'));
        error_log('[PASS_PURCHASE] Error Code: ' . ($e->errorInfo[1] ?? 'N/A'));
        error_log('[PASS_PURCHASE] Member ID: ' . $member_id);
        error_log('[PASS_PURCHASE] SKU: ' . ($cart_item['sku'] ?? 'N/A'));
        error_log('[PASS_PURCHASE] Trace: ' . $e->getTraceAsString());

        // 区分不同的数据库错误类型，给出更友好的提示
        $error_code = $e->errorInfo[1] ?? 0;
        $lang = $_SESSION['pos_lang'] ?? 'zh';

        // 1062 = Duplicate entry (已通过叠加购买逻辑处理，理论上不应再出现)
        if ($error_code == 1062) {
            error_log('[PASS_PURCHASE] UNEXPECTED: Duplicate key error should be handled by stacked purchase logic!');
            if ($lang === 'es') {
                json_error('Error inesperado: conflicto de restricción única. Contacte con el administrador.', 500);
            } else {
                json_error('系统错误：唯一约束冲突（叠加购买逻辑异常），请联系管理员。', 500);
            }
        }

        // 1452 = Foreign key constraint (会员或次卡定义不存在)
        if ($error_code == 1452) {
            error_log('[PASS_PURCHASE] Foreign key constraint violation - member or plan may have been deleted mid-transaction');
            if ($lang === 'es') {
                json_error('Error de datos: miembro o plan de tarjeta no válido.', 400);
            } else {
                json_error('数据错误：会员或次卡方案无效。', 400);
            }
        }

        // 其他数据库错误
        if ($lang === 'es') {
            json_error('Error de base de datos al procesar la compra. Por favor, inténtelo de nuevo o contacte con soporte.', 500);
        } else {
            json_error('购卡处理时发生数据库错误，请重试或联系技术支持。', 500);
        }

    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();

        // [FIX 500 ERROR 2025-11-19] 捕获所有其他异常（包括 Error 和业务逻辑异常）
        error_log('[PASS_PURCHASE] Exception: ' . get_class($e) . ': ' . $e->getMessage());
        error_log('[PASS_PURCHASE] Code: ' . $e->getCode());
        error_log('[PASS_PURCHASE] File: ' . $e->getFile() . ':' . $e->getLine());
        error_log('[PASS_PURCHASE] Member ID: ' . ($member_id ?? 'N/A'));
        error_log('[PASS_PURCHASE] SKU: ' . ($cart_item['sku'] ?? 'N/A'));
        error_log('[PASS_PURCHASE] Trace: ' . $e->getTraceAsString());

        // 根据异常类型区分业务错误(400)和系统错误(500)
        $error_code = 500;
        $error_msg = $e->getMessage();

        // 如果异常消息中包含业务规则关键词，归类为业务错误
        $business_keywords = ['not found', 'invalid', 'required', 'already exists', 'limit exceeded', 'not allowed'];
        foreach ($business_keywords as $keyword) {
            if (stripos($error_msg, $keyword) !== false) {
                $error_code = 400;
                break;
            }
        }

        $lang = $_SESSION['pos_lang'] ?? 'zh';
        if ($error_code == 400) {
            // 业务错误：直接返回异常消息
            json_error($error_msg, 400);
        } else {
            // 系统错误：返回通用提示，不暴露内部细节
            if ($lang === 'es') {
                json_error('Error del sistema al procesar la compra. Por favor, contacte con soporte.', 500);
            } else {
                json_error('购卡处理时发生系统错误，请联系技术支持。', 500);
            }
        }
    }
}

/* -------------------------------------------------------------------------- */
/* Handlers: 优惠卡列表 (Discount Card List)                             */
/* -------------------------------------------------------------------------- */
/**
 * 获取可售优惠卡列表
 */
function handle_pass_list(PDO $pdo, array $config, array $input_data): void {
    try {
        $sql = "
            SELECT
                pass_plan_id AS plan_id,
                name,
                name_zh,
                name_es,
                total_uses,
                validity_days,
                max_uses_per_order,
                max_uses_per_day,
                sale_sku,
                sale_price,
                notes
            FROM pass_plans
            WHERE is_active = 1
            ORDER BY sale_price ASC
        ";

        $stmt = $pdo->prepare($sql);
        $stmt->execute();
        $cards = $stmt->fetchAll(PDO::FETCH_ASSOC);

        json_ok($cards, 'Pass plans retrieved successfully.');

    } catch (PDOException $e) {
        json_error('Database error: ' . $e->getMessage(), 500);
    }
}