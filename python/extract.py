import pandas as pd
import logging
from config import RAW_DIR, STAGING_DIR

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def extract_raw_csvs():
    files = ['user.csv', 'card.csv', 'transaction.csv', 'mcc.csv']
    extracted_data = {}
    
    for file in files:
        raw_path = RAW_DIR / file
        if not raw_path.exists():
            raise FileNotFoundError(f"Missing raw asset: {raw_path}")
        
        logging.info(f"Extracting {file} to staging zone...")
        df = pd.read_csv(raw_path)
        
        # Save exact copy to staging area
        staging_path = STAGING_DIR / f"stg_{file}"
        df.to_csv(staging_path, index=False)
        extracted_data[file.replace('.csv', '')] = df
        
    logging.info("Extraction phase completed successfully.")
    return extracted_data

if __name__ == "__main__":
    extract_raw_csvs()