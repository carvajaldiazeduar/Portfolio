import os
from storage.warehouse_adapter import DataWarehouseAdapter


class DuckDB(DataWarehouseAdapter):
    def __init__(self):
        self._conn = None
        self.connect()

    def connect(self):
        if self._conn is not None:
            return
        try:
            import duckdb
            db_path = os.getenv("WAREHOUSE_PATH", "data.duckdb")
            self._conn = duckdb.connect(db_path)
        except ImportError:
            raise RuntimeError("duckdb package is required")

    def execute(self, query: str, params: tuple = None) -> list:
        self.connect()
        cur = self._conn.cursor()
        cur.execute(query, params or ())
        if cur.description:
            cols = [desc[0] for desc in cur.description]
            rows = cur.fetchall()
            result = [dict(zip(cols, row)) for row in rows]
        else:
            result = []
        cur.close()
        return result

    def bulk_insert(self, table: str, records: list) -> None:
        if not records:
            return
        self.connect()
        cur = self._conn.cursor()
        cols = list(records[0].keys())
        placeholders = ", ".join(["?"] * len(cols))
        col_names = ", ".join(cols)
        values = [tuple(r.get(c) for c in cols) for r in records]
        cur.executemany(f"INSERT INTO {table} ({col_names}) VALUES ({placeholders})", values)
        self._conn.commit()
        cur.close()

    def create_table(self, table: str, schema: dict) -> None:
        self.connect()
        col_defs = ", ".join(f"{name} {dtype}" for name, dtype in schema.items())
        self._conn.execute(f"CREATE TABLE IF NOT EXISTS {table} ({col_defs})")

    def list_tables(self) -> list:
        self.connect()
        result = self._conn.execute("SHOW TABLES").fetchall()
        return [r[0] for r in result]

    def close(self):
        if self._conn is not None:
            self._conn.close()
            self._conn = None