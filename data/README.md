# Data Folder

This folder stores the project datasets used throughout the data warehouse pipeline.

## Subfolders

- `raw/` — original source files as received.
- `clean/` — cleaned and standardized data ready for transformation.
- `staging/` — intermediate staged files prepared for loading into the warehouse.

## Notes

- Keep raw files unchanged for auditability.
- Use the cleaned and staging layers for downstream processing.
- Refresh data only through the defined ETL workflow.
