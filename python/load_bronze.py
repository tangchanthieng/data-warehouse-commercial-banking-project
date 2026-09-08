import pandas as pd
import numpy as np
from database import get_db_connection
from config import STAGING_DIR

def bulk_insert_to_bronze():
    file_mapping = {
        'stg_user.csv': 'bronze.user_raw',
        'stg_card.csv': 'bronze.card_raw',
        'stg_transaction.csv': 'bronze.transaction_raw',
        'stg_mcc.csv': 'bronze.mcc_raw'
    }
    
    with get_db_connection() as cursor:
        for file_name, table in file_mapping.items():
            df = pd.read_csv(STAGING_DIR / file_name)
            
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
            print(f"Loaded {len(df)} records into raw table {table}")

if __name__ == "__main__":
    bulk_insert_to_bronze()