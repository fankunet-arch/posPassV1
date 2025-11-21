# L4-2B-POS-EOD-MINI 测试与验证指南

## 阶段信息

- **阶段代号**: L4-2B-POS-EOD-MINI
- **范围**: POS 班次（Shift） / 日结（EOD） / 班次汇总相关逻辑
- **性质**: 实现阶段（修复已知问题）
- **相关Issue**: ISSUE-POS-DB-001, ISSUE-POS-EOD-001

## 修复内容摘要

### 任务1：清理幽灵函数 `calculate_eod_totals()`
- **文件**: `store_html/pos_backend/helpers/pos_helper.php`
- **操作**: 删除已废弃的 `calculate_eod_totals()` 函数
- **原因**: 该函数引用不存在的 `pos_invoice_payments` 表，已通过熔断机制规避运行时风险
- **影响**: 减少代码噪音，避免误导后续维护者

### 任务2：补全正常关班的 pos_shifts 字段写入
- **文件**: `store_html/html/pos/api/registries/pos_registry_ops_shift.php`
- **操作**:
  - 修改 `handle_shift_end()`（正常关班）
  - 修改 `handle_shift_force_start()`（强制关班）
- **改动**:
  - 正常关班现在写入 `expected_cash`, `cash_variance`, `payment_summary` 到 `pos_shifts`
  - 强制关班的 `payment_summary` 现在包含真实的支付分解（而不仅是note）
- **数据来源**:
  - 调用 `getInvoiceSummaryForPeriod()` 获取支付方式分解
  - 从 `compute_expected_cash()` 获取理论现金
- **目标**: 让正常班次与强制班次的 `pos_shifts` 字段完整度一致

### 任务3：脏数据检查脚本
- **文件**: `store_html/pos_backend/tools/check_shift_cash_completeness.php`
- **功能**: 只读检查历史数据中财务字段为空的班次
- **用途**: 为后续数据回填提供评估依据

---

## 测试环境准备

### 前置条件

1. **数据库连接**: 确保测试环境能连接到 POS 数据库
2. **用户权限**: 需要一个有权限操作班次和销售的测试账户
3. **测试门店**: 选择一个测试门店（建议使用非生产数据）
4. **测试商品**: 至少准备2-3个测试商品，价格不同

### 测试数据准备建议

- 准备至少 50€ 的测试现金（用于模拟不同支付方式）
- 确保测试账户有开班/关班权限
- 准备至少3种支付方式测试：现金、银行卡、平台支付（如有）

---

## 测试场景

### 场景1：正常关班字段完整性验证

#### 目标
验证正常关班后，`pos_shifts` 表中对应记录包含完整的财务字段。

#### 测试步骤

1. **开班**
   ```
   - 登录 POS 系统
   - 进入班次管理
   - 点击"开班"，输入起始备用金：100.00€
   - 记录返回的 shift_id（例如：shift_id = 123）
   ```

2. **进行销售**
   ```
   - 添加商品A（价格：5.00€）× 2 = 10.00€
   - 支付方式：现金 10.00€
   - 完成销售1

   - 添加商品B（价格：8.50€）× 1 = 8.50€
   - 支付方式：银行卡 8.50€
   - 完成销售2

   - 添加商品A（价格：5.00€）× 1 = 5.00€
   - 添加商品B（价格：8.50€）× 1 = 8.50€
   - 小计：13.50€
   - 支付方式：现金 13.50€
   - 完成销售3
   ```

   **预期现金收入**: 10.00€ + 13.50€ = 23.50€
   **预期银行卡收入**: 8.50€
   **理论现金**: 100.00€ (起始备用金) + 23.50€ (现金销售) = 123.50€

3. **正常关班**
   ```
   - 进入班次管理
   - 点击"关班"
   - 输入清点现金：123.50€（假设点钱准确）
   - 提交关班
   ```

