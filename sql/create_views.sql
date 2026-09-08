USE bank_db;
GO

-- ==========================================
-- FRAUD DETECTION & PREVENTION VIEWS
-- ==========================================

-- Identifies transactions with potential fraud indicators across multiple dimensions
-- Scoring fraud flags

CREATE OR ALTER VIEW gold.vw_fraud_alerts AS
SELECT
    ft.transaction_id,
    ft.date,
    ft.client_id,
    dc.card_id,
    dc.card_brand,
    dc.card_type,
    ft.amount,
    ft.merchant_id,
    ft.merchant_city,
    ft.merchant_state,
    ft.mcc_id,
    dm.Description AS merchant_category,
    ft.errors,
    CASE WHEN ft.amount > 1000 THEN 1 ELSE 0 END AS high_amount_flag,
    CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END AS error_flag,
    CASE WHEN ft.use_chip <> 'Chip Transaction' THEN 1 ELSE 0 END AS chip_anomaly_flag,
    CASE WHEN ft.amount < 0 THEN 1 ELSE 0 END AS negative_amount_flag,
    -- Fraud risk score: sum of all flags
    (CASE WHEN ft.amount > 1000 THEN 1 ELSE 0 END +
     CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END +
     CASE WHEN ft.use_chip <> 'Chip Transaction' THEN 1 ELSE 0 END +
     CASE WHEN ft.amount < 0 THEN 1 ELSE 0 END) AS fraud_risk_score
FROM gold.fact_transactions ft
 JOIN gold.dim_card dc ON ft.card_id = dc.card_id
 JOIN gold.dim_mcc dm ON ft.mcc_id = dm.mcc_id
WHERE ft.amount > 1000
   OR (ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0)
   OR ft.use_chip <> 'Chip Transaction'
   OR ft.amount < 0;
GO

-- Customer risk profiling based on transaction behavior and patterns
-- High value transactions and error counts

CREATE OR ALTER VIEW gold.vw_customer_risk_summary AS
SELECT
    dc.client_id,
    dc.current_age,
    dc.gender,
    COUNT(ft.transaction_id) AS total_transactions,
    ISNULL(AVG(ft.amount), 0) AS avg_transaction_amount,
    SUM(CASE WHEN ft.amount > 1000 THEN 1 ELSE 0 END) AS high_value_transactions,
    SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) AS suspicious_transactions,
    CASE
        WHEN SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) >= 3 THEN 'Critical'
        WHEN SUM(CASE WHEN ft.amount > 1000 THEN 1 ELSE 0 END) >= 2 THEN 'High'
        WHEN ISNULL(AVG(ft.amount), 0) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS risk_tier
FROM gold.dim_customer dc
 JOIN gold.fact_transactions ft ON dc.client_id = ft.client_id
GROUP BY dc.client_id, dc.current_age, dc.gender;
GO

-- Merchant risk profiling with fraud indicators and calculations
-- Error counts for each merchant and error percentage calculation

CREATE OR ALTER VIEW gold.vw_merchant_risk_summary AS
SELECT
    ft.merchant_id,
    ft.merchant_city,
    ft.merchant_state,
    ft.mcc_id,
    dm.Description AS merchant_category,
    COUNT(*) AS total_transactions,
    ISNULL(AVG(ft.amount), 0) AS avg_amount,
    SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) AS fraud_indicators,
    CAST(
        100.0 * SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(*), 0) AS DECIMAL(10,2)
    ) AS fraud_rate_pct
FROM gold.fact_transactions ft
 JOIN gold.dim_mcc dm ON ft.mcc_id = dm.mcc_id
GROUP BY ft.merchant_id, ft.merchant_city, ft.merchant_state, ft.mcc_id, dm.Description;
GO

-- Identifies and scores transaction anomalies for investigation
-- Scoring anomalies (high value transactions, negative transactions, and errors)
CREATE OR ALTER VIEW gold.vw_transaction_anomalies AS
SELECT
    ft.transaction_id,
    ft.client_id,
    ft.card_id,
    ft.date,
    ft.amount,
    ft.merchant_id,
    ft.merchant_city,
    ft.merchant_state,
    ft.mcc_id,
    CASE
        WHEN ft.amount > 1000 THEN 'Large Amount'
        WHEN ft.amount < 0 THEN 'Negative Amount'
        WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 'System Error'
        ELSE 'Normal'
    END AS anomaly_type,
    CASE
        WHEN ft.amount > 1000 THEN 5
        WHEN ft.amount < 0 THEN 4
        WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 3
        ELSE 0
    END AS anomaly_score
