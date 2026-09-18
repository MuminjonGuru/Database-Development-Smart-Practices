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
    ON c.customer_id = o.order_id
  INNER JOIN sales.order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.status = 'completed'
AND o.ordered_at >= TIMESTAMPTZ '2026-07-01 00:00:00+05'
AND o.ordered_at < TIMESTAMPTZ '2026-08-01 00:00:00+05'
GROUP BY o.order_id,
         o.ordered_at,
         c.full_name,
         c.country_code,
         o.sales_channel
ORDER BY net_order_value DESC LIMIT 20;


/* 
  dbForge AI Assistant Result grain: one row per o.order_id after aggregation, because the query groups by o.order_id, o.ordered_at, c.full_name, c.country_code, and o.sales_channel. The SUM(...) values are order-level measures, and LIMIT 20 returns the 20 highest-value completed orders in the date range. Correctness risks:  sales.customers is joined on c.customer_id = o.order_id. From the attached metadata, orders has customer_id and customers has customer_id, so this join condition is incorrect and will likely mis-match orders to customers. The date filter uses TIMESTAMPTZ '2026-07-01 00:00:00+05' to 2026-08-01 00:00:00+05; that is logically fine for a half-open monthly window, but be careful that it is anchored to a specific offset, not the session time zone. SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) is order-item based and then rounded at the order level, which is usually correct for an order total, but if line-level rounding is required by business rules, this can differ slightly.  Maintainability / performance risks:  The query depends on grouping by customer attributes even though the underlying grain is order-level; this is acceptable, but it means any future customer-name or country-code changes are reflected historically as stored at query time, not as-of-order-time unless the data model guarantees stability. The existing indexes support the filter and join pattern reasonably well: sales.idx_orders_status, sales.idx_orders_ordered_at, sales.pk_orders, sales.pk_customers, and sales.idx_order_items_order_id. No composite index exists on (status, ordered_at) for sales.orders, so the planner may still need to combine separate indexes or scan more rows for the filtered month window.  Necessary change:  Fix the customer join to use the order’s customer_id column.
*/
