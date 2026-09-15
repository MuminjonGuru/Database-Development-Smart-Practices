-- ============================================================================
-- File: 06_reset_dev_transactional_data.sql
-- Purpose:
--   Remove generated customers, orders, and order items from retail_ops_dev.
--
-- The script preserves:
--   sales.categories
--   sales.products
--   all schemas, constraints, indexes, and views
--
-- Run this before rerunning 04_populate_dev_demo_data.sql.
-- ============================================================================

BEGIN;

DO $$
BEGIN
    IF current_database() <> 'retail_ops_dev' THEN
        RAISE EXCEPTION
            'This script must be run in retail_ops_dev. Current database: %',
            current_database();
    END IF;
END
$$;

TRUNCATE TABLE
    sales.order_items,
    sales.orders,
    sales.customers
RESTART IDENTITY;

COMMIT;

ANALYZE sales.customers;
ANALYZE sales.orders;
ANALYZE sales.order_items;

SELECT
    (SELECT COUNT(*) FROM sales.customers) AS customers_remaining,
    (SELECT COUNT(*) FROM sales.orders) AS orders_remaining,
    (SELECT COUNT(*) FROM sales.order_items) AS order_items_remaining,
    (SELECT COUNT(*) FROM sales.products) AS products_preserved,
    (SELECT COUNT(*) FROM sales.categories) AS categories_preserved;