4. **数据验证**

   执行以下 SQL 查询：
   ```sql
   SELECT
       id,
       status,
       starting_float,
       counted_cash,
       expected_cash,
       cash_variance,
       payment_summary
   FROM pos_shifts
   WHERE id = 123;  -- 替换为实际的 shift_id
   ```

   **预期结果**:
   ```
   id: 123
   status: 'ENDED'
   starting_float: 100.00
   counted_cash: 123.50
   expected_cash: 123.50 (或接近值，根据实际销售)
   cash_variance: 0.00 (或接近0，counted_cash - expected_cash)
   payment_summary: {"Cash":23.5,"Card":8.5,"Platform":0}  (JSON格式)
   ```

   **验证点**:
   - ✅ `status` = 'ENDED'
   - ✅ `counted_cash` 有值且等于输入的清点现金
   - ✅ `expected_cash` 不为 NULL，且数值合理
   - ✅ `cash_variance` 不为 NULL，且等于 counted_cash - expected_cash
   - ✅ `payment_summary` 不为 NULL，是合法JSON，包含各支付方式金额

5. **验证 pos_eod_records**

   ```sql
   SELECT
       shift_id,
       expected_cash,
       counted_cash,
       cash_diff
   FROM pos_eod_records
   WHERE shift_id = 123;  -- 替换为实际的 shift_id
   ```

   **预期结果**:
   - ✅ 有对应记录
   - ✅ `expected_cash` 与 `pos_shifts` 中的值一致
   - ✅ `counted_cash` 与 `pos_shifts` 中的值一致
   - ✅ `cash_diff` 与 `pos_shifts.cash_variance` 一致

---

### 场景2：现金差异场景测试

#### 目标
验证当清点现金与理论现金不一致时，`cash_variance` 字段正确计算。

#### 测试步骤

1. **开班** (同场景1步骤1)
   - 起始备用金：100.00€
   - 记录 shift_id

2. **进行销售** (简化版)
   ```
   - 销售1：商品5.00€，现金支付
   - 销售2：商品10.00€，现金支付
   ```
   **理论现金**: 100.00€ + 5.00€ + 10.00€ = 115.00€

3. **关班（模拟短款）**
   ```
   - 输入清点现金：113.00€ (少了2€)
   - 提交关班
   ```

4. **数据验证**
   ```sql
   SELECT
       expected_cash,
       counted_cash,
       cash_variance
   FROM pos_shifts
   WHERE id = <shift_id>;
   ```

   **预期结果**:
   ```
   expected_cash: 115.00
   counted_cash: 113.00
   cash_variance: -2.00  (113.00 - 115.00)
   ```

---

### 场景3：强制关班回归测试

#### 目标
验证强制关班功能未被破坏，且 `payment_summary` 包含真实支付分解。

#### 测试步骤

1. **创建幽灵班次**
   - 开班但不关班
   - 进行1-2笔销售（含不同支付方式）
   - 退出系统（不关班）

2. **模拟第二天开班**
   - 修改系统时间到第二天（或等待EOD cutoff时间）
   - 以另一个用户尝试开班
   - 系统应检测到幽灵班次

3. **强制关班**
   - 系统提示有未关闭班次
   - 点击"强制开班"（会关闭旧班次并开新班次）

4. **数据验证**
   ```sql
   SELECT
       id,
       status,
       expected_cash,
       cash_variance,
       payment_summary
   FROM pos_shifts
   WHERE status = 'FORCE_CLOSED'
   ORDER BY id DESC
   LIMIT 1;
   ```

   **预期结果**:
   ```
   status: 'FORCE_CLOSED'
   expected_cash: <理论现金值，不为NULL>
   cash_variance: <负值，因为counted_cash=0>
   payment_summary: {
       "Cash": <金额>,
       "Card": <金额>,
       "Platform": <金额>,
       "_force_closed_by": "管理员名称",
       "_force_closed_note": "Shift was forcibly closed due to EOD cutoff"
   }
   ```

   **验证点**:
   - ✅ `status` = 'FORCE_CLOSED'
   - ✅ `expected_cash` 不为 NULL
   - ✅ `cash_variance` 不为 NULL（应为负值）
   - ✅ `payment_summary` 包含真实支付分解（不只是note）
   - ✅ `payment_summary` 包含 `_force_closed_by` 和 `_force_closed_note` 字段

---

### 场景4：EOD 提交流程回归测试

#### 目标
验证日结提交流程未受影响。

#### 测试步骤

1. **完成一个或多个班次**
   - 开班 → 销售 → 关班（正常流程）
   - 重复1-2次

2. **执行日结提交**
   ```
   - 进入 EOD（日结）页面
   - 查看当日销售汇总
   - 点击"提交日结"
   ```

