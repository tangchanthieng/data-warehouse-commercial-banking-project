# Staging Data

This folder contains intermediate files produced after validation and before warehouse loading.

## Purpose

- Hold data in a near-final structure.
- Support incremental loading and testing.
- Provide a handoff point between transformation and final warehouse processes.

## Typical files

- `stg_card.csv`
- `stg_mcc.csv`
- `stg_transaction.csv`
- `stg_user.csv`
