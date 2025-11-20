-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- 主机： mhdlmskv3gjbpqv3.mysql.db
-- 生成日期： 2025-11-20 03:33:35
-- 服务器版本： 8.4.6-6
-- PHP 版本： 8.1.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- 数据库： `mhdlmskv3gjbpqv3`
--
CREATE DATABASE IF NOT EXISTS `mhdlmskv3gjbpqv3` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `mhdlmskv3gjbpqv3`;

-- --------------------------------------------------------

--
-- 表的结构 `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
  `log_id` bigint UNSIGNED NOT NULL,
  `action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '动作 (e.g., pass.purchase, pass.review)',
  `actor_user_id` int UNSIGNED NOT NULL COMMENT '操作人ID (kds_users或cpsys_users)',
  `actor_type` enum('store_user','hq_user') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'store_user',
  `target_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '目标类型 (e.g., member_pass, topup_order)',
  `target_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '目标ID',
  `data_json` json DEFAULT NULL COMMENT '详细数据',
  `ip` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '操作IP',
  `ua` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'User Agent',
  `session_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '会话ID',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: 审计日志表';

-- --------------------------------------------------------

--
-- 表的结构 `cpsys_roles`
--

DROP TABLE IF EXISTS `cpsys_roles`;
CREATE TABLE `cpsys_roles` (
  `id` int UNSIGNED NOT NULL,
  `role_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色名称 (e.g., Super Admin)',
  `role_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '角色描述',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='后台系统角色表';

-- --------------------------------------------------------

--
-- 表的结构 `cpsys_users`
--

DROP TABLE IF EXISTS `cpsys_users`;
CREATE TABLE `cpsys_users` (
  `id` int UNSIGNED NOT NULL,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '显示名称',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '账户是否激活',
  `role_id` int UNSIGNED NOT NULL COMMENT '外键, 关联 cpsys_roles 表',
  `last_login_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='后台系统用户表';

-- --------------------------------------------------------

--
-- 表的结构 `expsys_store_stock`
--

