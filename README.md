## Commercial Banking Analytics Warehouse

version: 2.0

## Project Summary

This project builds a batch data warehouse for commercial banking customer, card, merchant-category, and transaction.

Focusing on implementing the **Medallion Architecture**, operational data undergoes an ETL pipeline via Bronze, Silver, and Gold Layers before exposing analytical views for Power BI reporting.

The analysis supports transaction monitoring, customer profiling, merchant analysis, marketing segmentation, and credit risk assessment.

## Business Challenge

The bank's customer and payment data is distributed across separate CSV sources, making it difficult to create a consistent view of transaction activity, customer behavior, card performance, and credit exposure.

The bank needs a repeatable data preparation and reporting process that improves data quality and helps business teams identify suspicious activity, understand customer segments, and monitor portfolio risk.

## Business Questions

1. Which transactions contain rule-based indicators of suspicious unusual activity, repeated transactions in short-terms, or frequent errors?
2. Which customers, cards, merchants, and merchant categories show the highest value transaction risk or error rates?
3. How do retention rate, active customers, transaction volume, value, success rate, chip usage, and card utilization change over time?
4. Which customer segments and regions have the greatest spending potential or marketing opportunity?
5. Which customers or credit-score groups have elevated debt-to-income or credit exposure risk?

## Project Objectives

1. Build a repeatable batch pipeline that extracts, validates, and loads 04 source datasets.
2. Create a data warehouse using Bronze, Silver, and Gold Layers, star schemas with dimensional and fact tables.
3. Produce Gold-layer Views for transaction anomalies, fraud indicators, customer and merchant risk, performance, segmentation, and credit analysis.
4. Provide Power BI-ready data for monitoring transaction activity, customer profiles, marketing opportunities, and risk management.
5. Document a reproducible local setup and execution process for analysts and engineers.

## Tech Stack

| Tool                            | Usage                                                                                           |
| ---                             | ---                                                                                             |
| Python                          | Runs extraction, data-quality validation, transformations, and database loading scripts         |
| pandas                          | Reads and writes CSV files and performs data cleaning and profiling                             |
| NumPy                           | Handles null values and numeric data preparation                                                |
| SQL Server Management Studio 22 | Host the database and the Bronze, Silver, and Gold schemas                                      |
| pyodbc                          | Connects Python to SQL Server using Windows trusted authentication                              |
| SQL                             | Creates warehouse tables, reloads Gold data, and defines analytical views                       |
| Jupyter Notebook                | Performs exploratory data assessment on the raw datasets                                        |
| Power BI                        | Provides report artifacts for customer profiling, transactions, marketing, and risk management  |

## Scope

### In Scope

- Load `user.csv`, `card.csv`, `transaction.csv`, and `mcc.csv` from the raw data layer.
- Copy raw files to staging and validate required fields, nulls, and duplicate keys.
- Clean and standardize user, card, transaction, and MCC data into CSV files.
- Load the data into SQL Server Bronze, Silver, and Gold layers.
- Build customer, card, and MCC dimensions plus a transaction fact table.
- Create SQL views for fraud indicators, anomalies, customer and merchant risk, transaction performance, marketing, and credit analysis.
- Use the resulting warehouse views in the included Power BI report artifacts.

### Out of Scope

- Real-time streaming, online transaction processing, or automated alert delivery.
- Machine-learning model training, deployment, or model retraining.
- Cloud deployment, production orchestration, scheduling, or CI/CD.
- Integration with external fraud providers, banking systems, or APIs.
- Customer-facing web or mobile applications.
- Automated case management, investigation workflows, or regulatory filing.

## Key Findings and Insights

<!-- Add validated findings and insights after completing the data assessment and report# review. -->

## How to Run the Project

### Prerequisites

- Windows with Python installed.
- SQL Server Express running as `.\SQLEXPRESS`.
- ODBC Driver 17 for SQL Server.
- A Python environment with the packages in `requirements.txt` installed.
- Permission to create and load the `bank_db` database using Windows trusted authentication.

### Install Python Dependencies

From the project root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

The notebook also imports `matplotlib` and `seaborn`; install them separately before running the notebook:

```powershell
python -m pip install matplotlib seaborn jupyter
```

### Create the Database

Run these scripts in SQL Server Management Studio or another SQL Server client, in order:

```text
sql/create_db.sql
sql/create_t Server syntax.

### Run the Python Pipeline

Run these commands from the project root, in order:

```powershell
python python/extract.py
python python/validate.py
python python/load_bronze.py
python python/transformation_silver.py
python python/load_silver.py
```

The pipeline reads from `data/raw`, writes staging file, loads the Bronze and Silver tables in `bank_db`, and writes cleaned files to `data/clean`.

### Load Gold Data and Views

Run the following SQL scripts after the Python pipeline completes:

```text
sql/load_gold.sql
sql/create_views.sql
```

### Power BI dashboard report

Open `powerbi/report.pdf` to view dashboard pages in PDF format; OR connect data from `data/clean` to your Power BI Desktop and open `report.pbix` to view and monitor the dashboard.

### Optional Data Assessment

Open `noteboooks/data_assessment.ipynb` from the project root to inspect source data quality and profiling checks. The notebook expects the raw files under `data/raw`.
