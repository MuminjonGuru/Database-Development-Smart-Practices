-- ============================================================================
-- File: 04_optimized_category_revenue.sql
-- Video chapter: Profiling the optimized query
-- Database: retail_ops_dev
-- Purpose:
--   Return the same seven-day report using direct timestamptz range predicates,
--   allowing PostgreSQL to consider the existing ordered_at index naturally.
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
  AND o.ordered_at >= TIMESTAMPTZ '2026-07-25 00:00:00+05'
  AND o.ordered_at < TIMESTAMPTZ '2026-08-01 00:00:00+05'
GROUP BY
    c.country_code,
    cat.category_name,
    o.sales_channel
ORDER BY net_revenue DESC;
