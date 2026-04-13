import os

from fastapi import APIRouter, HTTPException
from sqlalchemy import inspect, text

from app.db.session import engine

router = APIRouter(prefix="/db", tags=["db"])


def ensure_debug_db_api_enabled() -> None:
    enabled = os.getenv("ENABLE_DEBUG_DB_API", "").strip().lower()
    if enabled not in {"1", "true", "yes", "on"}:
        raise HTTPException(status_code=404, detail="Not found")


@router.get("/status")
def db_status() -> dict[str, str]:
    ensure_debug_db_api_enabled()
    with engine.connect() as connection:
        version = connection.execute(text("SELECT VERSION()")).scalar()
        current_db = connection.execute(text("SELECT DATABASE()")).scalar()

    return {
        "status": "ok",
        "database": str(current_db),
        "version": str(version),
    }


@router.get("/tables")
def db_tables() -> dict[str, list[str]]:
    ensure_debug_db_api_enabled()
    inspector = inspect(engine)
    return {"tables": inspector.get_table_names()}


@router.get("/tables/{table_name}/columns")
def db_table_columns(table_name: str) -> dict[str, object]:
    ensure_debug_db_api_enabled()
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    if table_name not in tables:
        raise HTTPException(status_code=404, detail=f"table not found: {table_name}")

    columns = inspector.get_columns(table_name)
    primary_key = set(inspector.get_pk_constraint(table_name).get("constrained_columns", []))

    items = []
    for column in columns:
        items.append(
            {
                "name": column["name"],
                "type": str(column["type"]),
                "nullable": bool(column["nullable"]),
                "primary_key": column["name"] in primary_key,
                "default": None if column.get("default") is None else str(column.get("default")),
            }
        )

    return {
        "table": table_name,
        "columns": items,
    }
