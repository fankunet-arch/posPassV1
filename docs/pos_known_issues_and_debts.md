# POS 已知问题与技术债清单（TopTea 次卡相关）

说明：
- 本文仅记录 POS 线中的已知问题与技术债，方便后续阶段性集中处理。
- 每条问题包含：编号、类型、模块、描述、影响、临时措施、计划修复阶段与当前状态。
- 编号规则：`ISSUE-POS-<类别>-<序号>`，以及少量架构备注 `ARCH-POS-...`。

---

## 1. 打印相关问题

### ISSUE-POS-PRINT-001：打印模板中商品字段命名不统一

- 类型：一致性问题 / 潜在显示错误  
- 模块：POS · 打印（小票 / 杯贴）  
- 描述：  
  - 杯贴（Cup Sticker）模板中使用占位符 `{item_name}` 表示商品名称；  
  - 次卡核销小票（`PASS_REDEMPTION_SLIP`）模板中使用 `{title}` / `{variant_name}` / `{qty}`；  
  - 不同模板中对“商品名称”的字段命名不统一，未来新增模板时容易误抄 `{item_name}`，导致渲染结果为空。  
- 影响：  
  - 当前版本中，`PASS_REDEMPTION_SLIP` 模板已确认使用 `{title}` 等字段，短期内不会影响生产；  
  - 但模板设计缺乏统一规范，新模板或后续修改存在踩坑风险。  
- 临时措施：  
  - 本次次卡核销小票模板中，仅使用 `{title}`, `{variant_name}`, `{qty}` 不使用 `{item_name}`；  
  - 在设计打印模板时，优先参考新线模板字段命名，不再沿用旧的 `{item_name}` 写法。  
- 计划修复阶段：  
  - 建议在后续“打印系统规范化阶段”（例如 P4.x 或专门的 PRINT 规范任务）统一：  
    - 定义所有打印任务通用的字段命名规范；  
    - 对现有模板字段进行一次体检（必要时重构）。  
- 当前状态：记录中（未统一规范，仅局部规避）。

---

## 2. 数据库 / 日结（EOD）相关问题

### ISSUE-POS-DB-001：旧版 EOD 统计函数引用不存在的 `pos_invoice_payments` 表（已熔断，待清理）

- 类型：技术债 / 幽灵表引用（代码层面）  
- 模块：POS · 后端 EOD（日结）辅助函数  
- 位置：`store_html/pos_backend/helpers/pos_helper.php` 中的 `calculate_eod_totals()`  

- 描述：  
  - 早期版本中，`calculate_eod_totals()` 函数内曾使用 SQL 引用 `pos_invoice_payments` 等表；  
  - 在当前 Schema（`db_schema_structure_only.sql`）中，这些表已经不存在；  
  - 正式 EOD 逻辑已迁移至 `pos_repo.php::getInvoiceSummaryForPeriod()`，基于 `pos_invoices.payment_summary` 做聚合；  
  - 该函数现在是“幽灵实现”，保留签名但不应被再使用。  

- 现状（2025-11-21 审计）：  
  - `calculate_eod_totals()` 已改为：进入函数即抛出带有 "DEPRECATED" 关键字的异常，并提示改用 `getInvoiceSummaryForPeriod()`；  
  - 班次结束 / 日结提交流程均已切换至新聚合函数，不再调用该函数；  
  - 因此当前运行时不会访问不存在的 `pos_invoice_payments` 表。  

- 影响：  
  - 运行时风险已通过“熔断 + 替代实现”规避；  
  - 仍然存在代码阅读和维护噪音，容易误导后续维护者误以为系统中仍有 `pos_invoice_payments`。  

- 建议修复方式（后续阶段）：  
  - 在 EOD 清理阶段彻底删除 `calculate_eod_totals()` 函数及相关死代码；  
  - 删除前，通过 `grep -r "calculate_eod_totals"` 确认无任何实际调用。  

- 当前状态：
  - 🟢 已清理（L4-2B-POS-EOD-MINI 实施阶段删除了 calculate_eod_totals() 函数，仓库内不再存在该幽灵实现）

---

