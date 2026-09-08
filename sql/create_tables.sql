USE bank_db;
GO

CREATE TABLE bronze.user_raw (
    client_id INT, 
    current_age INT, 
    retirement_age INT,
    birth_year INT, 
    birth_month INT, 
    gender VARCHAR(50),
    address VARCHAR(255), 
    latitude DECIMAL(18,6), 
    longitude DECIMAL(18,6),
    per_capita_income VARCHAR(50), 
    yearly_income VARCHAR(50), 
    total_debt VARCHAR(50),
    credit_score INT, 
    num_credit_cards INT
);

CREATE TABLE bronze.card_raw (
    card_id INT, 
    client_id INT, 
    card_brand VARCHAR(100),
    card_type VARCHAR(100), 
    card_number BIGINT, 
    expires DATE, 
    cvv INT, 
    has_chip VARCHAR(50), 
    num_cards_issued INT,
    credit_limit VARCHAR(50), 
    acct_open_date DATE, 
    year_pin_last_changed INT
);

CREATE TABLE bronze.transaction_raw (
    transaction_id INT, 
    date DATETIME, 
    client_id INT,
    card_id INT, 
    amount DECIMAL(18,6), 
    use_chip VARCHAR(50),
    merchant_id INT, 
    merchant_city VARCHAR(100), 
    merchant_state VARCHAR(100),
    zip VARCHAR(50), 
    mcc_id INT, 
    errors VARCHAR(100)
);

CREATE TABLE bronze.mcc_raw (
    mcc_id INT,
    Description VARCHAR(255)
);
GO

-- Create silver tables
USE bank_db;
GO

CREATE TABLE silver.user_clean (
    client_id INT PRIMARY KEY,
    current_age INT, 
    retirement_age INT,
    birth_year INT, 
    birth_month INT, 
    gender VARCHAR(50),
    address VARCHAR(255), 
    latitude DECIMAL(18,6), 
    longitude DECIMAL(18,6),
    per_capita_income INT, 
    yearly_income INT, 
    total_debt INT,
    credit_score INT, 
    num_credit_cards INT
);

CREATE TABLE silver.card_clean (
    card_id INT PRIMARY KEY,
    client_id INT, 
    card_brand VARCHAR(100),
    card_type VARCHAR(100), 
    card_number BIGINT, 
    expires DATE, 
    cvv INT, 
    has_chip VARCHAR(50), 
    num_cards_issued INT,
    credit_limit INT, 
    acct_open_date DATE, 
    year_pin_last_changed INT
);

CREATE TABLE silver.transaction_clean (
    transaction_id INT PRIMARY KEY,
    date DATETIME, 
    client_id INT,
    card_id INT, 
    amount DECIMAL(18,6), 
    use_chip VARCHAR(50),
    merchant_id INT, 
    merchant_city VARCHAR(100), 
    merchant_state VARCHAR(100),
    zip INT, 
    mcc_id INT, 
    errors VARCHAR(100)
);

CREATE TABLE silver.mcc_clean (
    mcc_id INT PRIMARY KEY,
    Description VARCHAR(255)
);
GO

-- Create gold tables
USE bank_db;
GO

-- 1. MCC Dimension
CREATE TABLE gold.dim_mcc (
    mcc_id INT PRIMARY KEY,
    Description VARCHAR(255)
);

-- 2. Customer Dimension
CREATE TABLE gold.dim_customer (
    client_id INT PRIMARY KEY,
    current_age INT, 
    retirement_age INT,
    birth_year INT, 
    birth_month INT, 
    gender VARCHAR(50),
    address VARCHAR(255), 
    latitude DECIMAL(18,6), 
    longitude DECIMAL(18,6),
    per_capita_income INT, 
    yearly_income INT, 
    total_debt INT,
    credit_score INT, 
    num_credit_cards INT
);

-- 3. Card Dimension
CREATE TABLE gold.dim_card (
    card_id INT PRIMARY KEY,
    client_id INT, 
    card_brand VARCHAR(100),
    card_type VARCHAR(100), 
    card_number BIGINT, 
    expires DATE, 
    cvv INT, 
    has_chip VARCHAR(50), 
    num_cards_issued INT,
    credit_limit INT, 
    acct_open_date DATE, 
    year_pin_last_changed INT,
    FOREIGN KEY (client_id) REFERENCES gold.dim_customer(client_id)
);

-- 5. Fact Transactions
CREATE TABLE gold.fact_transactions (
    transaction_id INT PRIMARY KEY, 
    date DATETIME, 
    client_id INT,
    card_id INT, 
    amount DECIMAL(18,6), 
    use_chip VARCHAR(50), 
    merchant_id INT,
    merchant_city VARCHAR(100), 
    merchant_state VARCHAR(50), 
    zip VARCHAR(50),
    mcc_id INT, 
    errors VARCHAR(255),
    FOREIGN KEY (client_id) REFERENCES gold.dim_customer(client_id),
    FOREIGN KEY (card_id) REFERENCES gold.dim_card(card_id),
    FOREIGN KEY (mcc_id) REFERENCES gold.dim_mcc(mcc_id)
);
GO