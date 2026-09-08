import pandas as pd
import logging
from config import STAGING_DIR

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def validate_staging_data():
    logging.info("Starting Data Profiling and Quality Validation...")
    
    validations = {
        'user': {
            'pk': 'client_id',
            'not_null': [
                'client_id', 'current_age', 'retirement_age', 'birth_year', 'birth_month',
                'gender', 'address', 'latitude', 'longitude', 'per_capita_income',
                'yearly_income', 'total_debt', 'credit_score', 'num_credit_cards'
            ]
        },
        'card': {
            'pk': 'card_id',
            'not_null': [
                'card_id', 'client_id', 'card_brand', 'card_type', 'card_number', 'expires',
                'cvv', 'has_chip', 'num_cards_issued', 'credit_limit', 'acct_open_date',
                'year_pin_last_changed'
            ]
        },
        'transaction': {
            'pk': 'transaction_id',
            'not_null': [
                'transaction_id', 'date', 'client_id', 'card_id', 'amount', 'use_chip',
                'merchant_id', 'merchant_city', 'merchant_state', 'zip', 'mcc_id', 'errors'
            ]
        },
        'mcc': {
            'pk': 'mcc_id',
            'not_null': ['mcc_id', 'Description']
        }
    }
    
    pipeline_passed = True
    for entity, rules in validations.items():
        df = pd.read_csv(STAGING_DIR / f"stg_{entity}.csv")

        null_columns = []
        for col in rules['not_null']:
            if col not in df.columns:
                logging.warning(f"[DQ RULE WARNING] {entity}.{col} is missing from staging file.")
                continue
            null_count = int(df[col].isnull().sum())
            if null_count > 0:
                null_columns.append((col, null_count))

        if null_columns:
            columns_str = ", ".join(f"{col}={count}" for col, count in null_columns)
            logging.warning(f"[DQ RULE FAILED] {entity} contains nulls in columns: {columns_str}")

        pk = rules['pk']
        if pk not in df.columns:
            logging.error(f"[DQ CRITICAL CLEARANCE FAILED] Primary key column {entity}.{pk} is missing from staging file.")
            pipeline_passed = False
        else:
            duplicate_count = int(df[pk].duplicated().sum())
            if duplicate_count > 0:
                logging.error(f"[DQ CRITICAL CLEARANCE FAILED] {entity}.{pk} contains {duplicate_count} duplicate values.")
                pipeline_passed = False
            else:
                logging.info(f"{entity}.{pk} passed primary key duplication check.")

    if pipeline_passed:
        logging.info("Staging datasets passed data quality validation constraints.")
    return pipeline_passed

if __name__ == "__main__":
    validate_staging_data()