FROM gold.fact_transactions ft;
GO

-- Geographic risk analysis by merchant state
CREATE OR ALTER VIEW gold.vw_geo_risk AS
SELECT
    ft.merchant_state,
    COUNT(*) AS transaction_count,
    ISNULL(AVG(ft.amount), 0) AS avg_amount,
    SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) AS suspicious_count,
    CAST(
        100.0 * SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(*), 0) AS DECIMAL(10,2)
    ) AS suspicious_rate_pct
FROM gold.fact_transactions ft
GROUP BY ft.merchant_state;
GO

-- ==========================================
-- MARKETING & PERSONALIZATION
-- ==========================================

-- Customer Profiling: High-net-worth (top 10% income), generational segmentation
-- Gen Z (born 1997-2012), Middle-aged (age 40-59)
CREATE OR ALTER VIEW gold.vw_customer_profiling AS
WITH ClientSpending AS (
    SELECT 
        client_id,
        SUM(amount) AS total_spending,
        AVG(amount) AS avg_transaction_value
    FROM gold.fact_transactions
    WHERE errors IS NULL OR errors = ''
    GROUP BY client_id
),
RankedIncome AS (
    SELECT 
        client_id,
        NTILE(10) OVER (ORDER BY yearly_income DESC) AS income_percentile
    FROM gold.dim_customer
)
SELECT 
    c.client_id,
    c.current_age,
    c.gender,
    c.yearly_income,
    c.total_debt,
    c.credit_score,
    CASE 
        WHEN ri.income_percentile = 1 THEN 'High-Net-Worth'
        ELSE 'Standard'
    END AS customer_value,
    CASE 
        WHEN c.birth_year BETWEEN 1997 AND 2012 THEN 'Gen Z'
        WHEN c.current_age BETWEEN 40 AND 59 THEN 'Middle-Aged'
        ELSE 'Other'
    END AS age_generation,
    COALESCE(s.total_spending, 0) AS total_spending,
    COALESCE(s.avg_transaction_value, 0) AS avg_transaction_value    
FROM gold.dim_customer c
 JOIN ClientSpending s ON c.client_id = s.client_id
 JOIN RankedIncome ri ON c.client_id = ri.client_id;
GO

-- Merchant spending trends: categories with error rates and transaction volumes
CREATE OR ALTER VIEW gold.vw_merchant_spending_trends AS
SELECT 
    m.mcc_id,
    m.Description AS merchant_category,
    SUM(t.amount) AS total_spend,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(CASE WHEN t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0 THEN 1 ELSE 0 END) AS error_count,
    CAST(
        SUM(CASE WHEN t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0 THEN 1.0 ELSE 0.0 END) / 
        NULLIF(COUNT(t.transaction_id), 0) * 100 AS DECIMAL(5,2)
    ) AS error_rate_percentage
FROM gold.fact_transactions t
 JOIN gold.dim_mcc m ON t.mcc_id = m.mcc_id
GROUP BY m.mcc_id, m.Description;
GO

-- Card usage optimization: target high-score customers for limit increases
CREATE OR ALTER VIEW gold.vw_card_usage_optimization AS
SELECT 
    c.client_id,
    c.credit_score,
    cd.credit_limit,
    cd.card_type,
    COUNT(t.transaction_id) AS transaction_frequency,
    SUM(t.amount) AS total_spend_amount,
    CASE 
        -- Credit card candidates for limit increase
        WHEN cd.card_type = 'Credit' 
             AND c.credit_score >= 700 
             AND COUNT(t.transaction_id) < 100 
             AND cd.credit_limit <= 20000 
             THEN 'Target for Credit Limit Increase'
        
        -- Cross-sell opportunity: Non-credit cards with low usage
        WHEN cd.card_type <> 'Credit' 
             AND COUNT(t.transaction_id) < 100 
             AND SUM(t.amount) < 2000 
             THEN 'Promotion/cross-sell needed'
             
        ELSE 'Normal'
    END AS marketing_action
FROM gold.dim_customer c
 JOIN gold.dim_card cd ON c.client_id = cd.client_id
 JOIN gold.fact_transactions t ON cd.card_id = t.card_id
GROUP BY 
    c.client_id, 
    c.credit_score, 
    cd.credit_limit, 
    cd.card_type;
GO

