BEGIN;

CREATE SCHEMA sales;

CREATE TABLE sales.customers
(
    customer_id  BIGINT GENERATED ALWAYS AS IDENTITY,
    full_name    VARCHAR(120) NOT NULL,
    email        VARCHAR(254) NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers
        PRIMARY KEY (customer_id),

    CONSTRAINT uq_customers_email
        UNIQUE (email),

    CONSTRAINT chk_customers_country_code
        CHECK (country_code ~ '^[A-Z]{2}$')
);

CREATE TABLE sales.categories
(
    category_id   INTEGER GENERATED ALWAYS AS IDENTITY,
    category_name VARCHAR(80) NOT NULL,

    CONSTRAINT pk_categories
        PRIMARY KEY (category_id),

    CONSTRAINT uq_categories_name
        UNIQUE (category_name)
);

CREATE TABLE sales.products
(
    product_id   BIGINT GENERATED ALWAYS AS IDENTITY,
    category_id  INTEGER NOT NULL,
    sku          VARCHAR(32) NOT NULL,
    product_name VARCHAR(140) NOT NULL,
    unit_price   NUMERIC(12, 2) NOT NULL,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_products
        PRIMARY KEY (product_id),

    CONSTRAINT uq_products_sku
        UNIQUE (sku),

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES sales.categories (category_id),

    CONSTRAINT chk_products_unit_price
        CHECK (unit_price > 0)
);

CREATE TABLE sales.orders
(
    order_id    BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    ordered_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status      VARCHAR(20) NOT NULL,

    CONSTRAINT pk_orders
        PRIMARY KEY (order_id),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES sales.customers (customer_id),

    CONSTRAINT chk_orders_status
        CHECK
        (
            status IN
            (
                'pending',
                'paid',
                'completed',
                'cancelled',
                'refunded'
            )
        )
);

CREATE TABLE sales.order_items
(
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id      BIGINT NOT NULL,
    product_id    BIGINT NOT NULL,
    quantity      SMALLINT NOT NULL,
    unit_price    NUMERIC(12, 2) NOT NULL,

    CONSTRAINT pk_order_items
        PRIMARY KEY (order_item_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES sales.orders (order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES sales.products (product_id),

    CONSTRAINT chk_order_items_quantity
        CHECK (quantity BETWEEN 1 AND 20),

    CONSTRAINT chk_order_items_unit_price
        CHECK (unit_price > 0)
);

CREATE INDEX idx_products_category_id
    ON sales.products (category_id);

CREATE INDEX idx_orders_customer_id
    ON sales.orders (customer_id);

CREATE INDEX idx_orders_ordered_at
    ON sales.orders (ordered_at);

CREATE INDEX idx_orders_status
    ON sales.orders (status);

CREATE INDEX idx_order_items_order_id
    ON sales.order_items (order_id);

CREATE INDEX idx_order_items_product_id
    ON sales.order_items (product_id);

COMMIT;