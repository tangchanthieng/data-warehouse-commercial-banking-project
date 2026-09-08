import os
from pathlib import Path

# File System Paths
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
RAW_DIR = DATA_DIR / "raw"
STAGING_DIR = DATA_DIR / "staging"
PROCESSED_DIR = DATA_DIR / "clean"

# Database Configuration (SQL Server Express)
DB_CONFIG = {
    "driver": "ODBC Driver 17 for SQL Server",
    "server": r".\SQLEXPRESS",
    "database": "bank_db",
    "trusted_connection": "yes"
}

CONN_STR = f"DRIVER={DB_CONFIG['driver']};SERVER={DB_CONFIG['server']};DATABASE={DB_CONFIG['database']};Trusted_Connection={DB_CONFIG['trusted_connection']};"

# Ensure directories exist
for folder in [RAW_DIR, STAGING_DIR, PROCESSED_DIR]:
    folder.mkdir(parents=True, exist_ok=True)