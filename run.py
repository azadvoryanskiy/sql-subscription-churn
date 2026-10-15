"""Build the database, run the checks, answer the six questions.

    python run.py

Reads the KKBox CSVs from data/raw, writes data/kkbox.duckdb (about 1 GB) and
one CSV per question into results/. Takes under a minute.
"""
from pathlib import Path

import duckdb

ROOT = Path(__file__).parent
BUILD_STEPS = ["01_load.sql", "02_subscriptions.sql", "03_subscriber_months.sql"]


def main():
    con = duckdb.connect(str(ROOT / "data" / "kkbox.duckdb"))
    con.execute("SET memory_limit = '6GB'")

    for step in BUILD_STEPS:
        print(f"building  {step}")
        con.execute((ROOT / "sql" / step).read_text())

    checks = con.extract_statements((ROOT / "sql" / "checks.sql").read_text())
    for number, check in enumerate(checks, start=1):
        bad_rows = con.execute(check).fetchall()
        if bad_rows:
            raise SystemExit(f"check {number} failed: {len(bad_rows)} rows, e.g. {bad_rows[0]}")
        print(f"check {number}   passed")

    (ROOT / "results").mkdir(exist_ok=True)
    for query in sorted((ROOT / "sql" / "questions").glob("q*.sql")):
        result = con.sql(query.read_text()).df()
        result.to_csv(ROOT / "results" / f"{query.stem}.csv", index=False)
        print(f"\n{query.stem}\n{result.to_string(index=False)}")


if __name__ == "__main__":
    main()
