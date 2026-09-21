# Commercial Banking Data Warehouse Skill

## Purpose
Use this skill to operate, troubleshoot, or document the local batch data warehouse pipeline in this repository. The project implements a Bronze, Silver, and Gold medallion architecture for customer, card, merchant-category, and transaction data and exposes Gold views for Power BI analysis.

## When to Use
Use this skill when:

- Setting up the local Python and SQL Server environment.
- Running or explaining the ETL pipeline.
- Checking source data quality or investigating load failures.
- Updating warehouse tables, Gold data, or analytical views.
- Preparing data for the included Power BI artifacts or notebook.

## When Not to Use
Do not use this procedure for real-time ingestion, production scheduling, cloud deployment, machine-learning workflows, customer-facing applications, or external fraud-provider integrations. Those capabilities are outside this repository's scope.

## Project Contracts

- Run commands from the repository root.
- Raw input files must be in `data/raw`: `user.csv`, `card.csv`, `transaction.csv`, and `mcc.csv`.
- Extraction writes exact copies to `data/staging` as `stg_user.csv`, `stg_card.csv`, `stg_transaction.csv`, and `stg_mcc.csv`.
- Transformation writes `clean_users.csv`, `clean_cards.csv`, `clean_transactions.csv`, and `clean_mcc.csv` to `data/clean`.
- The default SQL Server connection is `.\SQLEXPRESS`, database `bank_db`, ODBC Driver 17, Windows trusted authentication. The connection is defined in `config/config.py`.
- Python database scripts import local modules from `config` and `python`; run them using the repository-root commands below.

## Prerequisites

1. Windows with Python and SQL Server Express installed.
2. SQL Server running as `.\SQLEXPRESS` and ODBC Driver 17 for SQL Server installed.
3. Permission to create and load the `bank_db` database with Windows authentication.
4. Python dependencies installed in a virtual environment.

Set up the environment from the repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m pip install matplotlib seaborn jupyter
```

The additional packages are needed by `noteboooks/data_assessment.ipynb`.

## Workflow

### 1. Inspect or assess source data

Confirm that all four required CSVs exist in `data/raw`. For exploratory profiling, open `noteboooks/data_assessment.ipynb`; the notebook reads directly from `data/raw`.

### 2. Create the database and schemas

Run these SQL scripts in SQL Server Management Studio in this order:

```text
sql/create_db.sql
sql/create_tables.sql
```

The scripts create `bank_db` and the `bronze`, `silver`, and `gold` schemas, then create raw, cleaned, dimension, and fact tables.

### 3. Extract raw files to staging

```powershell
python python/extract.py
```

This fails if a required raw file is missing. It reads each raw CSV and writes an unchanged copy to the staging layer.

### 4. Validate staging data

```powershell
python python/validate.py
```

Validation checks required columns, reports nulls in configured fields, and treats missing or duplicate primary-key columns as critical failures. The current validation function returns a Boolean and logs failures; because the command-line entry point does not explicitly exit nonzero on a failed Boolean, inspect the log and stop the pipeline manually when a critical clearance failure is reported.

### 5. Transform staging data into Silver-ready files

```powershell
python python/transformation_silver.py
```

Transformations include numeric coercion, absolute values for configured financial and demographic fields, gender normalization, uppercase card and location values, chip-value normalization, and empty MCC descriptions converted to null. The cleaned CSVs are written to `data/clean`.

### 6. Load Bronze and Silver tables

Run these commands in order:

```powershell
python python/load_bronze.py
python python/load_silver.py
```

Each loader reads its corresponding CSV layer, converts pandas nulls to SQL `NULL`, truncates the target table, and bulk inserts the current file contents. Bronze receives staging files; Silver receives cleaned files. Do not run a loader before its database tables and input files exist.

### 7. Reload Gold dimensions and fact data

After the Silver load succeeds, run:

```text
sql/load_gold.sql
```

The script truncates the dependent Gold fact table first, deletes the dimensions, reloads dimensions from Silver, and then reloads the transaction fact table. This order is required because Gold foreign keys reference the dimension tables.

### 8. Recreate analytical views

```text
sql/create_views.sql
```

Run this after Gold data is loaded. The views cover transaction performance, customer profiling, geographic purchasing power and risk, card usage optimization, credit risk, merchant risk, and fraud indicators.

## Validation and Completion Checks

Before reporting success, verify:

- The four raw files, four staging files, and four cleaned files are present.
- Validation logs contain no critical missing-key or duplicate-key failures.
- Bronze and Silver load messages show the expected record counts.
- Gold dimensions and `gold.fact_transactions` contain data after `sql/load_gold.sql`.
- The views in `gold` were created or altered successfully after `sql/create_views.sql`.
- At least one representative Gold view can be queried from SQL Server before opening Power BI.

For a repeatable reload, rerun extraction, validation, transformation, Bronze load, Silver load, Gold load, and view creation in that order. The Bronze, Silver, and Gold loading procedures are designed to replace the current snapshot rather than append to it.

## Troubleshooting Rules

- A missing raw-file error means the file name or location does not match the project contract; do not continue to the next stage.
- A database connection error usually indicates SQL Server is not running, the server name differs from `.\SQLEXPRESS`, the ODBC driver is missing, or Windows authentication lacks permission.
- A duplicate-key or missing-key validation failure must be resolved in the source/staging data before loading Silver or Gold.
- A foreign-key failure during Gold loading usually means dimension keys and transaction references are inconsistent; inspect the Silver files before retrying.
- The optional `generate_transactions.py` utility expects source names `users_data.csv`, `cards_data.csv`, `mcc_codes.csv`, and `transactions_data.csv`, which differ from the pipeline's `user.csv`, `card.csv`, `mcc.csv`, and `transaction.csv`. Do not use it with the standard raw directory unless those inputs are supplied separately or the utility is updated.

## Output Requirements

When using this skill, produce a concise procedure or diagnosis that includes:

1. The current pipeline stage and its required input.
2. The exact command or SQL script to run next.
3. The expected output path, table, or view.
4. The validation evidence needed before proceeding.
5. Any blocker, especially a missing file, failed data-quality rule, or database connection problem.

Do not claim that a stage succeeded without checking its logs, generated files, or database result.

## Quality Checklist

- [ ] Work is based on the repository's actual file names and script order.
- [ ] Raw data is preserved in staging before transformations are applied.
- [ ] Data-quality failures are reported before database loads continue.
- [ ] Bronze, Silver, and Gold dependencies are respected.
- [ ] Gold fact data is cleared before referenced dimensions are replaced.
- [ ] Views are recreated only after Gold data is available.
- [ ] Paths, SQL Server settings, and known filename caveats are stated explicitly.
- [ ] Results are verified with files, logs, row counts, or queries.