# Database Development Smart Practices

Here are SQL scripts and dbForge project files for a practical PostgreSQL deployment workflow: reviewing a query, visualizing JOINs, comparing schemas, generating test data, profiling and fixing a slow query, and generating deployment-ready DDL—all with dbForge Studio for PostgreSQL, part of multidatabase solution [dbForge Edge](https://www.devart.com/dbforge/edge/).

## Overview

The workflow demonstrates how dbForge Studio for PostgreSQL helps manage a single database change from a first working query to a deployment-ready script. You will be able to do the following:

* Write and review a SQL query, checking its result grain before aggregating
* Use the built-in AI Assistant as a second review surface for an existing query
* Build and validate a multi-table query visually with Query Builder
* Compare a development and a staging schema before deployment and generate a synchronization script
* Generate relational test data that preserves foreign key relationships
* Profile a slow query, read its execution plan, and fix the bottleneck without changing the result
* Generate the final view DDL as a reviewable deployment artifact

## Demo Scenario

The database represents a `retail_ops` e-commerce backend with these entities: categories, products, customers, orders, and order items.

The task: build a category-revenue report broken down by customer country and sales channel, take it from a first working query in `retail_ops_dev` through to a deployment-ready script for `retail_ops_staging`, and use a separate `retail_ops_test` database for data generation and profiling.

## Repository Structure

```text
.
├── README.md
├── LICENSE
├── retail_ops_dev/
│   ├── README.md
│   ├── 01_recent_completed_orders.sql
│   ├── 02_category_revenue_query.sql
│   ├── 03_slow_category_revenue.sql
│   ├── 04_optimized_category_revenue.sql
│   └── 05_validate_profile_results.sql
├── retail_ops_staging/
│   └── 01_base_schema.sql
├── retail_ops_population_scripts/
│   ├── README.md
│   ├── 01_base_schema.sql
│   ├── 02_dev_reporting_changes.sql
│   ├── 03_seed_reference_data.sql
│   ├── 04_populate_dev_demo_data.sql
│   ├── 05_validate_dev_data.sql
│   └── 06_reset_dev_transactional_data.sql
└── workflow_files/
    ├── README.md
    ├── 01_completed_orders_query.sql
    ├── 02_category_revenue_view_ddl.sql
    ├── 03_visual_query_builder.sql
    ├── 03_visual_query_builder.sql.design
    ├── 04_schema_compare_dev_vs_staging.scomp
    └── 04_data_generator_retail_ops_test.dgen
```

## Folders

### `retail_ops_population_scripts/`

Sets up and resets the `retail_ops_dev` and `retail_ops_staging` databases: the base schema, reporting-only columns and a view added in development, seed reference data (12 categories, 144 products), a transactional dataset with roughly 1.2 million rows, and a reset script that preserves the schema and reference data. See the folder's own README for run order.

### `retail_ops_dev/`

Five working query files for reviewing and profiling: the first grain-checked query, a reference five-table query, unoptimized and optimized profiling candidates, and an `EXCEPT ALL` validation script confirming both profiling candidates return identical rows. See the folder's own README for details.

### `retail_ops_staging/`

The base schema only, no reporting columns or views, representing the environment that a schema comparison would run against before deployment.

### `workflow_files/`

dbForge Studio project files and generated SQL: a query reviewed by the AI Assistant, generated view DDL, Query Builder output, a schema comparison project (`retail_ops_dev` vs `retail_ops_staging`), and a data generation project (`retail_ops_test`).

## Notes

This repository is for educational and demonstration purposes.

Before running any script against a real environment:

* Review the SQL manually, including JOIN conditions and result grain
* Check the target database and connection before comparing or synchronizing schemas
* Validate indexes and constraints
* Test the execution plan
* Confirm no destructive changes are included

Schema Compare, Data Generator, and Query Profiler (three of the six workflow steps shown here) require the Professional edition of dbForge Studio for PostgreSQL. Query Builder, AI Assistant, and DDL generation are available in the free Express edition.

## Tool Used

This workflow was created with dbForge Studio for PostgreSQL, part of the dbForge database development and management ecosystem by Devart.

Learn more: [dbForge Studio for PostgreSQL](https://www.devart.com/dbforge/postgresql/studio/)