-- Geographic segmentation: purchasing power by region
CREATE OR ALTER VIEW gold.vw_geographic_purchasing_power AS
SELECT 
    CAST(c.latitude AS NUMERIC(9,6)) AS latitude,
    CAST(c.longitude AS NUMERIC(9,6)) AS longitude,
    COUNT(DISTINCT c.client_id) AS customer_count,
    SUM(t.amount) AS total_spend,
    AVG(t.amount) AS avg_transaction
FROM gold.dim_customer c
 JOIN gold.fact_transactions t ON c.client_id = t.client_id
WHERE (t.errors IS NULL OR LEN(LTRIM(RTRIM(t.errors))) = 0)
  AND c.latitude IS NOT NULL 
  AND c.longitude IS NOT NULL
GROUP BY CAST(c.latitude AS NUMERIC(9,6)), CAST(c.longitude AS NUMERIC(9,6));
GO

-- High-potential VIP customers: top 10% income with stable transaction history
CREATE OR ALTER VIEW gold.vw_high_potential_vip AS
WITH CustomerStability AS (
    SELECT 
        client_id,
        COUNT(transaction_id) AS tx_count,
        STDEV(amount) AS spend_volatility
    FROM gold.fact_transactions
    GROUP BY client_id
),
IncomeRanking AS (
    SELECT 
        client_id,
        yearly_income,
        credit_score,
        PERCENT_RANK() OVER (ORDER BY yearly_income DESC) AS income_rank
    FROM gold.dim_customer
)
SELECT 
    ir.client_id,
    ir.yearly_income,
    ir.credit_score,
    ISNULL(cs.tx_count, 0) AS tx_count,
    cs.spend_volatility
FROM IncomeRanking ir
 JOIN CustomerStability cs ON ir.client_id = cs.client_id
WHERE ir.income_rank <= 0.10 AND ISNULL(cs.tx_count, 0) >= 100;
GO


-- ==========================================
-- TRACK 2: RISK MANAGEMENT & CREDIT
-- ==========================================

-- Non-performing loan alert: Debt-to-Income analysis with credit tier assessment
CREATE OR ALTER VIEW gold.vw_npl_dti_warning AS
SELECT 
    client_id,
    yearly_income,
    total_debt,
    credit_score,
    CASE 
        WHEN yearly_income = 0 THEN 0
        ELSE CAST((CAST(total_debt AS DECIMAL(18,2)) / CAST(yearly_income AS DECIMAL(18,2))) * 100 AS DECIMAL(5,2))
    END AS dti_ratio_percentage,
    CASE 
        WHEN (yearly_income > 0 AND (CAST(total_debt AS DECIMAL(18,2)) / CAST(yearly_income AS DECIMAL(18,2))) > 0.40) 
             AND credit_score < 600 THEN 'CRITICAL ALERT: High DTI & Low Credit'
        WHEN (yearly_income > 0 AND (CAST(total_debt AS DECIMAL(18,2)) / CAST(yearly_income AS DECIMAL(18,2))) > 0.40) THEN 'Warning: High DTI'
        ELSE 'Safe'
    END AS risk_status
FROM gold.dim_customer;
GO

-- Fraud detection: flags high-value transactions, anomaly spikes, and location mismatches
CREATE OR ALTER VIEW gold.vw_fraud_detection AS
WITH ClientBaseline AS (
    SELECT 
        client_id,
        AVG(amount) AS avg_transaction_amount
    FROM gold.fact_transactions
    WHERE errors IS NULL OR errors = ''
    GROUP BY client_id
)
SELECT 
    t.transaction_id,
    t.date,
    t.client_id,
    t.amount,
    t.merchant_city,
    t.merchant_state,
    CASE 
        WHEN ABS(t.amount) > 1000 THEN 'High Value Absolute Spending Alert'
        WHEN t.amount > 5000 THEN 'Anomalously High Amount Spike'
        WHEN t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0 THEN 'Transaction Error Detected'
        ELSE 'Potential Fraud Indicator'
    END AS fraud_indicator_reason
FROM gold.fact_transactions t
 JOIN gold.dim_customer c ON t.client_id = c.client_id
 JOIN ClientBaseline cb ON t.client_id = cb.client_id
WHERE ABS(t.amount) > 1000 
   OR t.amount > 5000 
   OR (t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0);
GO

-- Transaction error analysis: systemic failures by card brand/type
CREATE OR ALTER VIEW gold.vw_transaction_error_analysis AS
SELECT 
    cd.card_brand,
    cd.card_type,
    t.errors AS error_message,
    COUNT(t.transaction_id) AS error_occurrence_count,
    SUM(t.amount) AS disrupted_volume
