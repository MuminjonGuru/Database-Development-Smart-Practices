# dbForge Studio for PostgreSQL project and query files

**01_completed_orders_query.sql**
Chapter 1 query (completed July 2026 orders, one row per order) plus the built-in AI Assistant's grain review, kept as a SQL comment.
Known issue: the customers JOIN currently reads `ON c.customer_id = o.order_id`. It should read `ON c.customer_id = o.customer_id`. Fix before reusing this file.

**02_category_revenue_view_ddl.sql**
Generated DDL for `reporting.vw_category_revenue` from the "Generate Script AS > Create" step. A duplicate of this file, `00_SQL1.sql`, was removed.

**03_visual_query_builder.sql / .design**
Five-table category-revenue query created using Query Builder, with a saved visual design file.

**04_schema_compare_dev_vs_staging.scomp**
Schema comparison project comparing `retail_ops_dev` (source) against `retail_ops_staging` (target).

**04_data_generator_retail_ops_test.dgen**
Data generation project for `retail_ops_test` (1,000 customers, 5,000 orders, 15,000 order items).
