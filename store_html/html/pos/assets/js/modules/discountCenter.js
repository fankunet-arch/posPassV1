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
import { startPassRedemptionSession } from './passSession.js';

/**
 * 优惠类型配置 (分层结构，可扩展)
 *
 * 第一级：优惠分类
 * 第二级：具体操作
 *
 * 结构：
 * {
 *   key: string,
 *   label_i18n_key: string,
 *   icon: string,
 *   children: [ { key, label_i18n_key, icon, handler } ]
 * }
 */
const DISCOUNT_TYPES = [
    {
        key: 'pass_category',
        label_i18n_key: 'discount_center_pass_category', // "次卡"
        icon: 'bi-credit-card',
        children: [
            {
                key: 'pass_purchase',
                label_i18n_key: 'discount_center_pass_purchase', // "购买次卡"
                icon: 'bi-cart-plus',
                handler: handlePassPurchase
            },
            {
                key: 'pass_redeem',
                label_i18n_key: 'discount_center_pass_redeem', // "核销次卡"
                icon: 'bi-credit-card-2-front',
                handler: handlePassRedeem
            }
        ]
    }
    // 未来可以添加更多分类，例如：
    // {
    //     key: 'voucher_category',
    //     label_i18n_key: 'discount_center_voucher_category', // "折扣券"
    //     icon: 'bi-ticket-perforated',
    //     children: [
    //         {
    //             key: 'voucher_purchase',
    //             label_i18n_key: 'discount_center_voucher_purchase',
    //             icon: 'bi-cart-plus',
    //             handler: handleVoucherPurchase
    //         },
    //         {
    //             key: 'voucher_redeem',
    //             label_i18n_key: 'discount_center_voucher_redeem',
    //             icon: 'bi-ticket-detailed',
    //             handler: handleVoucherRedeem
    //         }
    //     ]
    // }
];

/**
 * 打开优惠中心面板
 * 这是优惠中心的主入口函数
 *
 * 使用 Modal（屏幕中央弹窗）而不是 Offcanvas
 * 显示第1层：优惠类型分类列表
 */
export function openDiscountCenter() {
    console.log('[discountCenter] ====== 打开优惠中心 ======');

    // 检查 Modal 元素是否存在
    const modalEl = document.getElementById('passActionSelectorModal');
    if (!modalEl) {
        console.error('[discountCenter] ❌ 错误：未找到 #passActionSelectorModal 元素');
        console.error('[discountCenter] 请检查 index.php 中是否包含次卡选择 Modal 的 HTML');
        alert('错误：优惠中心面板未找到，请联系技术支持');
        return;
    }

    console.log('[discountCenter] ✅ 找到优惠中心 Modal 元素');

    // [第1层] 渲染优惠类型分类列表
    renderDiscountCategories(modalEl);

    // 打开 Modal
    console.log('[discountCenter] 打开 Bootstrap Modal');
    try {
        const modal = bootstrap.Modal.getOrCreateInstance(modalEl);
        modal.show();
        console.log('[discountCenter] ✅ Modal 已显示（第1层：分类列表）');
    } catch (error) {
        console.error('[discountCenter] ❌ 打开 Modal 失败:', error);
        alert('错误：无法打开优惠中心面板，请刷新页面重试');
    }
}

/**
 * 处理次卡购买操作
 * 直接打开次卡购买列表
 */
function handlePassPurchase() {
    console.log('[discountCenter] 用户选择：购买次卡');

    // 关闭 Modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('passActionSelectorModal'));
    if (modal) {
        modal.hide();
    }

    // 延迟打开次卡购买列表
    setTimeout(() => {
        openDiscountCardsPanel();
    }, 300);
}

/**
 * 处理次卡核销操作
 * 统一的核销优惠入口
 */
function handlePassRedeem() {
    console.log('[discountCenter] 用户选择：核销次卡');

    // 关闭 Modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('passActionSelectorModal'));
    if (modal) {
        modal.hide();
    }

    // 延迟执行检查逻辑，等待 Modal 关闭动画完成
    setTimeout(() => {
        // 1. 检查是否已绑定会员
        if (!STATE.activeMember) {
            console.log('[discountCenter] 未绑定会员，提示用户');
            toast(t('pass_redeem_no_member'));

            // 引导用户打开购物车侧边栏进行会员绑定
            setTimeout(() => {
                const cartOffcanvas = bootstrap.Offcanvas.getOrCreateInstance(document.getElementById('cartOffcanvas'));
                cartOffcanvas.show();

                // 聚焦到会员搜索框
                setTimeout(() => {
                    document.getElementById('member_search_phone')?.focus();
                }, 500);
            }, 100);

            return;
        }

        // 2. 检查会员是否有可用次卡
        const availablePasses = STATE.activeMember.passes?.filter(p => p.remaining_uses > 0) || [];
        if (availablePasses.length === 0) {
            console.log('[discountCenter] 会员无可用次卡，提示并询问是否购买');

            // 显示确认对话框
            if (confirm(t('pass_redeem_no_available'))) {
                // 用户选择前往购买
                handlePassPurchase();
            }

            return;
        }

        // 3. 会员有可用次卡，选择第一张进入核销模式
        console.log('[discountCenter] 会员有', availablePasses.length, '张可用次卡');

        // 如果只有一张次卡，直接使用
        // 如果有多张次卡，使用第一张（未来可以优化为让用户选择）
        const selectedPass = availablePasses[0];
        console.log('[discountCenter] 选择次卡:', selectedPass);

        // 调用统一的核销模式入口函数
        startPassRedemptionSession(selectedPass);
    }, 350);
}

