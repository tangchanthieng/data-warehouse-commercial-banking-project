import pyodbc
from contextlib import contextmanager
import logging
from config import CONN_STR

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

@contextmanager
def get_db_connection():
    conn = pyodbc.connect(CONN_STR)
    cursor = conn.cursor()
    try:
        yield cursor
        conn.commit()
    except Exception as e:
        conn.rollback()
        logging.error(f"Database transaction failed: {str(e)}")
        raise e
    finally:
        cursor.close()
        conn.close()

def execute_sql_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        sql_commands = f.read().split('GO')
        
    with get_db_connection() as cursor:
        for command in sql_commands:
            if command.strip():
                cursor.execute(command)
        logging.info(f"Successfully executed scripts from {file_path}")





        