from pathlib import Path
import sys

from sqlalchemy import text

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.db.session import engine


def main() -> None:
    with engine.connect() as connection:
        version = connection.execute(text("SELECT VERSION()")).scalar()
        current_db = connection.execute(text("SELECT DATABASE()")).scalar()

    print("DB connection ok")
    print(f"MySQL version: {version}")
    print(f"Current database: {current_db}")


if __name__ == "__main__":
    main()
