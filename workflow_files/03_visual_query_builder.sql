SELECT
  customers.country_code,
  categories.category_name,
  orders.sales_channel,
  SUM(order_items.quantity) AS units_sold
FROM sales.orders
  INNER JOIN sales.customers
    ON orders.customer_id = customers.customer_id
  INNER JOIN sales.order_items
    ON order_items.order_id = orders.order_id
  INNER JOIN sales.products
    ON order_items.product_id = products.product_id
  INNER JOIN sales.categories
    ON products.category_id = categories.category_id
WHERE orders.status = 'completed'
AND orders.ordered_at >= '2026-07-01 00:00:00+05'
AND orders.ordered_at < '2026-08-01 00:00:00+05'
GROUP BY customers.country_code,
         categories.category_name,
         orders.sales_channel
