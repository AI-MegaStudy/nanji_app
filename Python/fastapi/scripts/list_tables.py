from pathlib import Path
import sys

from sqlalchemy import inspect

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.db.session import engine


def main() -> None:
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    print("Tables in current database:")
    for table_name in tables:
        print(f"- {table_name}")


if __name__ == "__main__":
    main()
