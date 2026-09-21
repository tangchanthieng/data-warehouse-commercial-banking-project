# Python Scripts

This folder contains the ETL and transformation code for the data warehouse project.

## Main areas

- `extract.py` — extracts source data.
- `load_bronze.py` — loads raw/bronze-layer data.
- `load_silver.py` — processes silver-layer transformations.
- `transformation_silver.py` — contains business logic for silver transformations.
- `validate.py` — validates data quality.
- `database.py` and `config.py` — database and configuration support.
- `utils.py` — reusable helper functions.

## Workflow

Run the scripts in the sequence used by the pipeline to move data from extraction to warehouse-ready forms.
