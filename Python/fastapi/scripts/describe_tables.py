from pathlib import Path
import sys

from sqlalchemy import inspect

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.db.session import engine


TARGET_TABLES = [
    "user",
    "parking_lot",
    "user_fcm_device_token",
]


def main() -> None:
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    for table_name in TARGET_TABLES:
        print(f"\n[{table_name}]")

        if table_name not in existing_tables:
            print("- table not found")
            continue

        primary_key = set(
            inspector.get_pk_constraint(table_name).get("constrained_columns", [])
        )

        for column in inspector.get_columns(table_name):
            column_name = column["name"]
            column_type = str(column["type"])
            nullable = "NULL" if column["nullable"] else "NOT NULL"
            pk_mark = " PK" if column_name in primary_key else ""
            default = "" if column.get("default") is None else f" DEFAULT={column['default']}"

            print(f"- {column_name}: {column_type} {nullable}{pk_mark}{default}")


if __name__ == "__main__":
    main()