### ISSUE-POS-EOD-001：正常关班未写入 `pos_shifts.expected_cash` 等字段

- 类型：数据完整性 / 一致性问题  
- 模块：POS · 班次管理 / 日结  

- 描述：  
  - `handle_shift_end`（正常关班）仅更新 `pos_shifts.status='ENDED'` 和 `counted_cash`（实点现金）；  
  - `expected_cash` / `cash_variance` / `payment_summary` 等字段在正常关班场景下保持 NULL；  
  - 而 `handle_shift_force_start`（强制关班）会同时写入上述字段；  
  - 导致同一张表中，“正常班次”与“强制关班班次”的字段完整度不一致。  

- 影响：  
  - 如果报表或分析直接基于 `pos_shifts` 表，会发现大多数正常班次缺少关键财务字段，只能再联表 `pos_eod_records` 才能还原信息；  
  - 增加了数据使用的复杂度和误读风险。  

- 建议修复方式：  
  - 在 `pos_registry_ops_shift.php::handle_shift_end` 中：  
    - 调用与 EOD 相同的汇总逻辑（例如 `getInvoiceSummaryForPeriod()` 或提取公共函数），计算 expected_cash / payment_summary；  
    - 更新 `pos_shifts` 时同步写入 `expected_cash`、`cash_variance`、`payment_summary`；  
  - 核对 `handle_shift_force_start` 的逻辑，确保两种关班路径对 `pos_shifts` 和 `pos_eod_records` 的写入字段和公式一致。  

- 当前状态：
  - 🟢 实现完成（claude/fix-pos-eod-shifts-01QCVSgCoU6ev8LKw4mbMFeh, commit 397a881），等待测试环境和生产环境验证后最终关闭。

---

## 3. 功能缺口 / 优惠券相关问题

### ISSUE-POS-FEATURE-001：POS 不支持 `pos_member_issued_coupons`（个人券）核销

- 类型：功能缺口 / 业务能力未覆盖  
- 模块：POS · 优惠券系统  

- 描述：  
  - 数据库 Schema 中存在 `pos_member_issued_coupons` 表，含义为“发放给某个具体会员的优惠券实例”；  
  - POS 当前的优惠券处理逻辑，仅基于 `pos_coupons`（通用券/公开券），未实现对 `pos_member_issued_coupons` 的读取与核销；  
  - 这意味着：“个人券”（只针对某个会员）在 POS 前端目前不可用。  

- 影响：  
  - 如业务希望使用“个人券”场景（例如针对部分会员的精准优惠），POS 端暂无法直接支持；  
  - 当前次卡项目范围内不涉及个人券，因此不影响本阶段上线，但属于未来可扩展能力。  

- 临时措施：  
  - 业务侧如暂不规划个人券功能，则可以接受现状；  
  - 若后续要启用个人券，需要专门立一个“优惠券系统增强”需求。  

- 计划修复阶段：  
  - 建议在“优惠券系统增强 / 精准营销”阶段统一规划：  
    - POS 加入对 `pos_member_issued_coupons` 的支持；  
    - 与 CPSYS/HQ 的发券逻辑打通。  

- 当前状态：记录中（功能缺口，当前项目不处理）。

---

## 4. 架构备注：幽灵表与旧表的定义（重要）

### ARCH-POS-GHOST-TABLES-001：幽灵表与旧表的区分与审计策略

- 类型：架构级备注 / 审计方法说明  

- 描述：  
  - **幽灵表（Ghost Table）**：  
    - 指代码中仍然引用，但在当前 Schema 中已经不存在的表；  
    - 典型表现：某个函数/模块的 SQL 使用某表名，Schema 里没有该表定义；  
    - 这类问题一旦执行，将直接造成运行时错误（500）。  
    - 示例：`pos_invoice_payments` 就是当前已确认的幽灵表引用（见 ISSUE-POS-DB-001）。  

  - **旧表（Legacy Table）**：  
    - 指数据库中仍存在，但已经不再被现有链路使用的表；  
    - 注意：旧表**不一定以 `old_` 前缀命名**，很多旧表是按“新风格命名”保留下来的（例如早期版本的设计残留），只是升级链路时改用了新表而未删除旧表；  
    - 旧表在短期内不会直接导致错误，但会让 Schema 与实际业务不一致，增加维护成本。  

