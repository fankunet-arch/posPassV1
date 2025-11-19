/**
 * 优惠中心模块 - Discount Center Module
 *
 * 功能：统一管理 POS 的各类优惠入口
 * - v1: 次卡购买 (Pass)
 * - 未来可扩展: 优惠券包、充值卡等
 *
 * Engineer: Claude | Date: 2025-11-18
 */

import { STATE } from '../state.js';
import { t, toast } from '../utils.js';
import { openDiscountCardsPanel } from './discountCard.js';

/**
 * 优惠类型配置 (可扩展)
 * 结构：{ key: string, label_i18n_key: string, handler: function }
 */
const DISCOUNT_TYPES = [
    {
        key: 'pass',
        label_i18n_key: 'discount_center_pass', // "次卡"
        handler: handlePassPurchase
    }
    // 未来可以添加更多类型，例如：
    // {
    //     key: 'voucher',
    //     label_i18n_key: 'discount_center_voucher',
    //     handler: handleVoucherPurchase
    // }
];

/**
 * 打开优惠中心面板
 * 这是优惠中心的主入口函数
 */
export function openDiscountCenter() {
    console.log('[discountCenter] ====== 打开优惠中心 ======');

    // 检查 DOM 元素是否存在
    const offcanvasEl = document.getElementById('discountCenterOffcanvas');
    if (!offcanvasEl) {
        console.error('[discountCenter] ❌ 错误：未找到 #discountCenterOffcanvas 元素');
        console.error('[discountCenter] 请检查 index.php 中是否包含优惠中心面板的 HTML');
        alert('错误：优惠中心面板未找到，请联系技术支持');
        return;
    }

    console.log('[discountCenter] ✅ 找到优惠中心面板元素');

    // 渲染优惠类型列表
    console.log('[discountCenter] 开始渲染优惠类型列表');
    renderDiscountTypes();

    // 打开 Offcanvas
    console.log('[discountCenter] 打开 Bootstrap Offcanvas');
    try {
        const offcanvas = new bootstrap.Offcanvas(offcanvasEl);
        offcanvas.show();
        console.log('[discountCenter] ✅ Offcanvas 已显示');
    } catch (error) {
        console.error('[discountCenter] ❌ 打开 Offcanvas 失败:', error);
        alert('错误：无法打开优惠中心面板，请刷新页面重试');
    }
}

/**
 * 渲染优惠类型列表
 */
function renderDiscountTypes() {
    console.log('[discountCenter] renderDiscountTypes 开始');
    console.log('[discountCenter] 优惠类型数量:', DISCOUNT_TYPES.length);

    const container = document.getElementById('discount_center_types_list');
    if (!container) {
        console.error('[discountCenter] ❌ 未找到容器 #discount_center_types_list');
        return;
    }

    console.log('[discountCenter] ✅ 找到类型列表容器');
    container.innerHTML = '';

    DISCOUNT_TYPES.forEach((type, index) => {
        console.log(`[discountCenter] 渲染类型 ${index + 1}:`, type.key);
        const typeItem = document.createElement('div');
        typeItem.className = 'list-group-item list-group-item-action d-flex justify-content-between align-items-center';
        typeItem.style.cursor = 'pointer';

        typeItem.innerHTML = `
            <div class="d-flex align-items-center">
                <i class="bi bi-credit-card-2-front fs-4 me-3 text-brand"></i>
                <div>
                    <h6 class="mb-0" data-i18n="${type.label_i18n_key}">${t(type.label_i18n_key)}</h6>
                    <small class="text-muted" data-i18n="${type.label_i18n_key}_desc">${t(type.label_i18n_key + '_desc')}</small>
                </div>
            </div>
            <i class="bi bi-chevron-right text-muted"></i>
        `;

        // 点击事件
        typeItem.addEventListener('click', () => {
            console.log(`[discountCenter] 用户点击了类型: ${type.key}`);
            type.handler();
        });

        container.appendChild(typeItem);
    });
}

/**
 * 处理次卡购买
 * 调用现有的 discountCard.js 模块
 */
function handlePassPurchase() {
    console.log('[discountCenter] 进入次卡购买流程');

    // 关闭优惠中心面板
    const centerOffcanvas = bootstrap.Offcanvas.getInstance(document.getElementById('discountCenterOffcanvas'));
    if (centerOffcanvas) {
        centerOffcanvas.hide();
    }

    // 延迟打开次卡列表，等待优惠中心面板关闭动画完成
    setTimeout(() => {
        openDiscountCardsPanel();
    }, 300);
}

/**
 * 初始化优惠中心事件
 * 在 main.js 中调用
 */
export function initDiscountCenterEvents() {
    console.log('[discountCenter] ====== 初始化优惠中心模块 ======');
    console.log('[discountCenter] 优惠类型配置:', DISCOUNT_TYPES);
    console.log('[discountCenter] 模块加载完成，等待分类点击触发');

    // 目前不需要额外的事件绑定
    // openDiscountCenter() 会在分类点击时被调用
}
