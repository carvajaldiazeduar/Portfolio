import os
import psycopg2
import psycopg2.extras
from storage.database_adapter import DatabaseAdapter

TYPE_MAP = {
    "TEXT": "TEXT",
    "INTEGER": "INTEGER",
    "TIMESTAMP": "TIMESTAMP",
}

class PostgreSQL(DatabaseAdapter):
    def __init__(self):
        self.conn = None
        self.connect()

    def connect(self):
        if self.conn and not self.conn.closed:
            return
        self.conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "5432")),
            dbname=os.getenv("DB_NAME", "passwords"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "postgres"),
        )
        self.conn.autocommit = True

    def _translate(self, col_def):
        for generic, specific in TYPE_MAP.items():
            col_def = col_def.replace(generic, specific)
        return col_def

    def init_table(self, table, columns=None):
        self.connect()
        cur = self.conn.cursor()
        cols = ["id SERIAL PRIMARY KEY"]
        if columns:
            for name, col_def in columns.items():
                cols.append(f"{name} {self._translate(col_def)}")
        cur.execute(f"CREATE TABLE IF NOT EXISTS {table} ({', '.join(cols)})")
        cur.close()

    def _query(self, sql, params=None, fetchone=False, fetchall=False):
        self.connect()
        cur = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(sql, params or ())
        if fetchone:
            row = cur.fetchone()
            cur.close()
            return dict(row) if row else None
        if fetchall:
            rows = [dict(r) for r in cur.fetchall()]
            cur.close()
            return rows
        cur.close()

    def _execute(self, sql, params=None):
        self.connect()
        cur = self.conn.cursor()
        cur.execute(sql, params or ())
        rowcount = cur.rowcount
        cur.close()
        return rowcount

    def get_all(self, table):
        return self._query(f"SELECT * FROM {table} ORDER BY id DESC LIMIT 50", fetchall=True)

    def get_by_id(self, table, id):
        return self._query(f"SELECT * FROM {table} WHERE id = %s", (id,), fetchone=True)

    def create(self, table, data):
        cols = ", ".join(data.keys())
        placeholders = ", ".join("%s" for _ in data)
        values = list(data.values())
        self._execute(
            f"INSERT INTO {table} ({cols}) VALUES ({placeholders})", values
        )
        return None

    def update(self, table, id, data):
        set_clause = ", ".join(f"{k} = %s" for k in data)
        values = list(data.values()) + [id]
        return self._execute(f"UPDATE {table} SET {set_clause} WHERE id = %s", values) > 0

    def delete(self, table, id):
        return self._execute(f"DELETE FROM {table} WHERE id = %s", (id,)) > 0

    def search(self, table, field, query):
        return self._query(
            f"SELECT * FROM {table} WHERE LOWER({field}) LIKE %s ORDER BY id ASC",
            (f"%{query.lower()}%",), fetchall=True
        )

    def close(self):
        if self.conn and not self.conn.closed:
            self.conn.close()
