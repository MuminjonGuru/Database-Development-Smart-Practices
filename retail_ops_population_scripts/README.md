Retail Ops population scripts
=============================

Prerequisites
-------------
The following scripts must already have been executed:

1. 01_base_schema.sql
   - Run in retail_ops_dev
   - Run in retail_ops_staging

2. 02_dev_reporting_changes.sql
   - Run only in retail_ops_dev

Execution order
---------------
1. Open retail_ops_dev in pgAdmin Query Tool.
2. Run 03_seed_reference_data.sql.
3. Run 04_populate_dev_demo_data.sql.
4. Run 05_validate_dev_data.sql.

Then:

5. Open retail_ops_staging in pgAdmin Query Tool.
6. Run 03_seed_reference_data.sql there as well.

Why staging does not receive the large transactional dataset yet
----------------------------------------------------------------
The planned Schema Compare chapter compares database structure, not table rows.
Keeping the large dataset in retail_ops_dev avoids duplicating roughly 1.2
million transactional rows without adding value to that demonstration.

Generated development data
--------------------------
12 categories
144 products
25,000 customers
300,000 orders
900,000 order items

Reset
-----
Run 06_reset_dev_transactional_data.sql in retail_ops_dev before regenerating
the transactional dataset. It preserves categories, products, schemas, indexes,
constraints, and the reporting view.
