USE bank_db
GO

-- ===============================================================
-- OPERATION VIEWS - CUSTOMER PROFILING AND TRANSACTION MONITORING
-- ===============================================================

-- ======================================================================================
-- Transaction performance metrics: volumes, success rates, chip adoption, error patterns
-- ======================================================================================

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
        SUM(CASE WHEN ABS(ft.amount) > 1000 THEN 1 ELSE 0 END) AS high_value_transactions
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
GO

-- ====================================================================
-- Customer Profiling: High-net-worth (top 10% income) and segmentation 
-- ====================================================================

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

-- ===================================================
-- Geographic segmentation: purchasing power by region
-- ===================================================

CREATE OR ALTER VIEW gold.vw_geographic_purchasing_power AS
SELECT 
    t.merchant_state,
    t.merchant_city,
    COUNT(DISTINCT t.client_id) AS customer_count,
    SUM(t.amount) AS total_spend,
    AVG(t.amount) AS avg_transaction
FROM gold.fact_transactions t
WHERE (t.errors IS NULL OR LEN(LTRIM(RTRIM(t.errors))) = 0)
GROUP BY t.merchant_state, t.merchant_city;
GO

-- ===============================================================
-- Card usage optimization: target customers for marketing actions
-- ===============================================================

CREATE OR ALTER VIEW gold.vw_card_usage_optimization AS
SELECT 
    c.client_id,
    cd.acct_open_date,
    c.credit_score,
    cd.credit_limit,
    cd.card_type,
    COUNT(t.transaction_id) AS transaction_frequency,
    SUM(t.amount) AS total_spend_amount,
    CASE 
        -- Credit card candidates for limit increase
        WHEN cd.card_type = 'Credit' 
             AND c.credit_score >= 650 
             AND COUNT(t.transaction_id) > 100 
             AND cd.credit_limit <= AVG(cd.credit_limit) 
             THEN 'Target for Credit Limit Increase'
        
        -- Credit promo opportunity: Non-credit cards with high transaction amount
        WHEN cd.card_type <> 'Credit' 
             AND COUNT(t.transaction_id) > 50 
             AND SUM(t.amount) > 1000 
             THEN 'Credit promotions needed'

        -- Cross-sell opportunity: New products available
        WHEN COUNT(t.transaction_id) > 100
             AND SUM(t.amount) > 1000
             THEN 'Cross-sell promotions needed'
             
        ELSE 'Standard'
    END AS marketing_action
FROM gold.dim_customer c
 JOIN gold.dim_card cd ON c.client_id = cd.client_id
 JOIN gold.fact_transactions t ON cd.card_id = t.card_id
GROUP BY 
    c.client_id, 
    c.credit_score, 
    cd.credit_limit, 
    cd.card_type,
    cd.acct_open_date;
GO

-- =====================================================================
-- Which customers have elevated debt-to-income or credit exposure risk?
-- =====================================================================

CREATE OR ALTER VIEW gold.vw_business_credit_risk AS
WITH CardExposure AS (
    SELECT
        client_id,
        SUM(credit_limit) AS total_credit_limit
    FROM gold.dim_card
    GROUP BY client_id
)
SELECT
    c.client_id,
    c.yearly_income,
    c.total_debt,
    c.credit_score,
    COALESCE(ce.total_credit_limit, 0) AS total_credit_limit,
    
    -- calculate credit index: 
    CAST(CASE WHEN c.yearly_income > 0
              THEN 100.0 * c.total_debt / c.yearly_income ELSE 0 END AS DECIMAL(10,2)) AS DTI,
    CAST(CASE WHEN COALESCE(ce.total_credit_limit, 0) > 0
              THEN 100.0 * c.total_debt / ce.total_credit_limit ELSE 0 END AS DECIMAL(10,2)) AS credit_exposure_pct,
    -- credit tiers:
    CASE
        WHEN c.credit_score <= 450 THEN 'High risk'
        WHEN c.credit_score > 450 AND c.credit_score <= 650 THEN 'Moderate risk'
        ELSE 'Lower risk'
    END AS credit_risk_tier,

    CASE
        WHEN c.total_debt > c.yearly_income * 0.40 THEN 'High risk'
        WHEN c.total_debt > c.yearly_income * 0.25 THEN 'Moderate risk'
        ELSE 'Lower risk'
    END AS debt_income_risk
FROM gold.dim_customer AS c
 JOIN CardExposure AS ce ON ce.client_id = c.client_id;
GO

-- =============================================================================
-- Merchant risk patterns: categories with error rates and transaction volumes
-- =============================================================================

CREATE OR ALTER VIEW gold.vw_merchant_risk_exposure AS
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

-- ==================================================================================
-- Identifies transactions with potential fraud indicators across multiple dimensions
-- ==================================================================================

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

-- =======================================
-- Geographic error risk: errors by region
-- =======================================

CREATE OR ALTER VIEW gold.vw_geographic_risk_exposure AS
SELECT 
    t.merchant_state,
    t.merchant_city,
    SUM(t.amount) AS total_spend,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(CASE WHEN t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0 THEN 1 ELSE 0 END) AS error_count,
    CAST(
        SUM(CASE WHEN t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0 THEN 1.0 ELSE 0.0 END) / 
        NULLIF(COUNT(t.transaction_id), 0) * 100 AS DECIMAL(5,2)
    ) AS error_rate_percentage
FROM gold.fact_transactions t
GROUP BY t.merchant_state, t.merchant_city
HAVING SUM(CASE WHEN t.errors IS NOT NULL AND LEN(LTRIM(RTRIM(t.errors))) > 0 THEN 1 ELSE 0 END) > 0;
GO