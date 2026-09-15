-- ============================================================================
-- File: 04_populate_dev_demo_data.sql
-- Purpose:
--   Generate the full deterministic transactional dataset used by the video.
--
-- Run ONLY in:
--   retail_ops_dev
--
-- Prerequisite:
--   Run 03_seed_reference_data.sql first.
--
-- Generated data:
--   25,000 customers
--   300,000 orders
--   900,000 order items
--
-- Fixed order window:
--   Approximately August 2024 through August 2026.
--
-- Safety:
--   The script stops if transactional rows already exist.
--   Use 06_reset_dev_transactional_data.sql before regenerating them.
-- ============================================================================

BEGIN;

SET LOCAL synchronous_commit = OFF;
SET LOCAL statement_timeout = 0;

DO $$
BEGIN
    IF current_database() <> 'retail_ops_dev' THEN
        RAISE EXCEPTION
            'This script must be run in retail_ops_dev. Current database: %',
            current_database();
    END IF;

    IF to_regclass('sales.customers') IS NULL
       OR to_regclass('sales.orders') IS NULL
       OR to_regclass('sales.order_items') IS NULL THEN
        RAISE EXCEPTION
            'The base sales tables do not exist.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'sales'
          AND table_name = 'orders'
          AND column_name = 'sales_channel'
    ) THEN
        RAISE EXCEPTION
            'sales.orders.sales_channel is missing. Run 02_dev_reporting_changes.sql first.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'sales'
          AND table_name = 'order_items'
          AND column_name = 'discount_percent'
    ) THEN
        RAISE EXCEPTION
            'sales.order_items.discount_percent is missing. Run 02_dev_reporting_changes.sql first.';
    END IF;

    IF (SELECT COUNT(*) FROM sales.categories) < 12
       OR (SELECT COUNT(*) FROM sales.products) < 144 THEN
        RAISE EXCEPTION
            'Reference data is incomplete. Run 03_seed_reference_data.sql first.';
    END IF;

    IF EXISTS (SELECT 1 FROM sales.customers LIMIT 1)
       OR EXISTS (SELECT 1 FROM sales.orders LIMIT 1)
       OR EXISTS (SELECT 1 FROM sales.order_items LIMIT 1) THEN
        RAISE EXCEPTION
            'Transactional data already exists. Run 06_reset_dev_transactional_data.sql before regenerating it.';
    END IF;
END
$$;

CREATE TEMPORARY TABLE demo_generation_config
(
    customer_count  INTEGER NOT NULL,
    order_count     INTEGER NOT NULL,
    anchor_timestamp TIMESTAMPTZ NOT NULL,
    order_span_days INTEGER NOT NULL
)
ON COMMIT DROP;

INSERT INTO demo_generation_config
(
    customer_count,
    order_count,
    anchor_timestamp,
    order_span_days
)
VALUES
(
    25000,
    300000,
    TIMESTAMPTZ '2026-08-01 23:59:59+05',
    730
);

-- --------------------------------------------------------------------------
-- Customers
-- --------------------------------------------------------------------------

WITH name_pool AS
(
    SELECT
        ARRAY[
            'Aisha', 'Akmal', 'Ali', 'Amir', 'Anna', 'Aziza', 'Daniel',
            'Dilshod', 'Elena', 'Farid', 'Grace', 'Ilyas', 'Kamila',
            'Laylo', 'Liam', 'Madina', 'Malika', 'Maya', 'Michael',
            'Nargiza', 'Noah', 'Olivia', 'Otabek', 'Rustam', 'Sara',
            'Sofia', 'Timur', 'Yusuf', 'Zarina', 'Zafar'
        ]::TEXT[] AS first_names,
        ARRAY[
            'Abdullayev', 'Ahmedov', 'Akramov', 'Aliyev', 'Brown',
            'Clark', 'Davies', 'Ergashev', 'Garcia', 'Harris',
            'Ibragimov', 'Ivanov', 'Johnson', 'Karimov', 'Khan',
            'Lee', 'Martin', 'Miller', 'Nazarov', 'Petrov',
            'Rahmonov', 'Roberts', 'Saidov', 'Smith', 'Taylor',
            'Thomas', 'Usmanov', 'Wilson', 'Yuldashev', 'Zhang'
        ]::TEXT[] AS last_names
),
customer_source AS
(
    SELECT
        g,
        np.first_names,
        np.last_names,
        ((g::BIGINT * 37) % 100)::INTEGER AS country_bucket
    FROM demo_generation_config AS cfg
    CROSS JOIN name_pool AS np
    CROSS JOIN generate_series(1, cfg.customer_count) AS seq(g)
)
INSERT INTO sales.customers
(
    full_name,
    email,
    country_code,
    created_at
)
SELECT
    first_names[
        1 + ((g - 1) % ARRAY_LENGTH(first_names, 1))
    ]
    || ' ' ||
    last_names[
        1 + (
            ((g - 1) / ARRAY_LENGTH(first_names, 1))
            % ARRAY_LENGTH(last_names, 1)
        )
    ] AS full_name,

    'customer'
    || LPAD(g::TEXT, 6, '0')
    || '@example.test' AS email,

    CASE
        WHEN country_bucket < 35 THEN 'UZ'
        WHEN country_bucket < 47 THEN 'KZ'
        WHEN country_bucket < 55 THEN 'KG'
        WHEN country_bucket < 63 THEN 'TJ'
        WHEN country_bucket < 73 THEN 'TR'
        WHEN country_bucket < 78 THEN 'GB'
        WHEN country_bucket < 83 THEN 'DE'
        WHEN country_bucket < 90 THEN 'US'
        WHEN country_bucket < 95 THEN 'AE'
        ELSE 'PL'
    END AS country_code,

    TIMESTAMPTZ '2022-01-01 00:00:00+05'
    + (
        ((g::BIGINT * 53) % 850)::INTEGER
        * INTERVAL '1 day'
    )
    + (
        ((g::BIGINT * 97) % 86400)::INTEGER
        * INTERVAL '1 second'
    ) AS created_at
