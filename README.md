## Data Warehouse Commercial Banking Project

Updated on September 2026

## Project Summary

This project builds a batch data warehouse for commercial banking customer, card, merchant-category, and transaction.

Focusing on implementing the **Medallion Architecture**, operational data undergoes an ETL pipeline via Bronze, Silver, and Gold Layers before exposing analytical views for Power BI reporting.

The analysis supports transaction monitoring, customer profiling, merchant analysis, marketing segmentation, and credit risk assessment.

## Business Challenge

The bank's customer and payment data is distributed across separate CSV sources, making it difficult to create a **consistent view of transaction activity, customer behavior, card performance, and credit exposure**.

The bank needs a repeatable data preparation and reporting process that improves data quality and helps business teams identify suspicious activity, understand customer segments, and monitor portfolio risk.

## Business Questions

`Operations and marketing`

Q1. How do active customers, transaction volume, value, success rate, chip usage, and card utilization change over time?

Q2. Which customer segments and regions have the greatest spending potential or marketing opportunity?

`Risk management`

Q3. Which customers or credit-score groups have elevated debt-to-income or credit exposure risk?

Q4. Which transactions contain rule-based indicators of suspicious unusual activity, repeated transactions in short-terms, or frequent error

Q5. Which customers, cards, merchants, and merchant categories show the highest value transaction risk or error rates?

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

`Marketing and Operations`

**1. Geographic Spending Concentration**

- Top-spending clients are concentrated primarily in the far-east and western regions, while lower-spending clients are more prevalent in central regions and northern states, **creating opportunities for region-specific marketing campaigns, partnerships, and loyalty programs**.

- Further analysis should assess whether the difference is driven by customer demographics, income, product mix, or merchant availability.

**2. High-Value Spending Categories**

- The highest spending is concentrated across money transfer, groceries, wholesale, drug stores, services, utilities, dining, telecommunications, and automotive.

- The diversity of high-spending categories creates opportunities for strategic partnerships across multiple industries, rather than relying on a single merchant category.

- Potential initiatives include category-specific cashback, rewards, merchant discounts, and co-branded promotions.

**3. Online Payment Opportunity**

- Online payment value shows an increasing trend over time, despite representing a relatively small share of transaction volume. **This suggests that online transactions may have higher average transaction values, making them a potential area for targeted promotion**.

- The bank could consider online-payment incentives, digital rewards, and merchant partnerships to encourage greater adoption and transaction frequency.

- The gap between transaction value and volume should be monitored to determine whether online payments are being used primarily for high-value purchases.

**4. Chip Transaction Dominance**

- **Chip transactions dominate transaction activity**, indicating strong reliance on traditional card-present payment behaviour.

- Rather than directly replacing chip transactions, digital-payment initiatives could target incremental online and contactless adoption among suitable customer segments.

**5. Spending Decline After 2023**

- Total spending peaked in 2023 and **declined in 2024**, indicating a potential slowdown in customer spending activity.

- Spending patterns across card brands remain broadly similar, although transaction amounts differ.

- This suggests that marketing strategies may be more effectively differentiated by customer behaviour, credit capacity, spending category, and transaction value than by card brand alone.

- Further investigation should examine whether the decline is associated with changes in credit limits, customer activity, economic conditions, or product usage.

**6. Product Portfolio Opportunity**

- Debit and prepaid cards contribute relatively little to overall transaction value and volume compared with other card products.

- Before allocating substantial promotional budgets to these products, the bank should assess customer acquisition potential, usage trends, profitability, and strategic relevance.

- Promotional investment could instead prioritize products and customer segments demonstrating higher transaction activity and revenue potential.

`Risk Management`

**1. Limited Historical Customer Coverage**

- Only 303 of 2,000 clients have transaction records spanning the full 2020–2024 period.

- This represents approximately 15.2% of the customer base, meaning long-term behavioural analysis should be interpreted cautiously.

- The bank should distinguish between genuinely inactive customers and customers with incomplete historical records before using transaction history for risk profiling.

**2. Debt-to-Income Exposure**

- The dataset shows cases where maximum debt substantially exceeds maximum income, highlighting potential exposure to customer-level repayment risk.

