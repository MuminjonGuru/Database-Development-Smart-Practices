-- ============================================================================
-- File: 05_validate_profile_results.sql
-- Video chapter: Validating the optimization
-- Database: retail_ops_dev
-- Purpose:
--   Prove that the original and optimized queries return exactly the same rows
--   and aggregate values. Expected outcome: differing_rows = 0 and PASS.
-- ============================================================================

WITH slow_result AS
(
    SELECT
        c.country_code,
        cat.category_name,
        o.sales_channel,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(oi.quantity)::BIGINT AS units_sold,
        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - oi.discount_percent / 100.0)
            ),
            2
        ) AS net_revenue
    FROM sales.orders AS o
    INNER JOIN sales.customers AS c
        ON c.customer_id = o.customer_id
    INNER JOIN sales.order_items AS oi
        ON oi.order_id = o.order_id
    INNER JOIN sales.products AS p
        ON p.product_id = oi.product_id
    INNER JOIN sales.categories AS cat
        ON cat.category_id = p.category_id
    WHERE o.status = 'completed'
      AND (o.ordered_at AT TIME ZONE 'Asia/Tashkent')::DATE >= DATE '2026-07-25'
      AND (o.ordered_at AT TIME ZONE 'Asia/Tashkent')::DATE < DATE '2026-08-01'
    GROUP BY
        c.country_code,
        cat.category_name,
        o.sales_channel
),
optimized_result AS
(
    SELECT
        c.country_code,
        cat.category_name,
        o.sales_channel,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(oi.quantity)::BIGINT AS units_sold,
        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - oi.discount_percent / 100.0)
            ),
            2
        ) AS net_revenue
    FROM sales.orders AS o
    INNER JOIN sales.customers AS c
        ON c.customer_id = o.customer_id
    INNER JOIN sales.order_items AS oi
        ON oi.order_id = o.order_id
    INNER JOIN sales.products AS p
        ON p.product_id = oi.product_id
    INNER JOIN sales.categories AS cat
        ON cat.category_id = p.category_id
    WHERE o.status = 'completed'
      AND o.ordered_at >= TIMESTAMPTZ '2026-07-25 00:00:00+05'
      AND o.ordered_at < TIMESTAMPTZ '2026-08-01 00:00:00+05'
    GROUP BY
        c.country_code,
        cat.category_name,
        o.sales_channel
),
differences AS
(
    SELECT
        'slow_only'::TEXT AS difference_source,
        d.country_code,
        d.category_name,
        d.sales_channel,
        d.completed_orders,
        d.units_sold,
        d.net_revenue
    FROM
    (
        SELECT *
        FROM slow_result

        EXCEPT ALL

        SELECT *
        FROM optimized_result
    ) AS d

    UNION ALL

    SELECT
        'optimized_only'::TEXT AS difference_source,
        d.country_code,
        d.category_name,
        d.sales_channel,
        d.completed_orders,
        d.units_sold,
        d.net_revenue
    FROM
    (
        SELECT *
        FROM optimized_result

        EXCEPT ALL

        SELECT *
        FROM slow_result
    ) AS d
)
SELECT
    (SELECT COUNT(*) FROM slow_result) AS slow_result_rows,
    (SELECT COUNT(*) FROM optimized_result) AS optimized_result_rows,
    COUNT(*) AS differing_rows,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS: result sets are identical'
        ELSE 'FAIL: inspect the date boundaries or query logic'
    END AS validation_status
FROM differences;