- 审计策略：  
  - 幽灵表：  
    - 通过“代码引用 vs 当前 Schema”对比，可以发现代码中使用但 Schema 中不存在的表名；  
    - POS 线 L4-2B 已经找到一个典型案例（ISSUE-POS-DB-001），全系统（POS/KDS/CPSYS）完成 L4-2B 后，需要统一汇总所有幽灵表引用并逐一清理。  
  - 旧表：  
    - 不能仅依赖命名规则（例如 `old_` 前缀），因为历史上旧表也可能已经按新命名风格；  
    - 需要结合：  
      - Schema 粗筛（L4-2A）；  
      - 各线代码引用审计（L4-2B）；  
    - 得出“在 Schema 存在但各线代码均不再引用”的表清单，然后以“改名 / 降权 / 观察期 / 最终清理”的节奏处理。  

- 当前状态：  
  - POS 线 L4-2B：已发现一个幽灵表引用（ISSUE-POS-DB-001，现已熔断）；  
  - 全系统幽灵表与旧表的最终清单，待 POS / CPSYS / KDS 各线 L4-2B 完成后统一整理。

---

## 5. 次卡售价与展示/落库不一致

### ISSUE-POS-PASS-PRICE-001：次卡方案售价 60€，POS 与 VR 订单金额为 0.00€

- 类型：跨系统逻辑不一致 / 严重业务错误  
- 模块：POS · 次卡售卡（VR） / CPSYS · 次卡方案管理  

- 现象（已复盘）：  
  - 在 CPSYS 的「次卡方案管理」页面中，“销售价格 (€)” 配置为 60.00（例如「10次奶茶卡」）；  
  - POS 优惠中心中，同一张卡显示为 0.00€；  
  - POS 结账时，应收金额为 0.00€；  
  - CPSYS Topup Orders 页面中，对应 VR 订单 “总金额 (€)” 也为 0.00€；  
  - 说明：售价在总部配置正确，但售卖链路实际使用的是 0。  

- 根因（已闭环确认）：  
  1）**CPSYS 写入缺失**  
     - 文件：`/hq_html/html/cpsys/api/registries/cpsys_registry_bms_pass_plan.php`  
     - 函数：`handle_pass_plan_save`  
     - 问题：后端接收到 `sale_settings['price']` 后，只写入影子商品 `pos_item_variants.price_eur`，**没有写入 `pass_plans.sale_price`**，导致该字段长期为 0.00。  

  2）**POS 端“诚实读取”错误字段**  
     - POS 列表接口 `handle_pass_list` 从 `pass_plans.sale_price` 读取售价；  
     - 因为 sale_price = 0.00，前端展示为 0.00；  
     - 购买时，前端将 0.00 放进 `cart_item.price` 传给后端，  
       后端 `create_pass_records()` 用该值写入 `topup_orders.amount_total`，VR 订单金额也变成 0。  

- 修复措施（已落地）：  
  1）CPSYS 写入逻辑修复（Claude 已完成）  
     - 修改文件：`hq_html/html/cpsys/api/registries/cpsys_registry_bms_pass_plan.php`  
     - 在 `handle_pass_plan_save` 中：  
       - `$plan_params` 新增 `':sale_price' => (float)($sale_settings['price'] ?? 0)`；  
       - `UPDATE pass_plans ...` 增加 `sale_price = :sale_price`；  
       - `INSERT INTO pass_plans (...) VALUES (...)` 补上 `sale_price` 列与占位符。  
     - 分支：`claude/fix-toptea-pass-pricing-01PwzkxTUjWNz6r3PTh2SNtC`  
     - Commit：`e016362`（已推送）。  

  2）历史数据回填脚本（Data Patch）  
     - 新增脚本：`hq_html/html/cpsys/tools/fix_pass_plans_sale_price.php`  
     - 逻辑：当 `pp.sale_price = 0.00` 且对应 `variant.price_eur > 0` 时，从 `pos_item_variants.price_eur` 回填到 `pass_plans.sale_price`。  
     - 特性：幂等、事务保护、执行前预览 + 执行后验证。  

  3）测试指南  
     - 新增文档：`hq_html/html/cpsys/tools/TESTING_GUIDE_sale_price_fix.md`  
     - 覆盖场景：  
       - 新建/编辑方案 → sale_price 正确写入；  
       - POS 优惠中心展示价格正确；  
       - POS 售卡 → `topup_orders.amount_total` 与配置价一致；  
       - Data Patch 前后对比与幂等性验证。  

