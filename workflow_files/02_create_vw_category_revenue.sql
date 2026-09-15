CREATE OR REPLACE VIEW reporting.vw_category_revenue
AS
SELECT
  o.ordered_at :: DATE AS order_date,
  c.country_code,
  cat.category_name,
  o.sales_channel,
  COUNT(DISTINCT o.order_id) AS completed_orders,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.quantity :: NUMERIC * oi.unit_price), 2) AS gross_revenue,
  ROUND(SUM(oi.quantity :: NUMERIC * oi.unit_price * oi.discount_percent / 100.0), 2) AS discount_amount,
  ROUND(SUM(oi.quantity :: NUMERIC * oi.unit_price * (1 :: NUMERIC - oi.discount_percent / 100.0)), 2) AS net_revenue
FROM sales.orders o
  JOIN sales.customers c
    ON c.customer_id = o.customer_id
  JOIN sales.order_items oi
    ON oi.order_id = o.order_id
  JOIN sales.products p
    ON p.product_id = oi.product_id
  JOIN sales.categories cat
    ON cat.category_id = p.category_id
WHERE o.status :: TEXT = 'completed' :: TEXT
GROUP BY (o.ordered_at :: DATE),
         c.country_code,
         cat.category_name,
         o.sales_channel;