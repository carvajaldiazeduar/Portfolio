import os
import sqlite3
from storage.database_adapter import DatabaseAdapter

TYPE_MAP = {
    "TEXT": "TEXT",
    "INTEGER": "INTEGER",
    "TIMESTAMP": "TEXT",
}

class SQLite(DatabaseAdapter):
    def __init__(self):
        self.conn = None
        self.connect()

    def connect(self):
        if self.conn:
            return
        self.conn = sqlite3.connect(os.getenv("DB_FILE", "data.db"))
        self.conn.row_factory = sqlite3.Row

    def _translate(self, col_def):
        for generic, specific in TYPE_MAP.items():
            col_def = col_def.replace(generic, specific)
        col_def = col_def.replace("DEFAULT NOW()", "DEFAULT (datetime('now'))")
        return col_def

    def init_table(self, table, columns=None):
        self.connect()
        cur = self.conn.cursor()
        cols = ["id INTEGER PRIMARY KEY AUTOINCREMENT"]
        if columns:
            for name, col_def in columns.items():
                cols.append(f"{name} {self._translate(col_def)}")
        cur.execute(f"CREATE TABLE IF NOT EXISTS {table} ({', '.join(cols)})")
        self.conn.commit()
        cur.close()

    def _query(self, sql, params=None, fetchone=False, fetchall=False):
        self.connect()
        cur = self.conn.cursor()
        cur.execute(sql, params or [])
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
        cur.execute(sql, params or [])
        self.conn.commit()
        rowcount = cur.rowcount
        cur.close()
        return rowcount

    def get_all(self, table):
        return self._query(f"SELECT * FROM {table} ORDER BY id ASC", fetchall=True)

    def get_by_id(self, table, id):
        return self._query(f"SELECT * FROM {table} WHERE id = ?", (id,), fetchone=True)

    def create(self, table, data):
        cols = ", ".join(data.keys())
        placeholders = ", ".join("?" for _ in data)
        values = list(data.values())
        self.connect()
        cur = self.conn.cursor()
        cur.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders})", values)
        self.conn.commit()
        cur.execute(f"SELECT * FROM {table} WHERE id = last_insert_rowid()")
        row = dict(cur.fetchone())
        cur.close()
        return row

    def update(self, table, id, data):
        set_clause = ", ".join(f"{k} = ?" for k in data)
        values = list(data.values()) + [id]
        return self._execute(f"UPDATE {table} SET {set_clause} WHERE id = ?", values) > 0

    def delete(self, table, id):
        return self._execute(f"DELETE FROM {table} WHERE id = ?", (id,)) > 0

    def search(self, table, field, query):
        return self._query(
            f"SELECT * FROM {table} WHERE LOWER({field}) LIKE ? ORDER BY id ASC",
            (f"%{query.lower()}%",), fetchall=True
        )

    def close(self):
        if self.conn:
            self.conn.close()
