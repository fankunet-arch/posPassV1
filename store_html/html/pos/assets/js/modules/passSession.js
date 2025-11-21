/**
 * 次卡核销会话管理模块 - Pass Redemption Session Module
 *
 * 功能：统一管理次卡核销会话的业务逻辑
 * - 启动次卡核销会话
 * - 退出次卡核销会话
 * - 管理核销会话状态
 *
 * 职责：纯业务逻辑，不做入口初始化，不依赖 main.js
 *
 * Engineer: Claude | Date: 2025-11-20
 * Task: 修复 main.js 循环依赖问题（打破 main.js ↔ discountCenter.js 循环）
 */

import { STATE } from '../state.js';
import { t, toast } from '../utils.js';
import { calculatePromotions } from './cart.js';
import { refreshCartUI, updateMemberUI, renderCategories, renderProducts } from '../ui.js';

/**
 * [PASS_REDEEM] 统一的次卡核销模式入口函数
 * 供多处调用：会员侧边栏的"使用"按钮、优惠中心的"使用次卡"选项
 * @param {Object} pass - 要使用的次卡对象
 */
export function startPassRedemptionSession(pass) {
    if (!pass) {
        console.error('[PASS_REDEEM] startPassRedemptionSession: pass is null or undefined');
        return;
    }

    // [FIX] 购物车非空时禁止进入核销模式
    if (STATE.cart && STATE.cart.length > 0) {
        console.warn('[PASS_REDEEM] 购物车非空，拒绝进入核销模式');
        toast(t('pass_redeem_cart_not_empty'));
        return;
    }

    console.log('[PASS_REDEEM] 进入核销模式，次卡:', pass);

    // 设置核销会话
    STATE.activePassSession = pass;
    STATE.cart = []; // 清空购物车（此时已确认为空）

    // 刷新各个 UI 组件
    calculatePromotions(); // 刷新购物车UI (会调用 refreshCartUI)
    updateMemberUI();      // 刷新会员UI (显示"正在核销")
    renderCategories();    // 刷新分类 (禁用)
    renderProducts();      // 刷新产品 (只显示白名单)

    // 显示提示
    toast(t('pass_session_toast_enter'));

    // [FIX] 关闭所有可能打开的侧边栏和 Modal，并移除遗留的 backdrop
    const cartOffcanvas = bootstrap.Offcanvas.getInstance('#cartOffcanvas');
    const passActionModal = bootstrap.Modal.getInstance('#passActionSelectorModal');

    if (cartOffcanvas) cartOffcanvas.hide();
    if (passActionModal) passActionModal.hide();

    // [FIX] 强制移除所有可能遗留的 backdrop 遮罩层
    // 这是为了防止遮罩层遮挡商品卡片导致无法点击
    setTimeout(() => {
        const backdrops = document.querySelectorAll('.modal-backdrop, .offcanvas-backdrop');
        backdrops.forEach(backdrop => backdrop.remove());
        console.log('[PASS_REDEEM] 已清理', backdrops.length, '个遗留的 backdrop 遮罩层');
    }, 500); // 延迟 500ms 确保关闭动画完成
}

/**
 * [PASS_REDEEM] 退出次卡核销会话
 * 供事件绑定调用（#btn_exit_pass_mode 按钮）
 */
export function exitPassRedemptionSession() {
    console.log('[PASS_REDEEM] 退出核销模式');

    STATE.activePassSession = null;
    STATE.cart = []; // 清空购物车

    calculatePromotions(); // 刷新购物车UI
    updateMemberUI();      // 刷新会员UI (恢复正常)
    renderCategories();    // 刷新分类 (启用)
    renderProducts();      // 刷新产品 (恢复正常)

    toast(t('pass_session_toast_exit'));
}
