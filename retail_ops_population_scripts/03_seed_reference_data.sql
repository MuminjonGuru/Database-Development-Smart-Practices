-- ============================================================================
-- File: 03_seed_reference_data.sql
-- Purpose:
--   Seed shared lookup/reference data for the Retail Ops demonstration.
--
-- Run this script in BOTH:
--   1. retail_ops_dev
--   2. retail_ops_staging
--
-- Expected result:
--   12 categories
--   144 products
--
-- The script is idempotent: existing categories and products are retained or
-- updated by their unique business keys.
-- ============================================================================

BEGIN;

DO $$
BEGIN
    IF to_regclass('sales.categories') IS NULL
       OR to_regclass('sales.products') IS NULL THEN
        RAISE EXCEPTION
            'The sales.categories and sales.products tables must exist first.';
    END IF;
END
$$;

INSERT INTO sales.categories (category_name)
VALUES
    ('Laptops'),
    ('Monitors'),
    ('Keyboards'),
    ('Mice'),
    ('Headsets'),
    ('Storage'),
    ('Networking'),
    ('Webcams'),
    ('Docking Stations'),
    ('Mobile Accessories'),
    ('Office Equipment'),
    ('Security Devices')
ON CONFLICT (category_name) DO NOTHING;

WITH category_templates
(
    category_name,
    sku_prefix,
    product_family,
    base_price
)
AS
(
    VALUES
        ('Laptops',            'LAP', 'ApexBook',   720.00::NUMERIC),
        ('Monitors',           'MON', 'ViewLine',   210.00::NUMERIC),
        ('Keyboards',          'KEY', 'KeyCraft',    65.00::NUMERIC),
        ('Mice',               'MOU', 'TrackPoint',  35.00::NUMERIC),
        ('Headsets',           'HDS', 'SoundArc',    85.00::NUMERIC),
        ('Storage',            'STO', 'DataVault',   95.00::NUMERIC),
        ('Networking',         'NET', 'LinkWave',   120.00::NUMERIC),
        ('Webcams',            'WCM', 'ClearCam',    70.00::NUMERIC),
        ('Docking Stations',   'DOC', 'PortHub',    130.00::NUMERIC),
        ('Mobile Accessories', 'MOB', 'ChargeFlex',  28.00::NUMERIC),
        ('Office Equipment',   'OFF', 'WorkMate',   160.00::NUMERIC),
        ('Security Devices',   'SEC', 'SecureKey',   75.00::NUMERIC)
),
product_variants
(
    variant_no,
    variant_name,
    price_multiplier
)
AS
(
    VALUES
        (1,  'Lite',      0.78::NUMERIC),
        (2,  'Compact',   0.84::NUMERIC),
        (3,  'Essential', 0.90::NUMERIC),
        (4,  'Core',      0.98::NUMERIC),
        (5,  'Plus',      1.06::NUMERIC),
        (6,  'Business',  1.14::NUMERIC),
        (7,  'Pro',       1.22::NUMERIC),
        (8,  'Creator',   1.30::NUMERIC),
        (9,  'Studio',    1.38::NUMERIC),
        (10, 'Max',       1.48::NUMERIC),
        (11, 'Ultra',     1.58::NUMERIC),
        (12, 'Elite',     1.68::NUMERIC)
)
INSERT INTO sales.products
(
    category_id,
    sku,
    product_name,
    unit_price,
    is_active
)
SELECT
    c.category_id,
    t.sku_prefix || '-' || LPAD(v.variant_no::TEXT, 3, '0') AS sku,
    t.product_family || ' ' || v.variant_name AS product_name,
    ROUND(
        t.base_price * v.price_multiplier
        + v.variant_no * 1.75,
        2
    ) AS unit_price,
    TRUE AS is_active
FROM category_templates AS t
INNER JOIN sales.categories AS c
    ON c.category_name = t.category_name
CROSS JOIN product_variants AS v
ON CONFLICT (sku)
DO UPDATE
SET
    category_id = EXCLUDED.category_id,
    product_name = EXCLUDED.product_name,
    unit_price = EXCLUDED.unit_price,
    is_active = EXCLUDED.is_active;

COMMIT;

ANALYZE sales.categories;
ANALYZE sales.products;

SELECT
    (SELECT COUNT(*) FROM sales.categories) AS category_count,
    (SELECT COUNT(*) FROM sales.products) AS product_count;
