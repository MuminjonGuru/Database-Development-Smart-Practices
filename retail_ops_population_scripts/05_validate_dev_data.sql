-- ============================================================================
-- File: 05_validate_dev_data.sql
-- Purpose:
--   Validate row counts, distributions, date ranges, relationships, and the
--   reporting view after the development dataset has been generated.
--
-- Run ONLY in:
--   retail_ops_dev
-- ============================================================================

DO $$
BEGIN
    IF current_database() <> 'retail_ops_dev' THEN
        RAISE EXCEPTION
            'This script must be run in retail_ops_dev. Current database: %',
            current_database();
    END IF;
END
$$;

-- --------------------------------------------------------------------------
-- 1. Core row counts
-- --------------------------------------------------------------------------

SELECT
    'categories' AS object_name,
    COUNT(*) AS actual_rows,
    12::BIGINT AS expected_rows
FROM sales.categories

UNION ALL

SELECT
    'products',
    COUNT(*),
    144::BIGINT
FROM sales.products

UNION ALL

SELECT
    'customers',
    COUNT(*),
    25000::BIGINT
FROM sales.customers

UNION ALL

SELECT
    'orders',
    COUNT(*),
    300000::BIGINT
FROM sales.orders

UNION ALL

SELECT
    'order_items',
    COUNT(*),
    900000::BIGINT
FROM sales.order_items

ORDER BY object_name;

-- --------------------------------------------------------------------------
-- 2. Order date range
-- --------------------------------------------------------------------------

SELECT
    MIN(ordered_at) AS earliest_order,
    MAX(ordered_at) AS latest_order,
    COUNT(*) AS total_orders
FROM sales.orders;

-- --------------------------------------------------------------------------
-- 3. Order-status distribution
-- --------------------------------------------------------------------------

SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM sales.orders
GROUP BY status
ORDER BY order_count DESC;

-- --------------------------------------------------------------------------
-- 4. Sales-channel distribution
-- --------------------------------------------------------------------------

SELECT
    sales_channel,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM sales.orders
GROUP BY sales_channel
ORDER BY order_count DESC;

-- --------------------------------------------------------------------------
-- 5. Customer-country distribution
-- --------------------------------------------------------------------------

SELECT
    country_code,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM sales.customers
GROUP BY country_code
ORDER BY customer_count DESC;

-- --------------------------------------------------------------------------
-- 6. Order-item distribution
-- --------------------------------------------------------------------------

SELECT
    item_count,
    COUNT(*) AS orders_with_this_item_count
FROM
(
    SELECT
        order_id,
        COUNT(*) AS item_count
    FROM sales.order_items
    GROUP BY order_id
) AS item_counts
GROUP BY item_count
ORDER BY item_count;

-- --------------------------------------------------------------------------
-- 7. Discount distribution
-- --------------------------------------------------------------------------

SELECT
    discount_percent,
    COUNT(*) AS item_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM sales.order_items
GROUP BY discount_percent
ORDER BY discount_percent;

-- --------------------------------------------------------------------------
-- 8. Referential-integrity verification
--    Every result should be zero.
-- --------------------------------------------------------------------------

SELECT
    'orders_without_customer' AS check_name,
    COUNT(*) AS invalid_rows
FROM sales.orders AS o
LEFT JOIN sales.customers AS c
    ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'items_without_order',
    COUNT(*)
FROM sales.order_items AS oi
LEFT JOIN sales.orders AS o
    ON o.order_id = oi.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'items_without_product',
    COUNT(*)
FROM sales.order_items AS oi
LEFT JOIN sales.products AS p
    ON p.product_id = oi.product_id
WHERE p.product_id IS NULL;

-- --------------------------------------------------------------------------
-- 9. Sample reporting output
-- --------------------------------------------------------------------------

SELECT
    order_date,
    country_code,
    category_name,
    sales_channel,
    completed_orders,
    units_sold,
    gross_revenue,
    discount_amount,
    net_revenue
FROM reporting.vw_category_revenue
WHERE order_date >= DATE '2026-07-01'
  AND order_date < DATE '2026-08-01'
ORDER BY net_revenue DESC
LIMIT 20;
