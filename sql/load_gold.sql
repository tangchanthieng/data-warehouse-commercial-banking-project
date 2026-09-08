USE bank_db;
GO

-- STEP 1: Always empty the Fact (dependent) table FIRST to clear active references
TRUNCATE TABLE gold.fact_transactions;

-- STEP 2: Now you can safely clear and reload your Dimension tables
DELETE FROM gold.dim_card;
DELETE FROM gold.dim_customer;
DELETE FROM gold.dim_mcc;

-- STEP 3: Reload Dimension Layers from Silver tables
INSERT INTO gold.dim_customer SELECT * FROM silver.user_clean;
INSERT INTO gold.dim_card SELECT * FROM silver.card_clean;
INSERT INTO gold.dim_mcc SELECT * FROM silver.mcc_clean;

-- STEP 4: Reload Fact Layer from Silver tables
INSERT INTO gold.fact_transactions (
    transaction_id, 
    date, 
    client_id, 
    card_id, 
    amount, 
    use_chip, 
    merchant_id, 
    merchant_city,
    merchant_state,
    zip,
    mcc_id,
    errors)
SELECT transaction_id, date, client_id, card_id, amount, use_chip, merchant_id, merchant_city, merchant_state, zip, mcc_id, errors 
FROM silver.transaction_clean;
GO