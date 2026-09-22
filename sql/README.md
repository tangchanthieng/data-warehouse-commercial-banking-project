### SQL Scripts

This folder contains the SQL scripts used to create and manage the data warehouse database objects for the commercial banking project.

### Contents

- `create_db.sql` — creates the database.
- `create_tables.sql` — creates the core tables for the warehouse.
- `create_views.sql` — creates analytical views for downstream reporting.
- `load_gold.sql` — loads or materializes the gold-layer reporting data.

### Typical workflow

1. Run `create_db.sql` to create the database.
2. Run `create_tables.sql` to create the tables and schema.
3. Run `create_views.sql` to create reusable reporting views.
4. Use `load_gold.sql` for the final reporting dataset preparation.

### Views mapping to Business questions

| Views                               | Answer to |
| ---                                 | ---       |
| gold.vw_transaction_performance     | Q1        |
| gold.vw_customer_profiling          | Q2        |
| gold.vw_geographic_purchasing_power | Q2        |
| gold.vw_card_usage_optimization     | Q2        |
| gold.vw_business_credit_risk        | Q3        |
| gold.vw_merchant_risk_exposure      | Q5        |
| gold.vw_geographic_risk_exposure    | Q5        |
| gold.vw_fraud_alerts                | Q4        |

## Notes

- These scripts are intended for use with the project’s Python ingestion and transformation pipeline.
- Review the script order before execution to avoid dependency issues.
- Update the database names, paths, and schema objects as needed for your environment.