/**
 * 渲染第1层：优惠类型分类列表
 * @param {HTMLElement} modalEl - Modal 元素
 */
function renderDiscountCategories(modalEl) {
    console.log('[discountCenter] 渲染第1层：优惠类型分类列表');

    // 更新 Modal 标题
    const titleEl = modalEl.querySelector('.modal-title');
    titleEl.innerHTML = `
        <i class="bi bi-gift me-2 text-brand"></i>
        <span>${t('discount_center_title') || '优惠中心'}</span>
    `;

    // 更新 Modal 内容：显示分类列表
    const bodyEl = modalEl.querySelector('.modal-body');
    let categoriesHTML = `<p class="text-muted mb-3">${t('discount_center_select_category') || '请选择优惠类型：'}</p>`;

    DISCOUNT_TYPES.forEach((category, index) => {
        const borderColor = index === 0 ? 'border-primary' : 'border-secondary';
        const iconColor = index === 0 ? 'text-primary' : 'text-secondary';

        categoriesHTML += `
            <div class="card mb-3 ${borderColor}" style="cursor: pointer;" data-category-key="${category.key}">
                <div class="card-body d-flex align-items-center">
                    <div class="flex-shrink-0 me-3">
                        <i class="bi ${category.icon} fs-1 ${iconColor}"></i>
                    </div>
                    <div class="flex-grow-1">
                        <h6 class="mb-0">${t(category.label_i18n_key)}</h6>
                    </div>
                    <div class="flex-shrink-0">
                        <i class="bi bi-chevron-right fs-4 text-muted"></i>
                    </div>
                </div>
            </div>
        `;
    });

    bodyEl.innerHTML = categoriesHTML;

    // 绑定分类点击事件（事件委托）
    bodyEl.querySelectorAll('[data-category-key]').forEach(card => {
        card.addEventListener('click', () => {
            const categoryKey = card.dataset.categoryKey;
            console.log('[discountCenter] 用户点击分类:', categoryKey);

            const category = DISCOUNT_TYPES.find(c => c.key === categoryKey);
            if (category) {
                renderCategoryActions(modalEl, category);
            }
        });
    });
}

/**
 * 渲染第2层：具体操作列表
 * @param {HTMLElement} modalEl - Modal 元素
 * @param {Object} category - 分类对象
 */
function renderCategoryActions(modalEl, category) {
    console.log('[discountCenter] 渲染第2层：操作列表', category);

    // 更新 Modal 标题（添加返回按钮）
    const titleEl = modalEl.querySelector('.modal-title');
    titleEl.innerHTML = `
        <button class="btn btn-sm btn-link text-decoration-none p-0 me-2" id="btn_back_to_categories">
            <i class="bi bi-arrow-left fs-5"></i>
        </button>
        <i class="bi ${category.icon} me-2 text-brand"></i>
        <span>${t(category.label_i18n_key)}</span>
    `;

    // 更新 Modal 内容：显示操作列表
    const bodyEl = modalEl.querySelector('.modal-body');
    let actionsHTML = `<p class="text-muted mb-3">${t('discount_center_select_action') || '请选择操作类型：'}</p>`;

    category.children.forEach((action, index) => {
        const borderColor = index === 0 ? 'border-primary' : 'border-success';
        const iconColor = index === 0 ? 'text-primary' : 'text-success';

        actionsHTML += `
            <div class="card mb-3 ${borderColor}" style="cursor: pointer;" data-action-key="${action.key}">
                <div class="card-body d-flex align-items-center">
                    <div class="flex-shrink-0 me-3">
                        <i class="bi ${action.icon} fs-1 ${iconColor}"></i>
                    </div>
                    <div class="flex-grow-1">
                        <h6 class="mb-1">${t(action.label_i18n_key)}</h6>
                        <small class="text-muted">${t(action.label_i18n_key + '_desc') || ''}</small>
                    </div>
                    <div class="flex-shrink-0">
                        <i class="bi bi-chevron-right fs-4 text-muted"></i>
                    </div>
                </div>
            </div>
        `;
    });

    bodyEl.innerHTML = actionsHTML;

    // 绑定返回按钮事件
    const btnBack = modalEl.querySelector('#btn_back_to_categories');
    if (btnBack) {
        btnBack.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            console.log('[discountCenter] 用户点击返回');
            renderDiscountCategories(modalEl);
        });
    }

    // 绑定操作点击事件（事件委托）
    bodyEl.querySelectorAll('[data-action-key]').forEach(card => {
        card.addEventListener('click', () => {
            const actionKey = card.dataset.actionKey;
            console.log('[discountCenter] 用户点击操作:', actionKey);

            const action = category.children.find(a => a.key === actionKey);
            if (action && action.handler) {
                action.handler();
            }
        });
    });
}

/**
 * 初始化优惠中心事件
 * 在 main.js 中调用
 */
export function initDiscountCenterEvents() {
    console.log('[discountCenter] ====== 初始化优惠中心模块 ======');
    console.log('[discountCenter] 优惠类型配置:', DISCOUNT_TYPES);
    console.log('[discountCenter] 模块加载完成，优惠中心已配置', DISCOUNT_TYPES.length, '个分类');
}