DROP TABLE IF EXISTS `expsys_store_stock`;
CREATE TABLE `expsys_store_stock` (
  `id` int UNSIGNED NOT NULL,
  `store_id` int UNSIGNED NOT NULL,
  `material_id` int UNSIGNED NOT NULL,
  `quantity` decimal(10,2) NOT NULL DEFAULT '0.00',
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT 'UTC'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- 表的结构 `expsys_warehouse_stock`
--

DROP TABLE IF EXISTS `expsys_warehouse_stock`;
CREATE TABLE `expsys_warehouse_stock` (
  `id` int UNSIGNED NOT NULL,
  `material_id` int UNSIGNED NOT NULL,
  `quantity` decimal(10,2) NOT NULL DEFAULT '0.00',
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT 'UTC'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- 表的结构 `kds_cups`
--

DROP TABLE IF EXISTS `kds_cups`;
CREATE TABLE `kds_cups` (
  `id` int UNSIGNED NOT NULL,
  `cup_code` smallint UNSIGNED NOT NULL COMMENT '杯型自定义编号 (1-2位)',
  `cup_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '杯型名称 (e.g., 中杯)',
  `volume_ml` int DEFAULT NULL COMMENT '杯型容量(毫升)',
  `sop_description_zh` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sop_description_es` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 杯型管理';

-- --------------------------------------------------------

--
-- 表的结构 `kds_global_adjustment_rules`
--

DROP TABLE IF EXISTS `kds_global_adjustment_rules`;
CREATE TABLE `kds_global_adjustment_rules` (
  `id` int UNSIGNED NOT NULL,
  `rule_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规则名称, e.g., "标准糖量公式"',
  `priority` int NOT NULL DEFAULT '100' COMMENT '执行优先级，数字越小越先执行',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `cond_cup_id` int UNSIGNED DEFAULT NULL COMMENT '条件: 杯型ID (NULL为全部)',
  `cond_ice_id` int UNSIGNED DEFAULT NULL COMMENT '条件: 冰量ID (NULL为全部)',
  `cond_sweet_id` int UNSIGNED DEFAULT NULL COMMENT '条件: 甜度ID (NULL为全部)',
  `cond_material_id` int UNSIGNED DEFAULT NULL COMMENT '条件: 针对哪个基础物料 (NULL为全部)',
  `cond_base_gt` decimal(10,2) DEFAULT NULL COMMENT '条件: L1基础用量大于此值',
  `cond_base_lte` decimal(10,2) DEFAULT NULL COMMENT '条件: L1基础用量小于等于此值',
  `action_type` enum('SET_VALUE','ADD_MATERIAL','CONDITIONAL_OFFSET','MULTIPLY_BASE') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '动作: SET=设为定值, ADD=添加物料, OFFSET=偏移量, MULTIPLY=乘基础值',
  `action_material_id` int UNSIGNED NOT NULL COMMENT '动作: 目标物料ID (e.g., 果糖, 冰)',
  `action_value` decimal(10,2) NOT NULL COMMENT '动作: 值 (e.g., 50.00, 1.25, -10.00)',
  `action_unit_id` int UNSIGNED DEFAULT NULL COMMENT '动作: ADD_MATERIAL 时的新单位ID',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='RMS V2.2 - 全局动态调整规则 (L2)';

-- --------------------------------------------------------

--
-- 表的结构 `kds_ice_options`
--

DROP TABLE IF EXISTS `kds_ice_options`;
CREATE TABLE `kds_ice_options` (
  `id` int UNSIGNED NOT NULL,
  `ice_code` smallint UNSIGNED NOT NULL COMMENT '冰量自定义编号 (1-2位)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 冰量选项管理';

-- --------------------------------------------------------

--
-- 表的结构 `kds_ice_option_translations`
--

DROP TABLE IF EXISTS `kds_ice_option_translations`;
CREATE TABLE `kds_ice_option_translations` (
  `id` int UNSIGNED NOT NULL,
  `ice_option_id` int UNSIGNED NOT NULL,
  `language_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '语言代码 (zh-CN, es-ES)',
  `ice_option_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '该语言下的选项名称',
  `sop_description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 冰量选项翻译表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_materials`
--

DROP TABLE IF EXISTS `kds_materials`;
CREATE TABLE `kds_materials` (
  `id` int UNSIGNED NOT NULL,
  `material_code` smallint UNSIGNED NOT NULL COMMENT '物料自定义编号 (1-2位)',
  `material_type` enum('RAW','SEMI_FINISHED','PRODUCT','CONSUMABLE') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SEMI_FINISHED',
  `base_unit_id` int UNSIGNED NOT NULL,
  `medium_unit_id` int UNSIGNED DEFAULT NULL,
  `medium_conversion_rate` decimal(10,2) DEFAULT NULL COMMENT '1 中级单位 = X 基础单位',
  `large_unit_id` int UNSIGNED DEFAULT NULL,
  `large_conversion_rate` decimal(10,2) DEFAULT NULL COMMENT '1 大单位 = X 中级单位',
  `expiry_rule_type` enum('HOURS','DAYS','END_OF_DAY') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expiry_duration` int DEFAULT NULL,
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '物料图片URL',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 物料字典主表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_material_expiries`
--

DROP TABLE IF EXISTS `kds_material_expiries`;
CREATE TABLE `kds_material_expiries` (
  `id` int UNSIGNED NOT NULL,
  `store_id` int UNSIGNED NOT NULL,
  `material_id` int UNSIGNED NOT NULL,
  `batch_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `opened_at` datetime(6) NOT NULL,
  `expires_at` datetime(6) NOT NULL,
  `status` enum('ACTIVE','USED','DISCARDED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `handler_id` int UNSIGNED DEFAULT NULL,
  `handled_at` datetime(6) DEFAULT NULL,
  `notes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- 表的结构 `kds_material_translations`
--

DROP TABLE IF EXISTS `kds_material_translations`;
CREATE TABLE `kds_material_translations` (
  `id` int UNSIGNED NOT NULL,
  `material_id` int UNSIGNED NOT NULL,
  `language_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '语言代码 (zh-CN, es-ES)',
  `material_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '物料名称'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 物料翻译表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_products`
--

DROP TABLE IF EXISTS `kds_products`;
CREATE TABLE `kds_products` (
  `id` int UNSIGNED NOT NULL,
  `product_code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产品唯一编码 (P-Code)',
  `status_id` int UNSIGNED NOT NULL,
  `category_id` int UNSIGNED DEFAULT NULL,
  `product_qr_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '预留给二维码数据',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否上架',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL,
  `is_deleted_flag` int UNSIGNED NOT NULL DEFAULT '0' COMMENT '用于软删除唯一约束的辅助列'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 产品主表';

--
-- 触发器 `kds_products`
--
DROP TRIGGER IF EXISTS `before_product_soft_delete`;
DELIMITER $$
CREATE TRIGGER `before_product_soft_delete` BEFORE UPDATE ON `kds_products` FOR EACH ROW BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
        SET NEW.is_deleted_flag = OLD.id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_adjustments`
--

DROP TABLE IF EXISTS `kds_product_adjustments`;
CREATE TABLE `kds_product_adjustments` (
  `id` int UNSIGNED NOT NULL,
  `product_id` int UNSIGNED NOT NULL COMMENT '关联的产品ID',
  `option_type` enum('sweetness','ice') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '选项类型 (甜度或冰度)',
  `option_id` int UNSIGNED NOT NULL COMMENT '关联的选项ID (来自 kds_sweetness_options 或 kds_ice_options)',
  `material_id` int UNSIGNED NOT NULL COMMENT '需要调整用量的物料ID (如糖浆, 冰块)',
  `quantity` decimal(10,2) NOT NULL COMMENT '该选项下的物料用量',
  `unit_id` int UNSIGNED NOT NULL COMMENT '用量的单位ID',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 产品动态用量调整表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_categories`
--

DROP TABLE IF EXISTS `kds_product_categories`;
CREATE TABLE `kds_product_categories` (
  `id` int UNSIGNED NOT NULL,
  `parent_id` int UNSIGNED DEFAULT NULL COMMENT '父分类ID, NULL表示顶级分类',
  `sort_order` int DEFAULT '0' COMMENT '排序字段',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 产品分类主表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_category_translations`
--

DROP TABLE IF EXISTS `kds_product_category_translations`;
CREATE TABLE `kds_product_category_translations` (
  `id` int UNSIGNED NOT NULL,
  `category_id` int UNSIGNED NOT NULL,
  `language_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '语言代码 (zh-CN, es-ES)',
  `category_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '分类名称'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 产品分类翻译表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_ice_options`
--

DROP TABLE IF EXISTS `kds_product_ice_options`;
CREATE TABLE `kds_product_ice_options` (
  `product_id` int UNSIGNED NOT NULL,
  `ice_option_id` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品与冰量选项的关联表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_recipes`
--

DROP TABLE IF EXISTS `kds_product_recipes`;
CREATE TABLE `kds_product_recipes` (
  `id` int UNSIGNED NOT NULL,
  `product_id` int UNSIGNED NOT NULL,
  `material_id` int UNSIGNED NOT NULL,
  `unit_id` int UNSIGNED NOT NULL,
  `quantity` decimal(10,2) NOT NULL COMMENT '数量',
  `step_category` enum('base','mixing','topping') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '步骤分类: 底料, 调杯, 顶料',
  `sort_order` int NOT NULL DEFAULT '0' COMMENT '同一分类内的排序',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 产品结构化制作步骤';

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_statuses`
--

DROP TABLE IF EXISTS `kds_product_statuses`;
CREATE TABLE `kds_product_statuses` (
  `id` int UNSIGNED NOT NULL,
  `status_code` smallint UNSIGNED NOT NULL COMMENT '产品状态自定义编号 (1-2位)',
  `status_name_zh` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '状态名称 (中)',
  `status_name_es` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态名称 (西)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 产品状态管理';

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_sweetness_options`
--

DROP TABLE IF EXISTS `kds_product_sweetness_options`;
CREATE TABLE `kds_product_sweetness_options` (
  `product_id` int UNSIGNED NOT NULL,
  `sweetness_option_id` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品与甜度选项的关联表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_product_translations`
--

DROP TABLE IF EXISTS `kds_product_translations`;
CREATE TABLE `kds_product_translations` (
  `id` int UNSIGNED NOT NULL,
  `product_id` int UNSIGNED NOT NULL,
  `language_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '语言代码 (zh-CN, es-ES)',
  `product_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 产品翻译表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_recipe_adjustments`
--

DROP TABLE IF EXISTS `kds_recipe_adjustments`;
CREATE TABLE `kds_recipe_adjustments` (
  `id` int UNSIGNED NOT NULL,
  `product_id` int UNSIGNED NOT NULL COMMENT '关联 kds_products.id',
  `material_id` int UNSIGNED NOT NULL COMMENT '要调整的物料ID',
  `cup_id` int UNSIGNED DEFAULT NULL COMMENT '条件: 杯型ID',
  `sweetness_option_id` int UNSIGNED DEFAULT NULL COMMENT '条件: 甜度选项ID',
  `ice_option_id` int UNSIGNED DEFAULT NULL COMMENT '条件: 冰量选项ID',
  `quantity` decimal(10,2) NOT NULL COMMENT '结果: 该条件下物料的最终用量',
  `unit_id` int UNSIGNED NOT NULL COMMENT '用量的单位ID',
  `step_category` enum('base','mixing','topping') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '结果: 覆盖步骤分类',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 配方动态调整规则表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_sop_query_rules`
--

DROP TABLE IF EXISTS `kds_sop_query_rules`;
CREATE TABLE `kds_sop_query_rules` (
  `id` int UNSIGNED NOT NULL,
  `store_id` int UNSIGNED DEFAULT NULL COMMENT '适用的门店ID, NULL = 全局规则',
  `rule_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规则名称 (e.g., KDS内部码, 门店A二维码)',
  `priority` int NOT NULL DEFAULT '100' COMMENT '解析优先级, 数字越小越先尝试',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `extractor_type` enum('DELIMITER','KEY_VALUE') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DELIMITER' COMMENT '解析器类型',
  `config_json` json NOT NULL COMMENT '解析器配置',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS SOP 查询码解析规则表 (V5.0)';

-- --------------------------------------------------------

--
-- 表的结构 `kds_stores`
--

DROP TABLE IF EXISTS `kds_stores`;
CREATE TABLE `kds_stores` (
  `id` int UNSIGNED NOT NULL,
  `store_code` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '门店码 (e.g., A1001)',
  `store_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '门店名称',
  `invoice_prefix` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '票号前缀 (e.g., S1)',
  `tax_id` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '门店税号 (NIF/CIF)，用于票据合规',
  `default_vat_rate` decimal(5,2) NOT NULL DEFAULT '10.00' COMMENT '门店默认增值税率(%)',
  `store_city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所在城市',
  `store_address` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '详细地址',
  `store_phone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '联系电话',
  `store_cif` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'CIF/税号',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL,
  `billing_system` enum('TICKETBAI','VERIFACTU','NONE') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'NONE' COMMENT '该门店使用的票据合规系统',
  `eod_cutoff_hour` int NOT NULL DEFAULT '3',
  `pr_receipt_type` enum('NONE','WIFI','BLUETOOTH','USB') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NONE' COMMENT '角色1: 小票打印机类型',
  `pr_receipt_ip` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '角色1: IP地址',
  `pr_receipt_port` int DEFAULT NULL COMMENT '角色1: 端口',
  `pr_receipt_mac` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '角色1: 蓝牙MAC',
  `pr_sticker_type` enum('NONE','WIFI','BLUETOOTH','USB') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NONE' COMMENT '角色2: 杯贴打印机类型',
  `pr_sticker_ip` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '角色2: IP地址',
  `pr_sticker_port` int DEFAULT NULL COMMENT '角色2: 端口',
  `pr_sticker_mac` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '角色2: 蓝牙MAC',
  `pr_kds_type` enum('NONE','WIFI','BLUETOOTH','USB') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NONE' COMMENT '角色3: KDS厨房/效期打印机',
  `pr_kds_ip` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '角色3: IP地址',
  `pr_kds_port` int DEFAULT NULL COMMENT '角色3: 端口',
  `pr_kds_mac` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '角色3: 蓝牙MAC'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 门店表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_sweetness_options`
--

DROP TABLE IF EXISTS `kds_sweetness_options`;
CREATE TABLE `kds_sweetness_options` (
  `id` int UNSIGNED NOT NULL,
  `sweetness_code` smallint UNSIGNED NOT NULL COMMENT '甜度自定义编号 (1-2位)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 甜度选项管理';

-- --------------------------------------------------------

--
-- 表的结构 `kds_sweetness_option_translations`
--

DROP TABLE IF EXISTS `kds_sweetness_option_translations`;
CREATE TABLE `kds_sweetness_option_translations` (
  `id` int UNSIGNED NOT NULL,
  `sweetness_option_id` int UNSIGNED NOT NULL,
  `language_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sweetness_option_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sop_description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 甜度选项翻译表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_units`
--

DROP TABLE IF EXISTS `kds_units`;
CREATE TABLE `kds_units` (
  `id` int UNSIGNED NOT NULL,
  `unit_code` smallint UNSIGNED NOT NULL COMMENT '单位自定义编号 (1-2位)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 单位字典主表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_unit_translations`
--

DROP TABLE IF EXISTS `kds_unit_translations`;
CREATE TABLE `kds_unit_translations` (
  `id` int UNSIGNED NOT NULL,
  `unit_id` int UNSIGNED NOT NULL,
  `language_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '语言代码 (zh-CN, es-ES)',
  `unit_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '单位名称'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 单位翻译表';

-- --------------------------------------------------------

--
-- 表的结构 `kds_users`
--

DROP TABLE IF EXISTS `kds_users`;
CREATE TABLE `kds_users` (
  `id` int UNSIGNED NOT NULL,
  `store_id` int UNSIGNED NOT NULL COMMENT '关联的门店ID',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '显示名称',
  `role` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'staff' COMMENT '角色 (e.g., staff, manager)',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `last_login_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='KDS - 用户表';

-- --------------------------------------------------------

--
-- 表的结构 `member_passes`
--

DROP TABLE IF EXISTS `member_passes`;
CREATE TABLE `member_passes` (
  `member_pass_id` int UNSIGNED NOT NULL COMMENT '会员持卡ID',
  `member_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pos_members.id',
  `pass_plan_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pass_plans.pass_plan_id',
  `topup_order_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 topup_orders.topup_order_id (来源订单)',
  `total_uses` int UNSIGNED NOT NULL COMMENT '总次数 (快照)',
  `remaining_uses` int UNSIGNED NOT NULL COMMENT '剩余次数',
  `purchase_amount` decimal(10,2) NOT NULL COMMENT '购卡支付金额 (分摊基准)',
  `unit_allocated_base` decimal(10,2) NOT NULL COMMENT '单位分摊基准价 [cite: 97]',
  `status` enum('active','suspended','revoked','expired') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT '卡状态 [cite: 35]',
  `store_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 kds_stores.id (激活门店)',
  `device_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '激活设备ID',
  `activated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `expires_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: 会员持卡表';

-- --------------------------------------------------------

--
-- 表的结构 `pass_daily_usage`
--

DROP TABLE IF EXISTS `pass_daily_usage`;
CREATE TABLE `pass_daily_usage` (
  `id` int UNSIGNED NOT NULL,
  `member_pass_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 member_passes.member_pass_id',
  `usage_date` date NOT NULL COMMENT '使用日期 (按Madrid时区计算的日期, 存储为UTC日期) [cite: 40]',
  `uses_count` int UNSIGNED NOT NULL DEFAULT '0' COMMENT '当日已用次数'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: 次卡每日用量统计 (防超限)';

-- --------------------------------------------------------

--
-- 表的结构 `pass_plans`
--

DROP TABLE IF EXISTS `pass_plans`;
CREATE TABLE `pass_plans` (
  `pass_plan_id` int UNSIGNED NOT NULL COMMENT '次卡方案ID',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '方案名称 (e.g., 10次奶茶卡)',
  `name_zh` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '中文名称',
  `name_es` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '西班牙语名称',
  `total_uses` int UNSIGNED NOT NULL COMMENT '总可用次数',
  `validity_days` int UNSIGNED NOT NULL COMMENT '有效期(天数)',
  `max_uses_per_order` int UNSIGNED NOT NULL DEFAULT '1' COMMENT '单笔订单最大核销次数 [cite: 31]',
  `max_uses_per_day` int UNSIGNED NOT NULL DEFAULT '0' COMMENT '单日最大核销次数 (0=不限) [cite: 31]',
  `allocation_strategy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'last_adjust' COMMENT '分摊策略 (默认: 尾差法) [cite: 31, 97]',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否激活 (可售)',
  `auto_activate` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0=需后台审核, 1=购买后自动激活',
  `sale_sku` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'FK, 关联 kds_products.product_code (售卖SKU)',
  `sale_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '售价(欧元)',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '备注说明',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: 次卡方案定义表';

-- --------------------------------------------------------

--
-- 表的结构 `pass_redemptions`
--

DROP TABLE IF EXISTS `pass_redemptions`;
CREATE TABLE `pass_redemptions` (
  `redemption_id` int UNSIGNED NOT NULL COMMENT '核销明细ID (每杯)',
  `batch_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pass_redemption_batches.batch_id',
  `member_pass_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 member_passes.member_pass_id',
  `order_id` int UNSIGNED DEFAULT NULL COMMENT 'FK, 关联 pos_invoices.id (TP税票ID, 0元核销时为NULL)',
  `order_item_id` int UNSIGNED DEFAULT NULL COMMENT 'FK, 关联 pos_invoice_items.id (对应单品, 0元核销时为NULL)',
  `sku_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '商品SKU (快照)',
  `invoice_series` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '税票系列 (TP) [cite: 38]',
  `invoice_number` bigint UNSIGNED NOT NULL COMMENT '税票编号 [cite: 38]',
  `covered_amount` decimal(10,2) NOT NULL COMMENT '卡支付分摊金额 (税基1) [cite: 38, 66]',
  `extra_charge` decimal(10,2) NOT NULL COMMENT '额外付费 (加料/差价) (税基2) [cite: 38, 66]',
  `redeemed_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `store_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 kds_stores.id (核销门店)',
  `device_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '核销设备ID',
  `cashier_user_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 kds_users.id (核销员工)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: 次卡核销明细表 (每杯)';

-- --------------------------------------------------------

--
-- 表的结构 `pass_redemption_batches`
--

DROP TABLE IF EXISTS `pass_redemption_batches`;
CREATE TABLE `pass_redemption_batches` (
  `batch_id` int UNSIGNED NOT NULL COMMENT '核销批次ID (对应一单)',
  `member_pass_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 member_passes.member_pass_id',
  `order_id` int UNSIGNED DEFAULT NULL COMMENT 'FK, 关联 pos_invoices.id (TP税票ID, 0元核销时为NULL)',
  `redeemed_uses` int UNSIGNED NOT NULL COMMENT '本批次核销的总次数',
  `extra_charge_total` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '本批次核销的加价总额',
  `store_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 kds_stores.id (核销门店)',
  `cashier_user_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 kds_users.id (核销员工)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `idempotency_key` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: 次卡核销批次表 (每单)';

-- --------------------------------------------------------

--
-- 表的结构 `pos_addons`
--

DROP TABLE IF EXISTS `pos_addons`;
CREATE TABLE `pos_addons` (
  `id` int UNSIGNED NOT NULL,
  `addon_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '唯一键 (e.g., boba)',
  `name_zh` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '中文名称',
  `name_es` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '西语名称',
  `price_eur` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '价格',
  `material_id` int UNSIGNED DEFAULT NULL COMMENT '关联 kds_materials.id (用于库存)',
  `sort_order` int NOT NULL DEFAULT '99',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='POS 可选小料（加料）表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_addon_tag_map`
--

DROP TABLE IF EXISTS `pos_addon_tag_map`;
CREATE TABLE `pos_addon_tag_map` (
  `addon_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pos_addons.id',
  `tag_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pos_tags.tag_id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: POS 加料与标签映射表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_categories`
--

DROP TABLE IF EXISTS `pos_categories`;
CREATE TABLE `pos_categories` (
  `id` int NOT NULL,
  `category_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name_zh` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name_es` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `sort_order` int NOT NULL DEFAULT '99',
  `card_bundle` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1=是次卡售卖分类(POS隐藏)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- 表的结构 `pos_coupons`
--

DROP TABLE IF EXISTS `pos_coupons`;
CREATE TABLE `pos_coupons` (
  `id` int UNSIGNED NOT NULL,
  `promotion_id` int UNSIGNED NOT NULL COMMENT '外键, 关联 pos_promotions.id',
  `coupon_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '优惠码 (大小写不敏感)',
  `coupon_usage_limit` int UNSIGNED NOT NULL DEFAULT '1' COMMENT '每个码可使用的总次数',
  `coupon_usage_count` int UNSIGNED NOT NULL DEFAULT '0' COMMENT '当前已使用次数',
  `coupon_is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS优惠券码表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_daily_tracking`
--

DROP TABLE IF EXISTS `pos_daily_tracking`;
CREATE TABLE `pos_daily_tracking` (
  `id` int UNSIGNED NOT NULL,
  `store_id` int UNSIGNED NOT NULL,
  `last_daily_reset_business_date` date DEFAULT NULL COMMENT '最后执行“每日重置”的营业日期',
  `sold_out_state_snapshot` json DEFAULT NULL COMMENT '交接班时存储的估清状态快照',
  `snapshot_taken_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS 门店每日状态追踪表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_eod_records`
--

DROP TABLE IF EXISTS `pos_eod_records`;
CREATE TABLE `pos_eod_records` (
  `id` bigint UNSIGNED NOT NULL,
  `shift_id` bigint UNSIGNED NOT NULL,
  `store_id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `started_at` datetime(6) NOT NULL,
  `ended_at` datetime(6) NOT NULL,
  `starting_float` decimal(10,2) NOT NULL DEFAULT '0.00',
  `cash_sales` decimal(10,2) NOT NULL DEFAULT '0.00',
  `cash_in` decimal(10,2) NOT NULL DEFAULT '0.00',
  `cash_out` decimal(10,2) NOT NULL DEFAULT '0.00',
  `cash_refunds` decimal(10,2) NOT NULL DEFAULT '0.00',
  `expected_cash` decimal(10,2) NOT NULL DEFAULT '0.00',
  `counted_cash` decimal(10,2) NOT NULL DEFAULT '0.00',
  `cash_diff` decimal(10,2) NOT NULL DEFAULT '0.00',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- 表的结构 `pos_eod_reports`
--

DROP TABLE IF EXISTS `pos_eod_reports`;
CREATE TABLE `pos_eod_reports` (
  `id` int UNSIGNED NOT NULL,
  `store_id` int UNSIGNED NOT NULL,
  `user_id` int UNSIGNED NOT NULL COMMENT '执行日结的用户ID (cpsys_users or kds_users)',
  `report_date` date NOT NULL COMMENT '报告所属日期',
  `executed_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `transactions_count` int NOT NULL DEFAULT '0',
  `system_gross_sales` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '系统计算-总销售额',
  `system_discounts` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '系统计算-总折扣',
  `system_net_sales` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '系统计算-净销售额',
  `system_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '系统计算-总税额',
  `system_cash` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '系统计算-现金收款',
  `system_card` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '系统计算-刷卡收款',
  `system_platform` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '系统计算-平台收款',
  `counted_cash` decimal(10,2) NOT NULL COMMENT '清点的现金金额',
  `cash_discrepancy` decimal(10,2) NOT NULL COMMENT '现金差异 (counted - system)',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '备注'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='POS每日日结报告存档表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_held_orders`
--

DROP TABLE IF EXISTS `pos_held_orders`;
CREATE TABLE `pos_held_orders` (
  `id` int NOT NULL,
  `store_id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `cart_data` json NOT NULL,
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用于存储POS端挂起的订单';

-- --------------------------------------------------------

--
-- 表的结构 `pos_invoices`
--

DROP TABLE IF EXISTS `pos_invoices`;
CREATE TABLE `pos_invoices` (
  `id` int UNSIGNED NOT NULL,
  `invoice_uuid` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '内部全局唯一ID (UUID)',
  `store_id` int UNSIGNED NOT NULL COMMENT '外键, 关联 kds_stores.id',
  `user_id` int UNSIGNED NOT NULL COMMENT '外键, 关联 kds_users.id (收银员)',
  `shift_id` int UNSIGNED DEFAULT NULL,
  `issuer_nif` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '(合规/快照) 开票方税号',
  `series` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '(合规) 票据系列号',
  `number` bigint UNSIGNED NOT NULL COMMENT '(合规) 票据连续编号',
  `issued_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `invoice_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'F2' COMMENT '(合规) 票据类型, F2=简化发票, R5=简化更正票据等',
  `taxable_base` decimal(10,2) NOT NULL COMMENT '税前基数',
  `vat_amount` decimal(10,2) NOT NULL COMMENT '增值税总额',
  `discount_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '促销折扣总额',
  `final_total` decimal(10,2) NOT NULL COMMENT '最终含税总额',
  `status` enum('ISSUED','CANCELLED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ISSUED' COMMENT '状态: ISSUED=已开具, CANCELLED=已作废',
  `cancellation_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '作废原因 (用于RF-anulación)',
  `correction_type` enum('S','I') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '(合规) 更正类型, S=替换, I=差额',
  `references_invoice_id` int UNSIGNED DEFAULT NULL COMMENT '外键, 指向被作废或被更正的原始票据ID',
  `compliance_system` enum('TICKETBAI','VERIFACTU') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '此票据遵循的合规系统',
  `compliance_data` json NOT NULL COMMENT '存储合规系统所需的所有凭证数据 (哈希, 签名, QR等)',
  `payment_summary` json DEFAULT NULL COMMENT '支付方式快照 (JSON)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS统一票据主表 (多系统合规-最终版)';

--
-- 触发器 `pos_invoices`
--
DROP TRIGGER IF EXISTS `before_invoice_insert`;
DELIMITER $$
CREATE TRIGGER `before_invoice_insert` BEFORE INSERT ON `pos_invoices` FOR EACH ROW BEGIN
    DECLARE store_billing_system VARCHAR(20);

    -- 从 kds_stores 表中获取对应门店的开票策略
    SELECT billing_system INTO store_billing_system
    FROM kds_stores
    WHERE id = NEW.store_id;

    -- 如果策略为 'NONE'，则拒绝插入并报错
    IF store_billing_system = 'NONE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invoicing is disabled for this store (DB Trigger). Cannot insert into pos_invoices.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- 表的结构 `pos_invoice_counters`
--

DROP TABLE IF EXISTS `pos_invoice_counters`;
CREATE TABLE `pos_invoice_counters` (
  `id` int UNSIGNED NOT NULL,
  `invoice_prefix` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '门店票号前缀 (e.g., S1)',
  `series` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '完整系列号 (e.g., S1Y25)',
  `compliance_system` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '合规系统 (TICKETBAI, VERIFACTU, NONE)',
  `current_number` bigint UNSIGNED NOT NULL DEFAULT '0' COMMENT '当前已用的最大号码',
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS 票号原子计数器';

-- --------------------------------------------------------

--
-- 表的结构 `pos_invoice_items`
--

DROP TABLE IF EXISTS `pos_invoice_items`;
CREATE TABLE `pos_invoice_items` (
  `id` int UNSIGNED NOT NULL,
  `invoice_id` int UNSIGNED NOT NULL COMMENT '外键, 关联 pos_invoices.id',
  `menu_item_id` int UNSIGNED DEFAULT NULL COMMENT '关联 pos_menu_items.id',
  `variant_id` int UNSIGNED DEFAULT NULL COMMENT '关联 pos_item_variants.id',
  `item_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '(快照) 商品名称',
  `variant_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '(快照) 规格名称',
  `item_name_zh` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `item_name_es` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `variant_name_zh` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `variant_name_es` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `unit_price` decimal(10,2) NOT NULL COMMENT '(快照) 成交含税单价',
  `unit_taxable_base` decimal(10,2) NOT NULL COMMENT '(合规/快照) 税前单价',
  `vat_rate` decimal(5,2) NOT NULL COMMENT '(合规/快照) 增值税率',
  `vat_amount` decimal(10,2) NOT NULL COMMENT '(合规/快照) 此行项目总增值税额',
  `customizations` json DEFAULT NULL COMMENT '(快照) 个性化选项 (JSON)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS票据项目详情表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_item_variants`
--

DROP TABLE IF EXISTS `pos_item_variants`;
CREATE TABLE `pos_item_variants` (
  `id` int UNSIGNED NOT NULL,
  `menu_item_id` int UNSIGNED NOT NULL COMMENT '外键，关联 pos_menu_items.id',
  `cup_id` int UNSIGNED DEFAULT NULL COMMENT '关联 kds_cups.id',
  `variant_name_zh` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规格名 (中文), 如: 中杯',
  `variant_name_es` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规格名 (西语), 如: Mediano',
  `price_eur` decimal(10,2) NOT NULL COMMENT '该规格的最终售价',
  `is_default` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否为默认规格, 1=是, 0=否',
  `sort_order` int NOT NULL DEFAULT '99' COMMENT '规格的排序，越小越靠前',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS商品规格、价格与配方关联表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_members`
--

DROP TABLE IF EXISTS `pos_members`;
CREATE TABLE `pos_members` (
  `id` int UNSIGNED NOT NULL,
  `member_uuid` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '会员全局唯一ID',
  `phone_number` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '手机号 (主要查找依据)',
  `first_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '名字',
  `last_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '姓氏',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '邮箱',
  `birthdate` date DEFAULT NULL COMMENT '会员生日',
  `points_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '当前积分余额',
  `member_level_id` int UNSIGNED DEFAULT NULL COMMENT '外键, 关联 pos_member_levels.id',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '会员状态 (1=激活, 0=禁用)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='POS会员信息表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_member_issued_coupons`
--

DROP TABLE IF EXISTS `pos_member_issued_coupons`;
CREATE TABLE `pos_member_issued_coupons` (
  `id` int UNSIGNED NOT NULL,
  `member_id` int UNSIGNED NOT NULL COMMENT '外键, 关联 pos_members.id',
  `promotion_id` int UNSIGNED NOT NULL COMMENT '外键, 关联 pos_promotions.id (优惠活动定义)',
  `coupon_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '可选的唯一码 (若有)',
  `issued_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `expires_at` datetime(6) DEFAULT NULL,
  `status` enum('ACTIVE','USED','EXPIRED') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'ACTIVE' COMMENT '券状态',
  `used_at` datetime(6) DEFAULT NULL,
  `used_invoice_id` int UNSIGNED DEFAULT NULL COMMENT '外键, 关联 pos_invoices.id (在哪个订单使用)',
  `source` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '来源 (e.g., BIRTHDAY, LEVEL_UP, MANUAL)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='POS会员已发放优惠券实例表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_member_levels`
--

DROP TABLE IF EXISTS `pos_member_levels`;
CREATE TABLE `pos_member_levels` (
  `id` int UNSIGNED NOT NULL,
  `level_name_zh` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '等级名称 (中文)',
  `level_name_es` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '等级名称 (西文)',
  `points_threshold` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '达到此等级所需最低积分 (或累计消费)',
  `sort_order` int NOT NULL DEFAULT '10' COMMENT '等级排序 (数字越小越高)',
  `level_up_promo_id` int UNSIGNED DEFAULT NULL COMMENT '外键, 关联 pos_promotions.id (升级时赠送的活动)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='POS会员等级定义表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_member_points_log`
--

DROP TABLE IF EXISTS `pos_member_points_log`;
CREATE TABLE `pos_member_points_log` (
  `id` int UNSIGNED NOT NULL,
  `member_id` int UNSIGNED NOT NULL COMMENT '关联 pos_members.id',
  `invoice_id` int UNSIGNED DEFAULT NULL COMMENT '关联 pos_invoices.id (产生或消耗积分的订单)',
  `points_change` decimal(10,2) NOT NULL COMMENT '积分变动 (+表示获得, -表示消耗)',
  `reason_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '变动原因代码 (e.g., PURCHASE, REDEEM_DISCOUNT, MANUAL_ADJUST, BIRTHDAY)',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '备注 (例如: 兑换XX商品, 管理员调整)',
  `executed_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `user_id` int UNSIGNED DEFAULT NULL COMMENT '操作人ID (关联 cpsys_users.id 或 kds_users.id)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='POS会员积分流水记录表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_menu_items`
--

DROP TABLE IF EXISTS `pos_menu_items`;
CREATE TABLE `pos_menu_items` (
  `id` int UNSIGNED NOT NULL,
  `pos_category_id` int UNSIGNED NOT NULL COMMENT '外键，关联 pos_categories.id',
  `product_code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关联 kds_products 的 P-Code',
  `name_zh` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '商品销售名 (中文)',
  `name_es` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '商品销售名 (西语)',
  `description_zh` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商品描述 (中文)',
  `description_es` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商品描述 (西语)',
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '商品图片URL',
  `sort_order` int NOT NULL DEFAULT '99' COMMENT '在分类中的排序，越小越靠前',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否在POS上架, 1=是, 0=否',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS销售商品主表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_point_redemption_rules`
--

DROP TABLE IF EXISTS `pos_point_redemption_rules`;
CREATE TABLE `pos_point_redemption_rules` (
  `id` int NOT NULL,
  `rule_name_zh` varchar(100) NOT NULL,
  `rule_name_es` varchar(100) NOT NULL,
  `points_required` int UNSIGNED NOT NULL DEFAULT '0',
  `reward_type` enum('DISCOUNT_AMOUNT','SPECIFIC_PROMOTION') NOT NULL DEFAULT 'DISCOUNT_AMOUNT',
  `reward_value_decimal` decimal(10,2) DEFAULT NULL COMMENT 'Discount amount if reward_type is DISCOUNT_AMOUNT',
  `reward_promo_id` int UNSIGNED DEFAULT NULL COMMENT 'pos_promotions.id if reward_type is SPECIFIC_PROMOTION',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6),
  `deleted_at` datetime(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- 表的结构 `pos_print_templates`
--

DROP TABLE IF EXISTS `pos_print_templates`;
CREATE TABLE `pos_print_templates` (
  `id` int NOT NULL,
  `store_id` int UNSIGNED DEFAULT NULL COMMENT '所属门店ID, NULL表示全局通用',
  `template_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板名称 (e.g., Z-Out Report, Customer Receipt)',
  `template_type` enum('EOD_REPORT','RECEIPT','KITCHEN_ORDER','SHIFT_REPORT','CUP_STICKER','EXPIRY_LABEL','PASS_REDEMPTION_SLIP') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板类型',
  `template_content` json NOT NULL COMMENT '模板布局和内容的JSON定义',
  `physical_size` varchar(20) DEFAULT NULL COMMENT '物理尺寸 (e.g., 50x30, 80mm)',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='POS打印模板配置表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_product_availability`
--

DROP TABLE IF EXISTS `pos_product_availability`;
CREATE TABLE `pos_product_availability` (
  `id` int UNSIGNED NOT NULL,
  `store_id` int UNSIGNED NOT NULL COMMENT '关联 kds_stores.id',
  `menu_item_id` int UNSIGNED NOT NULL COMMENT '关联 pos_menu_items.id',
  `is_sold_out` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否估清 (1=估清, 0=可售)',
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS 门店商品估清状态表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_product_tag_map`
--

DROP TABLE IF EXISTS `pos_product_tag_map`;
CREATE TABLE `pos_product_tag_map` (
  `product_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pos_menu_items.id',
  `tag_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pos_tags.tag_id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: POS 商品与标签映射表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_promotions`
--

DROP TABLE IF EXISTS `pos_promotions`;
CREATE TABLE `pos_promotions` (
  `id` int UNSIGNED NOT NULL,
  `promo_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规则名称, e.g., 珍珠奶茶买一送一',
  `promo_priority` int NOT NULL DEFAULT '10' COMMENT '优先级, 数字越小越高',
  `promo_exclusive` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否排他, 1=是 (若应用此规则,则不再计算其他规则)',
  `promo_trigger_type` enum('AUTO_APPLY','COUPON_CODE') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '触发类型: AUTO_APPLY=自动应用, COUPON_CODE=需优惠码',
  `promo_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `promo_conditions` json NOT NULL COMMENT '触发条件 (JSON)',
  `promo_actions` json NOT NULL COMMENT '执行动作 (JSON)',
  `promo_start_date` datetime(6) DEFAULT NULL,
  `promo_end_date` datetime(6) DEFAULT NULL,
  `promo_is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS促销规则表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_settings`
--

DROP TABLE IF EXISTS `pos_settings`;
CREATE TABLE `pos_settings` (
  `setting_key` varchar(50) NOT NULL,
  `setting_value` text NOT NULL,
  `description` text,
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- 表的结构 `pos_shifts`
--

DROP TABLE IF EXISTS `pos_shifts`;
CREATE TABLE `pos_shifts` (
  `id` int UNSIGNED NOT NULL,
  `shift_uuid` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '班次全局唯一ID',
  `store_id` int UNSIGNED NOT NULL COMMENT '所属门店ID',
  `user_id` int UNSIGNED NOT NULL COMMENT '当班收银员ID',
  `start_time` datetime(6) NOT NULL,
  `end_time` datetime(6) DEFAULT NULL,
  `status` enum('ACTIVE','ENDED','FORCE_CLOSED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE' COMMENT '班次状态: ACTIVE=进行中, ENDED=已结束, FORCE_CLOSED=被强制关闭',
  `starting_float` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '初始备用金',
  `counted_cash` decimal(10,2) DEFAULT NULL COMMENT '交班时清点的现金金额',
  `expected_cash` decimal(10,2) DEFAULT NULL COMMENT '系统计算的应有现金',
  `cash_variance` decimal(10,2) DEFAULT NULL COMMENT '现金差异 (清点 - 系统)',
  `payment_summary` json DEFAULT NULL COMMENT '此班次内各支付方式的汇总',
  `admin_reviewed` tinyint(1) NOT NULL DEFAULT '0',
  `sales_summary` json DEFAULT NULL COMMENT '此班次内的销售总览 (总销售, 折扣等)',
  `created_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='POS交接班记录表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_tags`
--

DROP TABLE IF EXISTS `pos_tags`;
CREATE TABLE `pos_tags` (
  `tag_id` int UNSIGNED NOT NULL,
  `tag_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签唯一码 (e.g., pass_eligible_beverage)',
  `tag_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签说明'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: POS 商品标签定义表';

-- --------------------------------------------------------

--
-- 表的结构 `pos_vr_counters`
--

DROP TABLE IF EXISTS `pos_vr_counters`;
CREATE TABLE `pos_vr_counters` (
  `id` int UNSIGNED NOT NULL,
  `vr_prefix` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '门店VR前缀 (e.g., S1-VR)',
  `series` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '完整系列号 (e.g., S1-VRY25)',
  `current_number` bigint UNSIGNED NOT NULL DEFAULT '0' COMMENT '当前已用的最大号码',
  `updated_at` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: POS 售卡(VR)票号原子计数器';

-- --------------------------------------------------------

--
-- 表的结构 `topup_orders`
--

DROP TABLE IF EXISTS `topup_orders`;
CREATE TABLE `topup_orders` (
  `topup_order_id` int UNSIGNED NOT NULL COMMENT '售卡订单ID',
  `pass_plan_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pass_plans.pass_plan_id',
  `member_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 pos_members.id (购买会员)',
  `quantity` int UNSIGNED NOT NULL DEFAULT '1' COMMENT '购买数量 (默认为1)',
  `amount_total` decimal(10,2) NOT NULL COMMENT '总支付金额 (合同负债)',
  `store_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 kds_stores.id (销售门店)',
  `device_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '销售设备ID',
  `sale_user_id` int UNSIGNED NOT NULL COMMENT 'FK, 关联 kds_users.id (销售员工)',
  `sale_time` datetime(6) NOT NULL DEFAULT (utc_timestamp(6)),
  `voucher_series` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'VR' COMMENT '非税凭证系列 (VR) [cite: 17, 33]',
  `voucher_number` bigint UNSIGNED NOT NULL COMMENT '非税凭证连续编号 [cite: 33]',
  `review_status` enum('pending','confirmed','rejected','refunded') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending' COMMENT '审核状态 [cite: 33]',
  `reviewed_by_user_id` int UNSIGNED DEFAULT NULL COMMENT 'FK, 关联 cpsys_users.id (审核人)',
  `reviewed_at` datetime(6) DEFAULT NULL,
  `review_note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '审核备注 [cite: 33]'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='B1.1: 次卡售卡订单表 (VR非税)';

--
-- 转储表的索引
--

--
-- 表的索引 `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_actor` (`actor_user_id`,`actor_type`),
  ADD KEY `idx_target` (`target_type`,`target_id`);

--
-- 表的索引 `cpsys_roles`
--
ALTER TABLE `cpsys_roles`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `cpsys_users`
--
ALTER TABLE `cpsys_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `role_id` (`role_id`),
  ADD KEY `idx_cpsys_users_email` (`email`);

--
-- 表的索引 `expsys_store_stock`
--
ALTER TABLE `expsys_store_stock`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `store_material` (`store_id`,`material_id`);

--
-- 表的索引 `expsys_warehouse_stock`
--
ALTER TABLE `expsys_warehouse_stock`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `material_id` (`material_id`);

--
-- 表的索引 `kds_cups`
--
ALTER TABLE `kds_cups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `cup_code` (`cup_code`);

--
-- 表的索引 `kds_global_adjustment_rules`
--
ALTER TABLE `kds_global_adjustment_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_priority_active` (`priority`,`is_active`),
  ADD KEY `fk_global_cond_cup` (`cond_cup_id`),
  ADD KEY `fk_global_cond_ice` (`cond_ice_id`),
  ADD KEY `fk_global_cond_sweet` (`cond_sweet_id`),
  ADD KEY `fk_global_cond_material` (`cond_material_id`),
  ADD KEY `fk_global_action_material` (`action_material_id`),
  ADD KEY `fk_global_action_unit` (`action_unit_id`);

--
-- 表的索引 `kds_ice_options`
--
ALTER TABLE `kds_ice_options`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ice_code` (`ice_code`);

--
-- 表的索引 `kds_ice_option_translations`
--
ALTER TABLE `kds_ice_option_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_ice_option_language` (`ice_option_id`,`language_code`);

--
-- 表的索引 `kds_materials`
--
ALTER TABLE `kds_materials`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `material_code` (`material_code`),
  ADD KEY `fk_material_large_unit` (`large_unit_id`);

--
-- 表的索引 `kds_material_expiries`
--
ALTER TABLE `kds_material_expiries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `material_id` (`material_id`),
  ADD KEY `store_id` (`store_id`),
  ADD KEY `status` (`status`),
  ADD KEY `expires_at` (`expires_at`);

--
-- 表的索引 `kds_material_translations`
--
ALTER TABLE `kds_material_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `material_language_unique` (`material_id`,`language_code`);

--
-- 表的索引 `kds_products`
--
ALTER TABLE `kds_products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_product_code` (`product_code`,`is_deleted_flag`),
  ADD KEY `status_id` (`status_id`),
  ADD KEY `category_id` (`category_id`);

--
-- 表的索引 `kds_product_adjustments`
--
ALTER TABLE `kds_product_adjustments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_product_option` (`product_id`,`option_type`,`option_id`),
  ADD KEY `material_id` (`material_id`),
  ADD KEY `unit_id` (`unit_id`);

--
-- 表的索引 `kds_product_categories`
--
ALTER TABLE `kds_product_categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `parent_id` (`parent_id`);

--
-- 表的索引 `kds_product_category_translations`
--
ALTER TABLE `kds_product_category_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `category_language_unique` (`category_id`,`language_code`);

--
-- 表的索引 `kds_product_ice_options`
--
ALTER TABLE `kds_product_ice_options`
  ADD PRIMARY KEY (`product_id`,`ice_option_id`),
  ADD KEY `ice_option_id` (`ice_option_id`);

--
-- 表的索引 `kds_product_recipes`
--
ALTER TABLE `kds_product_recipes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `material_id` (`material_id`),
  ADD KEY `unit_id` (`unit_id`);

--
-- 表的索引 `kds_product_statuses`
--
ALTER TABLE `kds_product_statuses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `status_code` (`status_code`);

--
-- 表的索引 `kds_product_sweetness_options`
--
ALTER TABLE `kds_product_sweetness_options`
  ADD PRIMARY KEY (`product_id`,`sweetness_option_id`),
  ADD KEY `sweetness_option_id` (`sweetness_option_id`);

--
-- 表的索引 `kds_product_translations`
--
ALTER TABLE `kds_product_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `product_language_unique` (`product_id`,`language_code`);

--
-- 表的索引 `kds_recipe_adjustments`
--
ALTER TABLE `kds_recipe_adjustments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_product_conditions` (`product_id`,`cup_id`,`sweetness_option_id`,`ice_option_id`),
  ADD KEY `fk_adj_material` (`material_id`),
  ADD KEY `fk_adj_cup` (`cup_id`),
  ADD KEY `fk_adj_sweetness` (`sweetness_option_id`),
  ADD KEY `fk_adj_ice` (`ice_option_id`),
  ADD KEY `fk_adj_unit` (`unit_id`);

--
-- 表的索引 `kds_sop_query_rules`
--
ALTER TABLE `kds_sop_query_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_store_priority` (`store_id`,`priority`,`is_active`);

--
-- 表的索引 `kds_stores`
--
ALTER TABLE `kds_stores`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `store_code` (`store_code`),
  ADD UNIQUE KEY `uniq_invoice_prefix` (`invoice_prefix`);

--
-- 表的索引 `kds_sweetness_options`
--
ALTER TABLE `kds_sweetness_options`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sweetness_code` (`sweetness_code`);

--
-- 表的索引 `kds_sweetness_option_translations`
--
ALTER TABLE `kds_sweetness_option_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_sweetness_option_language` (`sweetness_option_id`,`language_code`);

--
-- 表的索引 `kds_units`
--
ALTER TABLE `kds_units`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unit_code` (`unit_code`);

--
-- 表的索引 `kds_unit_translations`
--
ALTER TABLE `kds_unit_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unit_language_unique` (`unit_id`,`language_code`);

--
-- 表的索引 `kds_users`
--
ALTER TABLE `kds_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_store_username` (`store_id`,`username`,`deleted_at`);

--
-- 表的索引 `member_passes`
--
ALTER TABLE `member_passes`
  ADD PRIMARY KEY (`member_pass_id`),
  ADD UNIQUE KEY `uniq_member_plan` (`member_id`,`pass_plan_id`),
  ADD KEY `idx_member_id_status` (`member_id`,`status`),
  ADD KEY `idx_pass_plan_id` (`pass_plan_id`),
  ADD KEY `idx_topup_order_id` (`topup_order_id`);

--
-- 表的索引 `pass_daily_usage`
--
ALTER TABLE `pass_daily_usage`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_pass_date` (`member_pass_id`,`usage_date`);

--
-- 表的索引 `pass_plans`
--
ALTER TABLE `pass_plans`
  ADD PRIMARY KEY (`pass_plan_id`);

--
-- 表的索引 `pass_redemptions`
--
ALTER TABLE `pass_redemptions`
  ADD PRIMARY KEY (`redemption_id`),
  ADD KEY `idx_batch_id` (`batch_id`),
  ADD KEY `idx_member_pass_id` (`member_pass_id`),
  ADD KEY `idx_order_id` (`order_id`),
  ADD KEY `idx_order_item_id` (`order_item_id`);

--
-- 表的索引 `pass_redemption_batches`
--
ALTER TABLE `pass_redemption_batches`
  ADD PRIMARY KEY (`batch_id`),
  ADD UNIQUE KEY `idx_member_pass_idempotency` (`member_pass_id`,`idempotency_key`),
  ADD KEY `idx_member_pass_id` (`member_pass_id`),
  ADD KEY `idx_order_id` (`order_id`),
  ADD KEY `fk_batch_store` (`store_id`),
  ADD KEY `fk_batch_user` (`cashier_user_id`);

--
-- 表的索引 `pos_addons`
--
ALTER TABLE `pos_addons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_code_deleted` (`addon_code`,`deleted_at`),
  ADD KEY `idx_material_id` (`material_id`);

--
-- 表的索引 `pos_addon_tag_map`
--
ALTER TABLE `pos_addon_tag_map`
  ADD PRIMARY KEY (`addon_id`,`tag_id`),
  ADD KEY `fk_addon_map_tag` (`tag_id`);

--
-- 表的索引 `pos_categories`
--
ALTER TABLE `pos_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `category_code` (`category_code`);

--
-- 表的索引 `pos_coupons`
--
ALTER TABLE `pos_coupons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_coupon_code` (`coupon_code`),
  ADD KEY `idx_promotion_id` (`promotion_id`);

--
-- 表的索引 `pos_daily_tracking`
--
ALTER TABLE `pos_daily_tracking`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `store_id` (`store_id`);

--
-- 表的索引 `pos_eod_records`
--
ALTER TABLE `pos_eod_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_store_time` (`store_id`,`started_at`,`ended_at`);

--
-- 表的索引 `pos_eod_reports`
--
ALTER TABLE `pos_eod_reports`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `store_date_unique` (`store_id`,`report_date`);

--
-- 表的索引 `pos_held_orders`
--
ALTER TABLE `pos_held_orders`
  ADD PRIMARY KEY (`id`);

--
-- 表的索引 `pos_invoices`
--
ALTER TABLE `pos_invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_issuer_series_number` (`issuer_nif`,`series`,`number`,`compliance_system`),
  ADD KEY `idx_store_id` (`store_id`),
  ADD KEY `idx_issued_at` (`issued_at`),
  ADD KEY `idx_references_invoice_id` (`references_invoice_id`),
  ADD KEY `fk_invoice_shift` (`shift_id`);

--
-- 表的索引 `pos_invoice_counters`
--
ALTER TABLE `pos_invoice_counters`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_prefix_series_system` (`invoice_prefix`,`series`,`compliance_system`);

--
-- 表的索引 `pos_invoice_items`
--
ALTER TABLE `pos_invoice_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_invoice_id` (`invoice_id`),
  ADD KEY `idx_menu_item_id` (`menu_item_id`),
  ADD KEY `idx_variant_id` (`variant_id`);

--
-- 表的索引 `pos_item_variants`
--
ALTER TABLE `pos_item_variants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_menu_item_id` (`menu_item_id`),
  ADD KEY `fk_variant_cup` (`cup_id`);

--
-- 表的索引 `pos_members`
--
ALTER TABLE `pos_members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `member_uuid_unique` (`member_uuid`),
  ADD UNIQUE KEY `phone_number_unique` (`phone_number`),
  ADD KEY `idx_phone_number` (`phone_number`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_birthdate` (`birthdate`),
  ADD KEY `idx_member_level_id` (`member_level_id`);

--
-- 表的索引 `pos_member_issued_coupons`
--
ALTER TABLE `pos_member_issued_coupons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `coupon_code_unique` (`coupon_code`),
  ADD KEY `idx_member_id_status_expires` (`member_id`,`status`,`expires_at`),
  ADD KEY `idx_promotion_id` (`promotion_id`),
  ADD KEY `idx_used_invoice_id` (`used_invoice_id`);

--
-- 表的索引 `pos_member_levels`
--
ALTER TABLE `pos_member_levels`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_points_threshold` (`points_threshold`),
  ADD KEY `idx_sort_order` (`sort_order`);

--
-- 表的索引 `pos_member_points_log`
--
ALTER TABLE `pos_member_points_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_member_id` (`member_id`),
  ADD KEY `idx_invoice_id` (`invoice_id`);

--
-- 表的索引 `pos_menu_items`
--
ALTER TABLE `pos_menu_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pos_category_id` (`pos_category_id`),
  ADD KEY `idx_sort_order` (`sort_order`);

--
-- 表的索引 `pos_point_redemption_rules`
--
ALTER TABLE `pos_point_redemption_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_points_required` (`points_required`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `reward_promo_id` (`reward_promo_id`);

--
-- 表的索引 `pos_print_templates`
--
ALTER TABLE `pos_print_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_store_type` (`store_id`,`template_type`);

--
-- 表的索引 `pos_product_availability`
--
ALTER TABLE `pos_product_availability`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `store_item` (`store_id`,`menu_item_id`),
  ADD KEY `idx_store_id` (`store_id`),
  ADD KEY `idx_menu_item_id` (`menu_item_id`);

--
-- 表的索引 `pos_product_tag_map`
--
ALTER TABLE `pos_product_tag_map`
  ADD PRIMARY KEY (`product_id`,`tag_id`),
  ADD KEY `fk_tag_map_tag` (`tag_id`);

--
-- 表的索引 `pos_promotions`
--
ALTER TABLE `pos_promotions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `promo_code_unique` (`promo_code`),
  ADD KEY `idx_promo_active_dates` (`promo_is_active`,`promo_start_date`,`promo_end_date`);

--
-- 表的索引 `pos_settings`
--
ALTER TABLE `pos_settings`
  ADD PRIMARY KEY (`setting_key`);

--
-- 表的索引 `pos_shifts`
--
ALTER TABLE `pos_shifts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_store_user_status` (`store_id`,`user_id`,`status`),
  ADD KEY `idx_status_reviewed` (`status`,`admin_reviewed`);

--
-- 表的索引 `pos_tags`
--
ALTER TABLE `pos_tags`
  ADD PRIMARY KEY (`tag_id`),
  ADD UNIQUE KEY `uniq_tag_code` (`tag_code`);

--
-- 表的索引 `pos_vr_counters`
--
ALTER TABLE `pos_vr_counters`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_prefix_series` (`vr_prefix`,`series`);

--
-- 表的索引 `topup_orders`
--
ALTER TABLE `topup_orders`
  ADD PRIMARY KEY (`topup_order_id`),
  ADD UNIQUE KEY `uniq_vr_series_number` (`voucher_series`,`voucher_number`),
  ADD KEY `idx_pass_plan_id` (`pass_plan_id`),
  ADD KEY `idx_member_id` (`member_id`),
  ADD KEY `idx_store_id` (`store_id`),
  ADD KEY `idx_sale_user_id` (`sale_user_id`),
  ADD KEY `idx_reviewed_by_user_id` (`reviewed_by_user_id`);

--
-- 在导出的表使用AUTO_INCREMENT
--

--
-- 使用表AUTO_INCREMENT `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `log_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `cpsys_roles`
--
ALTER TABLE `cpsys_roles`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `cpsys_users`
--
ALTER TABLE `cpsys_users`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `expsys_store_stock`
--
ALTER TABLE `expsys_store_stock`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `expsys_warehouse_stock`
--
ALTER TABLE `expsys_warehouse_stock`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_cups`
--
ALTER TABLE `kds_cups`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_global_adjustment_rules`
--
ALTER TABLE `kds_global_adjustment_rules`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_ice_options`
--
ALTER TABLE `kds_ice_options`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_ice_option_translations`
--
ALTER TABLE `kds_ice_option_translations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_materials`
--
ALTER TABLE `kds_materials`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_material_expiries`
--
ALTER TABLE `kds_material_expiries`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_material_translations`
--
ALTER TABLE `kds_material_translations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_products`
--
ALTER TABLE `kds_products`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_product_adjustments`
--
ALTER TABLE `kds_product_adjustments`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_product_categories`
--
ALTER TABLE `kds_product_categories`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_product_category_translations`
--
ALTER TABLE `kds_product_category_translations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_product_recipes`
--
ALTER TABLE `kds_product_recipes`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_product_statuses`
--
ALTER TABLE `kds_product_statuses`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_product_translations`
--
ALTER TABLE `kds_product_translations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_recipe_adjustments`
--
ALTER TABLE `kds_recipe_adjustments`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_sop_query_rules`
--
ALTER TABLE `kds_sop_query_rules`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_stores`
--
ALTER TABLE `kds_stores`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_sweetness_options`
--
ALTER TABLE `kds_sweetness_options`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_sweetness_option_translations`
--
ALTER TABLE `kds_sweetness_option_translations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_units`
--
ALTER TABLE `kds_units`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_unit_translations`
--
ALTER TABLE `kds_unit_translations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `kds_users`
--
ALTER TABLE `kds_users`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `member_passes`
--
ALTER TABLE `member_passes`
  MODIFY `member_pass_id` int UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '会员持卡ID';

--
-- 使用表AUTO_INCREMENT `pass_daily_usage`
--
ALTER TABLE `pass_daily_usage`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pass_plans`
--
ALTER TABLE `pass_plans`
  MODIFY `pass_plan_id` int UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '次卡方案ID';

--
-- 使用表AUTO_INCREMENT `pass_redemptions`
--
ALTER TABLE `pass_redemptions`
  MODIFY `redemption_id` int UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '核销明细ID (每杯)';

--
-- 使用表AUTO_INCREMENT `pass_redemption_batches`
--
ALTER TABLE `pass_redemption_batches`
  MODIFY `batch_id` int UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '核销批次ID (对应一单)';

--
-- 使用表AUTO_INCREMENT `pos_addons`
--
ALTER TABLE `pos_addons`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_categories`
--
ALTER TABLE `pos_categories`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_coupons`
--
ALTER TABLE `pos_coupons`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_daily_tracking`
--
ALTER TABLE `pos_daily_tracking`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_eod_records`
--
ALTER TABLE `pos_eod_records`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_eod_reports`
--
ALTER TABLE `pos_eod_reports`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_held_orders`
--
ALTER TABLE `pos_held_orders`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_invoices`
--
ALTER TABLE `pos_invoices`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_invoice_counters`
--
ALTER TABLE `pos_invoice_counters`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_invoice_items`
--
ALTER TABLE `pos_invoice_items`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_item_variants`
--
ALTER TABLE `pos_item_variants`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_members`
--
ALTER TABLE `pos_members`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_member_issued_coupons`
--
ALTER TABLE `pos_member_issued_coupons`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_member_levels`
--
ALTER TABLE `pos_member_levels`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_member_points_log`
--
ALTER TABLE `pos_member_points_log`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_menu_items`
--
ALTER TABLE `pos_menu_items`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_point_redemption_rules`
--
ALTER TABLE `pos_point_redemption_rules`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_print_templates`
--
ALTER TABLE `pos_print_templates`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_product_availability`
--
ALTER TABLE `pos_product_availability`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_promotions`
--
ALTER TABLE `pos_promotions`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_shifts`
--
ALTER TABLE `pos_shifts`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_tags`
--
ALTER TABLE `pos_tags`
  MODIFY `tag_id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `pos_vr_counters`
--
ALTER TABLE `pos_vr_counters`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- 使用表AUTO_INCREMENT `topup_orders`
--
ALTER TABLE `topup_orders`
  MODIFY `topup_order_id` int UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '售卡订单ID';

--
-- 限制导出的表
--

--
-- 限制表 `cpsys_users`
--
ALTER TABLE `cpsys_users`
  ADD CONSTRAINT `cpsys_users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `cpsys_roles` (`id`) ON DELETE RESTRICT;

--
-- 限制表 `kds_global_adjustment_rules`
--
ALTER TABLE `kds_global_adjustment_rules`
  ADD CONSTRAINT `fk_global_action_material` FOREIGN KEY (`action_material_id`) REFERENCES `kds_materials` (`id`),
  ADD CONSTRAINT `fk_global_action_unit` FOREIGN KEY (`action_unit_id`) REFERENCES `kds_units` (`id`),
  ADD CONSTRAINT `fk_global_cond_cup` FOREIGN KEY (`cond_cup_id`) REFERENCES `kds_cups` (`id`),
  ADD CONSTRAINT `fk_global_cond_ice` FOREIGN KEY (`cond_ice_id`) REFERENCES `kds_ice_options` (`id`),
  ADD CONSTRAINT `fk_global_cond_material` FOREIGN KEY (`cond_material_id`) REFERENCES `kds_materials` (`id`),
  ADD CONSTRAINT `fk_global_cond_sweet` FOREIGN KEY (`cond_sweet_id`) REFERENCES `kds_sweetness_options` (`id`);

--
-- 限制表 `kds_ice_option_translations`
--
ALTER TABLE `kds_ice_option_translations`
  ADD CONSTRAINT `kds_ice_option_translations_ibfk_1` FOREIGN KEY (`ice_option_id`) REFERENCES `kds_ice_options` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_materials`
--
ALTER TABLE `kds_materials`
  ADD CONSTRAINT `fk_material_large_unit` FOREIGN KEY (`large_unit_id`) REFERENCES `kds_units` (`id`) ON DELETE SET NULL;

--
-- 限制表 `kds_material_translations`
--
ALTER TABLE `kds_material_translations`
  ADD CONSTRAINT `kds_material_translations_ibfk_1` FOREIGN KEY (`material_id`) REFERENCES `kds_materials` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_products`
--
ALTER TABLE `kds_products`
  ADD CONSTRAINT `kds_products_ibfk_2` FOREIGN KEY (`status_id`) REFERENCES `kds_product_statuses` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `kds_products_ibfk_3` FOREIGN KEY (`category_id`) REFERENCES `kds_product_categories` (`id`) ON DELETE SET NULL;

--
-- 限制表 `kds_product_adjustments`
--
ALTER TABLE `kds_product_adjustments`
  ADD CONSTRAINT `kds_product_adjustments_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `kds_products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `kds_product_adjustments_ibfk_2` FOREIGN KEY (`material_id`) REFERENCES `kds_materials` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `kds_product_adjustments_ibfk_3` FOREIGN KEY (`unit_id`) REFERENCES `kds_units` (`id`) ON DELETE RESTRICT;

--
-- 限制表 `kds_product_categories`
--
ALTER TABLE `kds_product_categories`
  ADD CONSTRAINT `kds_product_categories_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `kds_product_categories` (`id`) ON DELETE SET NULL;

--
-- 限制表 `kds_product_category_translations`
--
ALTER TABLE `kds_product_category_translations`
  ADD CONSTRAINT `kds_product_category_translations_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `kds_product_categories` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_product_ice_options`
--
ALTER TABLE `kds_product_ice_options`
  ADD CONSTRAINT `kds_product_ice_options_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `kds_products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `kds_product_ice_options_ibfk_2` FOREIGN KEY (`ice_option_id`) REFERENCES `kds_ice_options` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_product_recipes`
--
ALTER TABLE `kds_product_recipes`
  ADD CONSTRAINT `kds_product_recipes_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `kds_products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `kds_product_recipes_ibfk_2` FOREIGN KEY (`material_id`) REFERENCES `kds_materials` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `kds_product_recipes_ibfk_3` FOREIGN KEY (`unit_id`) REFERENCES `kds_units` (`id`) ON DELETE RESTRICT;

--
-- 限制表 `kds_product_sweetness_options`
--
ALTER TABLE `kds_product_sweetness_options`
  ADD CONSTRAINT `kds_product_sweetness_options_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `kds_products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `kds_product_sweetness_options_ibfk_2` FOREIGN KEY (`sweetness_option_id`) REFERENCES `kds_sweetness_options` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_product_translations`
--
ALTER TABLE `kds_product_translations`
  ADD CONSTRAINT `kds_product_translations_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `kds_products` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_recipe_adjustments`
--
ALTER TABLE `kds_recipe_adjustments`
  ADD CONSTRAINT `fk_adj_cup` FOREIGN KEY (`cup_id`) REFERENCES `kds_cups` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_adj_ice` FOREIGN KEY (`ice_option_id`) REFERENCES `kds_ice_options` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_adj_material` FOREIGN KEY (`material_id`) REFERENCES `kds_materials` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_adj_product` FOREIGN KEY (`product_id`) REFERENCES `kds_products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_adj_sweetness` FOREIGN KEY (`sweetness_option_id`) REFERENCES `kds_sweetness_options` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_adj_unit` FOREIGN KEY (`unit_id`) REFERENCES `kds_units` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_sweetness_option_translations`
--
ALTER TABLE `kds_sweetness_option_translations`
  ADD CONSTRAINT `kds_sweetness_option_translations_ibfk_1` FOREIGN KEY (`sweetness_option_id`) REFERENCES `kds_sweetness_options` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_unit_translations`
--
ALTER TABLE `kds_unit_translations`
  ADD CONSTRAINT `kds_unit_translations_ibfk_1` FOREIGN KEY (`unit_id`) REFERENCES `kds_units` (`id`) ON DELETE CASCADE;

--
-- 限制表 `kds_users`
--
ALTER TABLE `kds_users`
  ADD CONSTRAINT `kds_users_ibfk_1` FOREIGN KEY (`store_id`) REFERENCES `kds_stores` (`id`) ON DELETE CASCADE;

--
-- 限制表 `member_passes`
--
ALTER TABLE `member_passes`
  ADD CONSTRAINT `fk_pass_member` FOREIGN KEY (`member_id`) REFERENCES `pos_members` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_pass_plan` FOREIGN KEY (`pass_plan_id`) REFERENCES `pass_plans` (`pass_plan_id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_pass_topup_order` FOREIGN KEY (`topup_order_id`) REFERENCES `topup_orders` (`topup_order_id`) ON DELETE CASCADE;

--
-- 限制表 `pass_daily_usage`
--
ALTER TABLE `pass_daily_usage`
  ADD CONSTRAINT `fk_usage_pass` FOREIGN KEY (`member_pass_id`) REFERENCES `member_passes` (`member_pass_id`) ON DELETE CASCADE;

--
-- 限制表 `pass_redemptions`
--
ALTER TABLE `pass_redemptions`
  ADD CONSTRAINT `fk_redemption_batch` FOREIGN KEY (`batch_id`) REFERENCES `pass_redemption_batches` (`batch_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_redemption_invoice` FOREIGN KEY (`order_id`) REFERENCES `pos_invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_redemption_invoice_item` FOREIGN KEY (`order_item_id`) REFERENCES `pos_invoice_items` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_redemption_pass` FOREIGN KEY (`member_pass_id`) REFERENCES `member_passes` (`member_pass_id`) ON DELETE RESTRICT;

--
-- 限制表 `pass_redemption_batches`
--
ALTER TABLE `pass_redemption_batches`
  ADD CONSTRAINT `fk_batch_invoice` FOREIGN KEY (`order_id`) REFERENCES `pos_invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_batch_pass` FOREIGN KEY (`member_pass_id`) REFERENCES `member_passes` (`member_pass_id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_batch_store` FOREIGN KEY (`store_id`) REFERENCES `kds_stores` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_batch_user` FOREIGN KEY (`cashier_user_id`) REFERENCES `kds_users` (`id`) ON DELETE RESTRICT;

--
-- 限制表 `pos_addon_tag_map`
--
ALTER TABLE `pos_addon_tag_map`
  ADD CONSTRAINT `fk_addon_map_addon` FOREIGN KEY (`addon_id`) REFERENCES `pos_addons` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_addon_map_tag` FOREIGN KEY (`tag_id`) REFERENCES `pos_tags` (`tag_id`) ON DELETE CASCADE;

--
-- 限制表 `pos_invoices`
--
ALTER TABLE `pos_invoices`
  ADD CONSTRAINT `fk_invoice_shift` FOREIGN KEY (`shift_id`) REFERENCES `pos_shifts` (`id`) ON DELETE SET NULL;

--
-- 限制表 `pos_item_variants`
--
ALTER TABLE `pos_item_variants`
  ADD CONSTRAINT `fk_variant_cup` FOREIGN KEY (`cup_id`) REFERENCES `kds_cups` (`id`) ON DELETE SET NULL;

--
-- 限制表 `pos_members`
--
ALTER TABLE `pos_members`
  ADD CONSTRAINT `fk_member_level` FOREIGN KEY (`member_level_id`) REFERENCES `pos_member_levels` (`id`) ON DELETE SET NULL;

--
-- 限制表 `pos_member_issued_coupons`
--
ALTER TABLE `pos_member_issued_coupons`
  ADD CONSTRAINT `fk_issued_coupon_member` FOREIGN KEY (`member_id`) REFERENCES `pos_members` (`id`) ON DELETE CASCADE;

--
-- 限制表 `pos_member_points_log`
--
ALTER TABLE `pos_member_points_log`
  ADD CONSTRAINT `fk_member_points_member` FOREIGN KEY (`member_id`) REFERENCES `pos_members` (`id`) ON DELETE CASCADE;

--
-- 限制表 `pos_point_redemption_rules`
--
ALTER TABLE `pos_point_redemption_rules`
  ADD CONSTRAINT `pos_point_redemption_rules_ibfk_1` FOREIGN KEY (`reward_promo_id`) REFERENCES `pos_promotions` (`id`) ON DELETE SET NULL;

--
-- 限制表 `pos_product_tag_map`
--
ALTER TABLE `pos_product_tag_map`
  ADD CONSTRAINT `fk_tag_map_product` FOREIGN KEY (`product_id`) REFERENCES `pos_menu_items` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_tag_map_tag` FOREIGN KEY (`tag_id`) REFERENCES `pos_tags` (`tag_id`) ON DELETE CASCADE;

--
-- 限制表 `topup_orders`
--
ALTER TABLE `topup_orders`
  ADD CONSTRAINT `fk_topup_member` FOREIGN KEY (`member_id`) REFERENCES `pos_members` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_topup_plan` FOREIGN KEY (`pass_plan_id`) REFERENCES `pass_plans` (`pass_plan_id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_topup_reviewer` FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `cpsys_users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_topup_store` FOREIGN KEY (`store_id`) REFERENCES `kds_stores` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_topup_user` FOREIGN KEY (`sale_user_id`) REFERENCES `kds_users` (`id`) ON DELETE RESTRICT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
