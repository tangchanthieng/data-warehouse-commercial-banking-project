"""Generate a relational transaction snapshot from the source CSV files."""

import argparse
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd

from config import DATA_DIR, RAW_DIR


TRANSACTION_COLUMNS = [
    "transaction_id",
    "date",
    "client_id",
    "card_id",
    "amount",
    "use_chip",
    "merchant_id",
    "merchant_city",
    "merchant_state",
    "zip",
    "mcc_id",
    "errors",
]


def _read_source_files(source_dir: Path) -> tuple[pd.DataFrame, ...]:
    file_names = ("users_data.csv", "cards_data.csv", "mcc_codes.csv", "transactions_data.csv")
    paths = [source_dir / file_name for file_name in file_names]
    missing = [str(path) for path in paths if not path.exists()]
    if missing:
        raise FileNotFoundError(f"Missing source file(s): {', '.join(missing)}")

    return tuple(pd.read_csv(path) for path in paths)


def _require_columns(data: pd.DataFrame, required: set[str], file_name: str) -> None:
    missing = required.difference(data.columns)
    if missing:
        names = ", ".join(sorted(missing))
        raise ValueError(f"{file_name} is missing required column(s): {names}")


def generate_transactions(
    rows: int,
    source_dir: Path = RAW_DIR,
    output_dir: Path = RAW_DIR,
    output_date: datetime | None = None,
    seed: int | None = None,
) -> Path:
    """Generate and save transaction rows with valid dimension relationships."""
    if rows < 1:
        raise ValueError("rows must be greater than zero")

    users, cards, mcc_codes, transactions = _read_source_files(source_dir)
    _require_columns(users, {"client_id"}, "users_data.csv")
    _require_columns(cards, {"card_id", "client_id"}, "cards_data.csv")
    _require_columns(mcc_codes, {"mcc_id"}, "mcc_codes.csv")
    _require_columns(transactions, set(TRANSACTION_COLUMNS), "transactions_data.csv")

    valid_clients = set(users["client_id"].dropna())
    valid_cards = cards[cards["client_id"].isin(valid_clients)][["card_id", "client_id"]].dropna()
    valid_cards = valid_cards.drop_duplicates(subset="card_id")
    valid_mcc_ids = mcc_codes["mcc_id"].dropna().drop_duplicates().to_numpy()

    if valid_cards.empty:
        raise ValueError("cards_data.csv contains no cards linked to users_data.csv")
    if len(valid_mcc_ids) == 0:
        raise ValueError("mcc_codes.csv contains no usable mcc_id values")

    rng = np.random.default_rng(seed)
    card_rows = valid_cards.iloc[rng.integers(0, len(valid_cards), size=rows)].reset_index(drop=True)
    transaction_templates = transactions.iloc[
        rng.integers(0, len(transactions), size=rows)
    ].reset_index(drop=True)

    generated = transaction_templates.copy()
    generated["transaction_id"] = np.arange(
        pd.to_numeric(transactions["transaction_id"], errors="raise").max() + 1,
        pd.to_numeric(transactions["transaction_id"], errors="raise").max() + rows + 1,
        dtype="int64",
    )
    generated["client_id"] = card_rows["client_id"].to_numpy()
    generated["card_id"] = card_rows["card_id"].to_numpy()
    generated["mcc_id"] = rng.choice(valid_mcc_ids, size=rows)

    output_dir.mkdir(parents=True, exist_ok=True)
    date_suffix = (output_date or datetime.now()).strftime("%d%m%y")
    output_path = output_dir / f"transactions_{date_suffix}.csv"
    generated[TRANSACTION_COLUMNS].to_csv(output_path, index=False)
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=int, default=None, help="Number of rows to generate (default: source row count)")
    parser.add_argument("--source-dir", type=Path, default=RAW_DIR)
    parser.add_argument("--output-dir", type=Path, default=RAW_DIR)
    parser.add_argument("--seed", type=int, default=None, help="Optional random seed for reproducible output")
    args = parser.parse_args()

    source_transactions = pd.read_csv(args.source_dir / "transactions_data.csv")
    rows = len(source_transactions) if args.rows is None else args.rows
    output_path = generate_transactions(rows, args.source_dir, args.output_dir, seed=args.seed)
    print(f"Generated {rows} transaction rows: {output_path}")


if __name__ == "__main__":
    main()