3. **数据验证**
   ```sql
   SELECT
       id,
       store_id,
       report_date,
       total_sales,
       total_cash,
       total_card,
       total_platform
   FROM pos_eod_reports
   WHERE report_date = CURDATE()  -- 或指定日期
   ORDER BY id DESC
   LIMIT 1;
   ```

   **预期结果**:
   - ✅ 有对应记录
   - ✅ `total_sales` 等于所有班次销售总额
   - ✅ `total_cash` / `total_card` / `total_platform` 与 `pos_invoices` 聚合结果一致

4. **交叉验证**
   ```sql
   -- 从 pos_invoices 聚合当日销售
   SELECT
       SUM(final_total) AS invoice_total_sales
   FROM pos_invoices
   WHERE store_id = <store_id>
     AND issued_at BETWEEN '<日开始时间>' AND '<日结束时间>'
     AND status = 'ISSUED';
   ```

   比对 `invoice_total_sales` 与 `pos_eod_reports.total_sales` 是否一致。

---

### 场景5：幽灵函数删除验证

#### 目标
确认 `calculate_eod_totals()` 已被删除且不影响系统运行。

#### 测试步骤

1. **全局搜索**
   ```bash
   cd /home/user/posPassV1
   grep -r "calculate_eod_totals" --include="*.php" store_html/
   ```

   **预期结果**:
   - 不应在任何 PHP 代码中找到该函数的调用
   - 只在文档中有提及（如果有的话）

2. **语法检查**
   ```bash
   php -l store_html/pos_backend/helpers/pos_helper.php
   ```

   **预期结果**: `No syntax errors detected`

3. **功能回归**
   - 执行场景1-4的任意一个完整流程
   - 确认所有功能正常工作，没有500错误

---

### 场景6：脏数据检查脚本测试

#### 目标
验证脏数据检查脚本能正确识别历史不完整数据。

#### 测试步骤

1. **运行脚本**
   ```bash
   cd /home/user/posPassV1/store_html/pos_backend/tools
   php check_shift_cash_completeness.php
   ```

2. **预期输出**

   如果历史数据中有不完整班次：
   ```
   =================================================================
   POS 班次数据完整性检查工具
   L4-2B-POS-EOD-MINI / ISSUE-POS-EOD-001
   =================================================================

   [WARNING] 发现 X 个已结束但财务字段不完整的班次。

   shift_id   store_id   start_time           end_time             counted_cash    expected_cash   cash_variance   miss_exp   miss_var   miss_pay
   --------------------------------------------------------------------------------------
   <数据行...>

   [INFO] 共 X 条不完整记录。
   ...
   ```

   如果所有数据完整：
   ```
   [SUCCESS] 所有已结束的班次 (status='ENDED') 都已包含完整的财务字段。
             没有需要修复的历史数据。
   ```

3. **验证点**
   - ✅ 脚本能成功运行
   - ✅ 输出格式清晰易读
   - ✅ 识别出的不完整记录确实缺少相关字段
   - ✅ 脚本不修改任何数据（只读模式）

---

## 关键验证 SQL 汇总

### 验证正常关班字段完整性
```sql
-- 查看最近的正常关班记录
SELECT
    id AS shift_id,
    status,
    start_time,
    end_time,
    starting_float,
    counted_cash,
    expected_cash,
    cash_variance,
    payment_summary
FROM pos_shifts
WHERE status = 'ENDED'
ORDER BY end_time DESC
LIMIT 10;

-- 验证 payment_summary 格式
SELECT
    id,
    payment_summary,
    JSON_VALID(payment_summary) AS is_valid_json,
    JSON_EXTRACT(payment_summary, '$.Cash') AS cash_amount,
    JSON_EXTRACT(payment_summary, '$.Card') AS card_amount,
    JSON_EXTRACT(payment_summary, '$.Platform') AS platform_amount
FROM pos_shifts
WHERE status = 'ENDED'
  AND end_time > NOW() - INTERVAL 1 DAY
ORDER BY id DESC
LIMIT 5;
```

### 验证强制关班字段完整性
```sql
SELECT
    id AS shift_id,
    status,
    expected_cash,
    cash_variance,
    payment_summary
FROM pos_shifts
WHERE status = 'FORCE_CLOSED'
ORDER BY end_time DESC
LIMIT 5;
```

