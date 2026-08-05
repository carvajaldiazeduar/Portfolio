import os
import psycopg2
import psycopg2.extras
from storage.warehouse_adapter import DataWarehouseAdapter


class PostgreSQL(DataWarehouseAdapter):
    def __init__(self):
        self.conn = None
        self.connect()

    def connect(self):
        if self.conn and not self.conn.closed:
            return
        self.conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "5432")),
            dbname=os.getenv("DB_NAME", "etl_pipeline"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "postgres"),
        )
        self.conn.autocommit = True

    def execute(self, query: str, params: tuple = None) -> list:
        self.connect()
        cur = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(query, params or ())
        if cur.description:
            rows = [dict(r) for r in cur.fetchall()]
        else:
            rows = []
        cur.close()
        return rows

    def bulk_insert(self, table: str, records: list) -> None:
        if not records:
            return
        self.connect()
        cur = self.conn.cursor()
        cols = list(records[0].keys())
        placeholders = ", ".join(["%s"] * len(cols))
        col_names = ", ".join(cols)
        values = [tuple(r.get(c) for c in cols) for r in records]
        cur.executemany(f"INSERT INTO {table} ({col_names}) VALUES ({placeholders})", values)
        cur.close()

    def create_table(self, table: str, schema: dict) -> None:
        self.connect()
        col_defs = ", ".join(f"{name} {dtype}" for name, dtype in schema.items())
        cur = self.conn.cursor()
        cur.execute(f"CREATE TABLE IF NOT EXISTS {table} ({col_defs})")
        cur.close()

    def list_tables(self) -> list:
        self.connect()
        cur = self.conn.cursor()
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
        tables = [r[0] for r in cur.fetchall()]
        cur.close()
        return tables

    def close(self):
        if self.conn and not self.conn.closed:
            self.conn.close()