- The overall DTI ratio of approximately 1.39 should be interpreted carefully depending on how debt and income are defined and aggregated.

- Customers with elevated DTI should potentially receive additional credit-risk monitoring, affordability assessment, or exposure controls.

**3. Generally Strong Credit Scores**

- The average credit score is approximately 710, indicating that the customer portfolio is generally concentrated in a relatively healthy credit-score range.

- However, a strong average can mask high-risk subsegments, particularly customers with elevated debt or DTI.

- Credit score should therefore be evaluated jointly with DTI, income, debt exposure, and transaction behaviour rather than used as a standalone risk indicator.

**4. Transaction Errors and Spending Exposure**

- Transaction errors appear more frequently within high-spending merchant categories, suggesting that error monitoring should account for transaction volume and value.

- Similar patterns appear across card types, card brands, and locations, indicating that errors may be associated more strongly with transaction activity and merchant/category characteristics than with a specific card product.

- Error rates, rather than raw error counts, should be used to avoid disproportionately flagging high-volume categories.

**5. Seasonal and Temporal Error Patterns**

- Transaction errors appear concentrated between April and August, with additional concentration toward month-end.

- The pattern warrants further investigation to determine whether it reflects: increased transaction volume; billing or payment-cycle effects; system or operational issues; merchant processing behaviour; or seasonal customer activity.

- Comparing error rate vs. transaction volume by month and day-of-month would help determine whether the pattern is simply volume-driven or represents an elevated operational risk.

**6. Credit Health of Younger Customers**

- Younger customers generally demonstrate medium-to-high credit scores, suggesting relatively healthy credit profiles within this segment.

- However, approximately 75 younger customers with lower credit scores also have relatively low per-capita income, highlighting a potentially vulnerable subsegment.

- This group could benefit from targeted affordability monitoring and responsible-credit products rather than blanket promotional activity.

**7. DTI Variation Across Age Groups**

- Younger customers exhibit greater variation in DTI, while older customer groups appear comparatively more concentrated.

- This suggests that age alone is insufficient for risk segmentation.

- Combining age, income, credit score, DTI, debt exposure, and transaction behaviour would provide a more robust customer-risk profile.

| Area                  | Finding                                               | Potential Action                                  |
| ---                   | ---                                                   | ---                                               |
| Marketing             | Spending is geographically concentrated               | Develop region-specific campaigns                 |
| Partnerships          | High-value spending spans diverse MCCs                | Explore cross-industry merchant partnerships      |
| Digital payments      | Online payment value is increasing despite low volume | Promote online payment adoption                   |
| Customer spending     | Spending declined after the 2023 peak                 | Investigate drivers of reduced spending           |
| Card products         | Debit/prepaid contribute relatively little            | Reassess promotional ROI                          |
| Credit risk           | Some customers have high debt relative to income      | Strengthen affordability/risk monitoring          |
| Transaction risk      | Errors cluster in high-activity categories            | Monitor error rates, not just counts          |
| Operational risk      | Errors appear concentrated Apr-Aug and month-end      | Investigate seasonal/system/payment-cycle drivers |
| Young customers       | Generally healthy credit scores but heterogeneous DTI | Build differentiated young-customer risk segments |
| Data quality          | Only 15.2% have full 2020–2024 history                | Validate missing/incomplete historical records    |

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

```sql
sql/create_db.sql
sql/create_table.sql
```

```python
### Run the Python Pipeline
### Run these commands from the project root, in order:

python python/extract.py
python python/validate.py
python python/load_bronze.py
python python/transformation_silver.py
python python/load_silver.py
```

The pipeline reads from `data/raw`, writes staging file, loads the Bronze and Silver tables in `bank_db`, and writes cleaned files to `data/clean`.

### Load Gold Data and Views

Run the following SQL scripts after the Python pipeline completes:

```sql
sql/load_gold.sql
sql/create_views.sql
```

### Power BI dashboard report

Open `powerbi/report.pdf` to view dashboard pages in PDF format; OR connect data from `data/clean` to your Power BI Desktop and open `report.pbix` to view and monitor the dashboard.

### Optional Data Assessment

Open `noteboooks/data_assessment.ipynb` from the project root to inspect source data quality and profiling checks. The notebook expects the raw files under `data/raw`.