FROM gold.fact_transactions t
 JOIN gold.dim_card cd ON t.card_id = cd.card_id
WHERE t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0
GROUP BY cd.card_brand, cd.card_type, t.errors;
GO

-- Portfolio risk assessment: credit score tiers with system risk exposure metrics
CREATE OR ALTER VIEW gold.vw_portfolio_risk_assessment AS
SELECT 
    CASE 
        WHEN c.credit_score >= 800 THEN 'Exceptional (800-850)'
        WHEN c.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        WHEN c.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN c.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        ELSE 'Poor (300-579)'
    END AS credit_score_bucket,
    COUNT(DISTINCT c.client_id) AS customer_count,
    ISNULL(SUM(c.total_debt), 0) AS aggregate_outstanding_debt,
    ISNULL(SUM(cd.credit_limit), 0) AS aggregate_granted_limit,
    CAST(
        ISNULL(SUM(c.total_debt), 0) * 100.0 / NULLIF(SUM(cd.credit_limit), 0) AS DECIMAL(5,2)
    ) AS credit_exposure_ratio_percentage
FROM gold.dim_customer c
 JOIN gold.dim_card cd ON c.client_id = cd.client_id
GROUP BY 
    CASE 
        WHEN c.credit_score >= 800 THEN 'Exceptional (800-850)'
        WHEN c.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        WHEN c.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN c.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        ELSE 'Poor (300-579)'
    END;
GO

-- Strategic credit recommendations: ideal candidates for limit increases
CREATE OR ALTER VIEW gold.vw_strategic_credit_recommendations AS
SELECT 
    c.client_id,
    c.yearly_income,
    c.total_debt,
    c.credit_score,
    cd.card_id,
    cd.credit_limit AS current_limit,
    CAST(cd.credit_limit * 1.25 AS INT) AS recommended_new_limit,
    'Increase Limit 25% - Positive Profile' AS policy_action
FROM gold.dim_customer c
LEFT JOIN gold.dim_card cd ON c.client_id = cd.client_id
WHERE c.total_debt = 0 
  AND c.credit_score >= 720 
  AND cd.card_type = 'Credit'
  AND cd.credit_limit > 0;
GO

-- ==========================================
-- PERFORMANCE ANALYSIS VIEWS
-- ==========================================

-- Transaction performance metrics: volumes, success rates, chip adoption, error patterns
CREATE OR ALTER VIEW gold.vw_transaction_performance AS
WITH DailyTransactionMetrics AS (
    SELECT 
        CAST(ft.date AS DATE) AS transaction_date,
        YEAR(ft.date) AS transaction_year,
        MONTH(ft.date) AS transaction_month,
        DATEPART(WEEK, ft.date) AS transaction_week,
        ft.use_chip,
        COUNT(ft.transaction_id) AS transaction_count,
        SUM(ft.amount) AS total_volume,
        AVG(ft.amount) AS avg_amount,
        MIN(ft.amount) AS min_amount,
        MAX(ft.amount) AS max_amount,
        SUM(CASE WHEN ft.errors IS NULL OR LEN(LTRIM(RTRIM(ft.errors))) = 0 THEN 1 ELSE 0 END) AS successful_transactions,
        SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) AS failed_transactions,
        SUM(CASE WHEN ABS(ft.amount) > 1000 THEN 1 ELSE 0 END) AS high_value_transactions,
        SUM(CASE WHEN ft.amount < 0 THEN 1 ELSE 0 END) AS negative_amount_count
    FROM gold.fact_transactions ft
    GROUP BY CAST(ft.date AS DATE), YEAR(ft.date), MONTH(ft.date), DATEPART(WEEK, ft.date), ft.use_chip
)
SELECT 
    transaction_date,
    transaction_year,
    transaction_month,
    transaction_week,
    use_chip,
    transaction_count,
    total_volume,
    avg_amount,
    min_amount,
    max_amount,
    successful_transactions,
    failed_transactions,
    high_value_transactions,
    negative_amount_count,
    CAST(100.0 * successful_transactions / NULLIF(transaction_count, 0) AS DECIMAL(5,2)) AS success_rate_pct,
    CAST(100.0 * failed_transactions / NULLIF(transaction_count, 0) AS DECIMAL(5,2)) AS failure_rate_pct,
    CASE 
        WHEN use_chip = 'Chip Transaction' THEN 'Chip'
        ELSE 'Non-Chip'
    END AS chip_category,
    CASE 
        WHEN CAST(100.0 * successful_transactions / NULLIF(transaction_count, 0) AS DECIMAL(5,2)) >= 99 THEN 'Excellent'
        WHEN CAST(100.0 * successful_transactions / NULLIF(transaction_count, 0) AS DECIMAL(5,2)) >= 95 THEN 'Good'
        WHEN CAST(100.0 * successful_transactions / NULLIF(transaction_count, 0) AS DECIMAL(5,2)) >= 90 THEN 'Fair'
        ELSE 'Poor'
    END AS performance_tier