- 当前状态：  
  - ✅ 代码修复：已在 CPSYS 线落地（INSERT + UPDATE 修复）。  
  - ✅ 数据修复脚本：已在测试环境验证通过。  
  - ✅ POS 前端：已在真实 POS 页面实测，展示价格与 VR 订单金额正确。  
  - ⏳ 生产环境：待按 TESTING_GUIDE 步骤在生产执行脚本 & 最终确认。  

- 后续建议：  
  - 在生产环境执行顺序：  
    1）先部署代码；  
    2）执行 `fix_pass_plans_sale_price.php`（数据回填）；  
    3）按测试指南完成一次“后台改价 → POS 展示 → VR 落库”的完整回归；  
  - 完成后，可将本 Issue 状态更新为「✅ 已在生产验证通过」。

---

## 6. 多语言 / 文案显示问题

### ISSUE-POS-I18N-001：次卡名称在西班牙语界面下仍显示中文

- 类型：多语言/i18n 体验问题（需进一步确认是数据还是代码问题）  
- 模块：POS · 次卡展示（优惠中心） / CPSYS · 次卡方案管理  

- 描述：  
  - 当前次卡方案仅录入了中文名称；  
  - 在 POS 切换为西班牙语界面时，次卡名称仍显示中文；  
  - 需确认：  
    - CPSYS / DB 中是否存在西班牙语名称字段（如 `name_es`）但数据为空；  
    - 或 POS 前端在多语言环境下始终读取中文字段（硬编码），没有做语言 fallback。  

- 影响：  
  - 西班牙语模式下，员工看到的仍是中文，不利于日常使用与培训；  
  - 后续如果接入多语言小票/前台文案，会持续产生不一致。  

- 建议修复阶段：  
  - 与次卡售价问题一起，在 `POS-CPSYS-PASS-VR-PRICE-MINI` 或单独的 i18n 整理阶段中处理：  
    - 审计 `pass_plans` / 相关表的多语言字段设计；  
    - 明确 POS 在不同语言下的字段选择和回退策略；  
    - 制定运营层面的文案录入规范（必须同时填写中/西文）。  

- 当前状态：已记录，待确认是“缺数据”还是“代码逻辑问题”。

---

## 7. 审核机制与核销支付渠道限制

### ISSUE-POS-PASS-REVIEW-001：次卡售卡审核形同虚设（已修复）

- 类型：业务流程缺口 / 审核未生效（已修复）  
- 模块：POS · 次卡售卡（VR） / CPSYS · 次卡方案管理（B1）  

- 现象：  
  - CPSYS 中配置了需要人工审核的次卡方案（`auto_activate=0`）；  
  - 旧实现中，新售出的次卡在 POS 中依然可以立即核销；  
  - Topup Orders 页面显示大量 `pending` 订单，但对应卡已经在使用，审核记录形同虚设。  

- 根因：  
  - `store_html/pos_backend/helpers/pos_pass_helper.php::create_pass_records()` 在插入 `member_passes` 时硬编码 `status='active'`，无视 `pass_plans.auto_activate`；  
  - `get_member_pass_for_update()` 仅过滤 `status='active'`，导致所有新卡都被视为可用。  

- 修复状态：  
  - ✅ 已修复（2025-11-21，CPSYS-B1-PASS-REVIEW-AND-PAYMENT-MINI）。  

- 修复方案摘要：  
  - 新增逻辑：根据 `plan_details.auto_activate` 决定新卡初始 `status`：  
    - `auto_activate=1` → `status='active'`  
    - `auto_activate=0` → `status='suspended'`（待审核状态，不可核销）  
  - 叠加购买（UPDATE）不再修改 `status`，避免误锁已有 active 卡；  
  - 审核通过时，沿用 `activate_member_pass()` 将 `status` 统一改为 `active`。  

