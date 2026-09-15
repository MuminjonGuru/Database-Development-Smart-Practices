-- ============================================================================
-- File: 03_slow_category_revenue.sql
-- Video chapter: Profiling the original query
-- Database: retail_ops_dev
-- Purpose:
--   Produce the correct seven-day category-revenue report while applying a
--   date conversion to the indexed timestamptz column. This expression makes
--   it difficult for PostgreSQL to use the ordinary ordered_at B-tree index.
--
-- Important:
--   Run this query through Query Profiler and record the plan PostgreSQL
--   actually chooses. Do not claim a particular scan type until verified.
-- ============================================================================

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
ORDER BY net_revenue DESC;