### 比对 pos_shifts 与 pos_eod_records
```sql
SELECT
    s.id AS shift_id,
    s.expected_cash AS shift_expected,
    s.counted_cash AS shift_counted,
    s.cash_variance AS shift_variance,
    e.expected_cash AS eod_expected,
    e.counted_cash AS eod_counted,
    e.cash_diff AS eod_diff,
    (s.expected_cash = e.expected_cash) AS expected_match,
    (s.counted_cash = e.counted_cash) AS counted_match,
    (s.cash_variance = e.cash_diff) AS variance_match
FROM pos_shifts s
JOIN pos_eod_records e ON s.id = e.shift_id
WHERE s.status IN ('ENDED', 'FORCE_CLOSED')
  AND s.end_time > NOW() - INTERVAL 1 DAY
ORDER BY s.id DESC
LIMIT 10;
```

---

## 测试检查清单

### 功能测试
- [ ] 正常开班 → 销售 → 正常关班流程完整
- [ ] pos_shifts 写入 expected_cash / cash_variance / payment_summary
- [ ] payment_summary 为合法 JSON，包含 Cash/Card/Platform
- [ ] 现金差异（短款/长款）计算正确
- [ ] pos_eod_records 数据与 pos_shifts 一致
- [ ] 强制关班流程正常工作
- [ ] 强制关班的 payment_summary 包含真实支付分解
- [ ] 日结提交流程正常
- [ ] EOD 汇总金额与 pos_invoices 一致

### 代码质量测试
- [ ] 幽灵函数 calculate_eod_totals() 已删除
- [ ] 全局搜索无残留调用
- [ ] PHP 语法检查通过
- [ ] 无 500 / 致命错误

### 数据完整性测试
- [ ] 脏数据检查脚本运行成功
- [ ] 新关班记录字段完整
- [ ] 历史数据不受影响（只读检查）

---

## 测试通过标准

所有以下条件必须满足：

1. **功能完整性**: 所有测试场景（1-6）通过
2. **数据一致性**: pos_shifts / pos_eod_records / pos_eod_reports 数据对齐
3. **代码清洁度**: 无幽灵代码残留，语法检查通过
4. **向后兼容**: 历史流程（EOD 提交、强制关班）未受影响
5. **文档完整**: 所有修改都有注释说明 `[L4-2B-POS-EOD-MINI]`

---

## 回滚方案

如果测试中发现严重问题，可以回滚到修改前状态：

```bash
cd /home/user/posPassV1
git checkout HEAD~1 -- store_html/pos_backend/helpers/pos_helper.php
git checkout HEAD~1 -- store_html/html/pos/api/registries/pos_registry_ops_shift.php
```

注意：回滚后，历史不完整数据问题会继续存在。

---

## 常见问题排查

### Q1: 关班后 payment_summary 为空或格式错误
**可能原因**:
- `getInvoiceSummaryForPeriod()` 未正确返回 payments
- JSON 编码失败

**排查方法**:
```php
// 在 handle_shift_end 中添加调试日志
error_log("Invoice Summary: " . print_r($invoice_summary, true));
error_log("Payment Breakdown: " . print_r($payment_breakdown, true));
```

### Q2: cash_variance 计算不正确
**可能原因**:
- `compute_expected_cash()` 返回值错误
- 浮点数精度问题

**排查方法**:
```sql
-- 手动计算理论现金
SELECT
    s.starting_float,
    COALESCE(SUM(CASE WHEN JSON_EXTRACT(i.payment_summary, '$.summary.cash') IS NOT NULL
                      THEN JSON_EXTRACT(i.payment_summary, '$.summary.cash')
                      ELSE 0 END), 0) AS cash_sales
FROM pos_shifts s
LEFT JOIN pos_invoices i ON i.store_id = s.store_id
    AND i.issued_at BETWEEN s.start_time AND s.end_time
WHERE s.id = <shift_id>
GROUP BY s.id;
```

### Q3: 强制关班后 payment_summary 没有附加字段
**检查点**:
- 确认代码中有 `$payment_breakdown['_force_closed_by']` 赋值
- 确认 JSON 编码前的数组结构

---

## 联系与反馈

如遇测试问题或发现新的边界情况，请记录以下信息：
- 测试场景编号
- 预期结果 vs 实际结果
- 相关 shift_id 或数据库记录
- 错误日志（如有）

---

**文档版本**: v1.0
**创建日期**: 2025-11-21
**适用阶段**: L4-2B-POS-EOD-MINI
**维护者**: Claude (AI Engineer)
