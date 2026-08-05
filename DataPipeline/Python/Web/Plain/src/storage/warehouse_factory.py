import os
from storage.warehouse_adapter import DataWarehouseAdapter
from storage.adapters.duckdb import DuckDB
from storage.adapters.bigquery import BigQuery
from storage.adapters.postgresql import PostgreSQL


def create_warehouse() -> DataWarehouseAdapter:
    driver = os.getenv("WAREHOUSE_DRIVER", "duckdb")
    if driver == "bigquery":
        return BigQuery()
    if driver == "postgresql":
        return PostgreSQL()
    return DuckDB()