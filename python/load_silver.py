import pandas as pd
import numpy as np
from database import get_db_connection
from config import PROCESSED_DIR

def bulk_insert_to_silver():
    file_mapping = {
        'clean_users.csv': 'silver.user_clean',
        'clean_cards.csv': 'silver.card_clean',
        'clean_transactions.csv': 'silver.transaction_clean',
        'clean_mcc.csv': 'silver.mcc_clean'
    }
    
    with get_db_connection() as cursor:
        for file_name, table in file_mapping.items():
            df = pd.read_csv(PROCESSED_DIR / file_name)
            
            # Replace NaN/Null with None to preserve NULL semantics in SQL inserts
            df = df.replace({np.nan: None})
            data_to_insert = [
                [None if pd.isna(val) else val for val in row]
                for row in df.values.tolist()
            ]
            
            cursor.execute(f"TRUNCATE TABLE {table}")
            cols = ", ".join(df.columns)
            placeholders = ", ".join(["?"] * len(df.columns))
            sql = f"INSERT INTO {table} ({cols}) VALUES ({placeholders})"
            cursor.executemany(sql, data_to_insert)
            print(f"Loaded {len(df)} records into silver table {table}")

if __name__ == "__main__":
    bulk_insert_to_silver()