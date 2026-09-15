BEGIN;

ALTER TABLE sales.orders
    ADD COLUMN sales_channel VARCHAR(20) NOT NULL DEFAULT 'web';

ALTER TABLE sales.orders
    ADD CONSTRAINT chk_orders_sales_channel
    CHECK
    (
        sales_channel IN
        (
            'web',
            'mobile',
            'partner'
        )
    );

ALTER TABLE sales.order_items
    ADD COLUMN discount_percent NUMERIC(5, 2) NOT NULL DEFAULT 0;

ALTER TABLE sales.order_items
    ADD CONSTRAINT chk_order_items_discount_percent
    CHECK (discount_percent BETWEEN 0 AND 80);

CREATE SCHEMA reporting;

CREATE VIEW reporting.vw_category_revenue
AS
SELECT
    o.ordered_at::DATE AS order_date,
    c.country_code,
    cat.category_name,
    o.sales_channel,

    COUNT(DISTINCT o.order_id) AS completed_orders,

    SUM(oi.quantity)::BIGINT AS units_sold,

    ROUND(
        SUM(oi.quantity * oi.unit_price),
        2
    ) AS gross_revenue,

    ROUND(
        SUM(
            oi.quantity
            * oi.unit_price
            * oi.discount_percent
            / 100.0
        ),
        2
    ) AS discount_amount,

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

GROUP BY
    o.ordered_at::DATE,
    c.country_code,
    cat.category_name,
    o.sales_channel;

COMMIT;