- 相关提交：  
  - 分支：`claude/fix-payment-review-01Xsx8QHC48YqqXk7aBXWzhk`  
  - Commit：`47465d6`  

- 技术债 / 后续优化：  
  - 目前 `suspended` 同时表示“未审核”和“其他原因挂起”；  
  - 将来引入风控冻结时，需要新增 `suspend_reason` 等字段来区分具体原因，而不是继续增加新的 `status` 枚举值。  

---

### ISSUE-POS-PASS-PAYMENT-001：次卡核销有加价时支付方式未受控（已修复）

- 类型：风控规则未落地（已修复）  
- 模块：POS · 次卡核销结账 / 支付  

- 现象：  
  - 次卡核销存在额外收费（`extra_charge_total > 0`）时：  
    - POS 前端依然展示 Bizum / Platform 等支付方式；  
    - 只要金额正确，后端允许任何支付方式通过。  

- 根因：  
  - 前端 `payment.js::restrictPaymentMethods()` 仅在“购买优惠卡/次卡”时限制支付方式，没有考虑“次卡核销 + 加价”场景；  
  - 后端 `pos_registry_ext_pass.php::handle_pass_redeem()` 只校验金额，不校验支付渠道类型。  

- 修复状态：  
  - ✅ 已修复（2025-11-21，CPSYS-B1-PASS-REVIEW-AND-PAYMENT-MINI）。  

- 修复方案摘要：  
  - 前端：  
    - 在 `restrictPaymentMethods()` 中增加条件：  
      - 当存在 `STATE.activePassSession` 且 `STATE.calculatedCart.final_total > 0` 时，只展示「现金 / 银行卡」。  
  - 后端：  
    - 使用 `extract_payment_totals()` 对支付方式归类为 `$cash / $card / $platform`；  
    - 若 `extra_total > 0` 且 `$platform > 0`，直接返回 400 错误，阻止核销。  

- 相关提交：  
  - 分支：`claude/fix-payment-review-01Xsx8QHC48YqqXk7aBXWzhk`  
  - Commit：`47465d6`  

- 技术债 / 后续优化：  
  - 0 元核销当前仍走支付弹窗；后续需要单独设计“直接核销”流程；  
  - 将来若新增支付方式（例如新平台码），必须同步更新 `extract_payment_totals()` 和白名单规则。  

---

### ISSUE-POS-PASS-UX-REDEEM-0PAY-001：次卡 0 元核销交互不友好（仍要求选择支付方式）

- 类型：UX 优化 / 交互与语义不一致  
- 模块：POS · 次卡核销（P3/P4 前端）  

- 当前行为：  
  - 在次卡核销场景下，即使 `extra_charge_total = 0`（无任何加价），POS 仍然弹出支付方式列表；  
  - 员工必须选择“现金 / 银行卡”等支付方式之一，完成一笔“0 元支付”后才算核销成功；  
  - 业务上这更像是“确认核销”，但 UI 上表现为“选择支付方式”。  

- 期望行为（设计目标）：  
  - 当次卡核销且 `extra_charge_total = 0` 时：  
    - 不弹标准支付方式列表；  
    - 而是弹出一个简单的确认弹窗：  
      - 文案示例：“本次核销 2 杯，金额 0.00 €”；  
      - 按钮：[取消] / [核销]；  
    - 点击“核销”即视为一次“0 元支付 + 核销确认”，走完当前核销链路。  

- 与现有 B1 修复的关系：  
  - 有加价（`extra_charge_total > 0`）场景的安全性已在 B1 阶段通过“支付方式白名单 + 后端校验”处理；  
  - 本 Issue 只针对 0 元核销的 UX，不影响现有审核/风控逻辑；  
  - 建议后续通过独立 mini 阶段（`POS-PASS-UX-REDEEM-ZERO-MINI`）实现，以减少对高频业务路径的风险。  

- 当前状态：  
  - ✅ 需求与设计意图已在系统说明中记录；  
  - ⏳ 未实现，等待后续 UX Mini 阶段立项。
