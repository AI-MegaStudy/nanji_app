from fastapi import APIRouter, HTTPException
from sqlalchemy import inspect, text

from app.db.session import engine

router = APIRouter(prefix="/db", tags=["db"])


@router.get("/status")
def db_status() -> dict[str, str]:
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
    inspector = inspect(engine)
    return {"tables": inspector.get_table_names()}


@router.get("/tables/{table_name}/columns")
def db_table_columns(table_name: str) -> dict[str, object]:
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