FROM customer_source;

-- --------------------------------------------------------------------------
-- Orders
-- --------------------------------------------------------------------------

WITH customer_pool AS
(
    SELECT
        ARRAY_AGG(customer_id ORDER BY customer_id) AS customer_ids,
        COUNT(*)::INTEGER AS customer_count
    FROM sales.customers
),
order_source AS
(
    SELECT
        g,
        cp.customer_ids[
            1 + (
                (g::BIGINT * 15485863) % cp.customer_count
            )::INTEGER
        ] AS customer_id,

        cfg.anchor_timestamp
        - (
            ((g::BIGINT * 37) % cfg.order_span_days)::INTEGER
            * INTERVAL '1 day'
        )
        - (
            ((g::BIGINT * 7919) % 86400)::INTEGER
            * INTERVAL '1 second'
        ) AS ordered_at,

        ((g::BIGINT * 17) % 100)::INTEGER AS status_bucket,
        ((g::BIGINT * 29) % 10)::INTEGER AS channel_bucket
    FROM demo_generation_config AS cfg
    CROSS JOIN customer_pool AS cp
    CROSS JOIN generate_series(1, cfg.order_count) AS seq(g)
)
INSERT INTO sales.orders
(
    customer_id,
    ordered_at,
    status,
    sales_channel
)
SELECT
    customer_id,
    ordered_at,

    CASE
        WHEN status_bucket < 70 THEN 'completed'
        WHEN status_bucket < 80 THEN 'paid'
        WHEN status_bucket < 88 THEN 'pending'
        WHEN status_bucket < 95 THEN 'cancelled'
        ELSE 'refunded'
    END AS status,

    CASE
        WHEN channel_bucket < 6 THEN 'web'
        WHEN channel_bucket < 9 THEN 'mobile'
        ELSE 'partner'
    END AS sales_channel
FROM order_source;

-- --------------------------------------------------------------------------
-- Order items
-- --------------------------------------------------------------------------

WITH product_pool AS
(
    SELECT
        ARRAY_AGG(product_id ORDER BY product_id) AS product_ids,
        COUNT(*)::INTEGER AS product_count
    FROM sales.products
    WHERE is_active = TRUE
),
expanded_items AS
(
    SELECT
        o.order_id,
        item.item_no,

        pp.product_ids[
            1 + (
                (
                    o.order_id * 31
                    + item.item_no::BIGINT * 17
                ) % pp.product_count
            )::INTEGER
        ] AS product_id,

        (
            (
                o.order_id * 43
                + item.item_no::BIGINT * 19
            ) % 100
        )::INTEGER AS discount_bucket
    FROM sales.orders AS o
    CROSS JOIN product_pool AS pp
    CROSS JOIN LATERAL generate_series(
        1,
        1 + ((o.order_id * 7) % 5)::INTEGER
    ) AS item(item_no)
)
INSERT INTO sales.order_items
(
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_percent
)
SELECT
    e.order_id,
    e.product_id,

    (
        1
        + (
            (
                e.order_id
                + e.item_no::BIGINT * 13
            ) % 4
        )
    )::SMALLINT AS quantity,

    ROUND(
        p.unit_price
        * (
            1.00
            + (
                (
                    (
                        e.order_id
                        + e.item_no::BIGINT * 7
                    ) % 9
                )::INTEGER
                - 4
            )::NUMERIC
            / 100.00
        ),
        2
    ) AS historical_unit_price,

    CASE
        WHEN e.discount_bucket < 60 THEN 0.00
        WHEN e.discount_bucket < 75 THEN 5.00
        WHEN e.discount_bucket < 87 THEN 10.00
        WHEN e.discount_bucket < 94 THEN 15.00
        WHEN e.discount_bucket < 98 THEN 20.00
        ELSE 25.00
    END::NUMERIC(5, 2) AS discount_percent
FROM expanded_items AS e
INNER JOIN sales.products AS p
    ON p.product_id = e.product_id;

COMMIT;

ANALYZE sales.customers;
ANALYZE sales.orders;
ANALYZE sales.order_items;

SELECT
    'customers' AS object_name,
    COUNT(*) AS row_count
FROM sales.customers

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM sales.orders

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM sales.order_items

ORDER BY object_name;
