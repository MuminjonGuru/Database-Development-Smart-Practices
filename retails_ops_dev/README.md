Retail Ops working query files
==============================

Run all five SQL files against retail_ops_dev.

01_recent_completed_orders.sql
  Chapter 1 query. Returns one row per completed order for July 2026.

02_category_revenue_query.sql
  Reference SQL for the five-table Query Builder demonstration.

03_slow_category_revenue.sql
  Original profile candidate. It converts ordered_at to an Asia/Tashkent date,
  preventing the ordinary timestamp index from being used directly.

04_optimized_category_revenue.sql
  Equivalent query with direct timestamptz range predicates.

05_validate_profile_results.sql
  Compares both result sets in both directions using EXCEPT ALL.
  Expected output: differing_rows = 0 and validation_status = PASS.

Important
---------
The slow query uses an explicit Asia/Tashkent conversion so its local calendar
window is exactly equivalent to the +05 timestamp boundaries in the optimized
query, regardless of the PostgreSQL session's current timezone.
