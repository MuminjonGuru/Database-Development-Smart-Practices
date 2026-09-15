-- ============================================================================
-- File: 01_recent_completed_orders.sql
-- Video chapter: Writing and reviewing SQL
-- Database: retail_ops_dev
-- Purpose:
--   Return one row per completed order for July 2026, including the customer,
--   sales channel, total units, and net value after item-level discounts.
-- ============================================================================

SELECT
    o.order_id,
    o.ordered_at,
    c.full_name,
    c.country_code,
    o.sales_channel,
    SUM(oi.quantity) AS total_units,
    ROUND(
        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - oi.discount_percent / 100.0)
        ),
        2
    ) AS net_order_value
FROM sales.orders AS o
INNER JOIN sales.customers AS c
    ON c.customer_id = o.customer_id
INNER JOIN sales.order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.status = 'completed'
  AND o.ordered_at >= TIMESTAMPTZ '2026-07-01 00:00:00+05'
  AND o.ordered_at < TIMESTAMPTZ '2026-08-01 00:00:00+05'
GROUP BY
    o.order_id,
    o.ordered_at,
    c.full_name,
    c.country_code,
    o.sales_channel
ORDER BY net_order_value DESC
LIMIT 20;