FROM DailyTransactionMetrics
ORDER BY transaction_date DESC, use_chip;
GO

-- Card performance metrics: utilization, activity, and operational health by card
CREATE OR ALTER VIEW gold.vw_card_performance AS
WITH CardMetrics AS (
    SELECT 
        dc.card_id,
        dc.client_id,
        dc.card_brand,
        dc.card_type,
        dc.credit_limit,
        dc.acct_open_date,
        DATEDIFF(DAY, dc.acct_open_date, CAST(GETDATE() AS DATE)) AS days_active,
        COUNT(ft.transaction_id) AS total_transactions,
        SUM(ft.amount) AS total_spending,
        AVG(ft.amount) AS avg_transaction_amount,
        MAX(ft.amount) AS max_transaction_amount,
        COUNT(DISTINCT CAST(ft.date AS DATE)) AS active_days,
        SUM(CASE WHEN ft.errors IS NULL OR LEN(LTRIM(RTRIM(ft.errors))) = 0 THEN 1 ELSE 0 END) AS successful_txns,
        SUM(CASE WHEN ft.errors IS NOT NULL AND LEN(LTRIM(RTRIM(ft.errors))) > 0 THEN 1 ELSE 0 END) AS failed_txns,
        SUM(CASE WHEN ft.use_chip = 'Chip Transaction' THEN 1 ELSE 0 END) AS chip_transactions,
        SUM(CASE WHEN ft.use_chip <> 'Chip Transaction' THEN 1 ELSE 0 END) AS non_chip_transactions,
        MIN(ft.date) AS first_transaction_date,
        MAX(ft.date) AS last_transaction_date
    FROM gold.dim_card dc
    LEFT JOIN gold.fact_transactions ft ON dc.card_id = ft.card_id
    GROUP BY dc.card_id, dc.client_id, dc.card_brand, dc.card_type, dc.credit_limit, dc.acct_open_date
)
SELECT 
    card_id,
    client_id,
    card_brand,
    card_type,
    credit_limit,
    acct_open_date,
    days_active,
    total_transactions,
    total_spending,
    avg_transaction_amount,
    max_transaction_amount,
    active_days,
    successful_txns,
    failed_txns,
    chip_transactions,
    non_chip_transactions,
    first_transaction_date,
    last_transaction_date,
    CASE 
        WHEN credit_limit > 0 THEN CAST(100.0 * total_spending / credit_limit AS DECIMAL(5,2))
        ELSE 0
    END AS credit_utilization_pct,
    CASE 
        WHEN total_transactions > 0 THEN CAST(100.0 * successful_txns / total_transactions AS DECIMAL(5,2))
        ELSE 0
    END AS success_rate_pct,
    CASE 
        WHEN total_transactions > 0 THEN CAST(100.0 * chip_transactions / total_transactions AS DECIMAL(5,2))
        ELSE 0
    END AS chip_adoption_pct,
    CASE 
        WHEN days_active > 0 THEN CAST(CAST(total_transactions AS DECIMAL(10,2)) / days_active AS DECIMAL(5,2))
        ELSE 0
    END AS txn_per_day_rate,
    CASE 
        WHEN total_spending >= credit_limit * 0.8 THEN 'High Utilization'
        WHEN total_spending >= credit_limit * 0.5 THEN 'Medium Utilization'
        WHEN total_spending > 0 THEN 'Low Utilization'
        ELSE 'Inactive'
    END AS utilization_tier,
    CASE 
        WHEN total_transactions = 0 THEN 'Inactive'
        WHEN total_transactions > 0 AND CAST(100.0 * successful_txns / total_transactions AS DECIMAL(5,2)) >= 98 THEN 'Healthy'
        WHEN total_transactions > 0 AND CAST(100.0 * successful_txns / total_transactions AS DECIMAL(5,2)) >= 90 THEN 'Operational'
        ELSE 'Problematic'
    END AS card_health_status
FROM CardMetrics
ORDER BY card_id;
GO