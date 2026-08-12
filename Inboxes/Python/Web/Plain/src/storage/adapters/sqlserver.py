import os
import pymssql
from storage.database_adapter import DatabaseAdapter

TYPE_MAP = {
    "TEXT": "NVARCHAR(MAX)",
    "INTEGER": "INT",
    "TIMESTAMP": "DATETIME",
}

class SQLServer(DatabaseAdapter):
    def __init__(self):
        self.conn = None
        self.connect()

    def connect(self):
        if getattr(self, 'conn', None) and self.conn.connected:
            return
        self.conn = pymssql.connect(
            host=os.getenv("DB_HOST", "db"),
            user=os.getenv("DB_USER", "sa"),
            password=os.getenv("DB_PASSWORD", "your_password"),
            database=os.getenv("DB_NAME", "inboxes"),
            port=int(os.getenv("DB_PORT", "1433")),
            tds_version='7.4',
        )

    def _translate(self, col_def):
        for generic, specific in TYPE_MAP.items():
            col_def = col_def.replace(generic, specific)
        col_def = col_def.replace("DEFAULT NOW()", "DEFAULT GETDATE()")
        return col_def

    def init_table(self, table, columns=None):
        self.connect()
        cur = self.conn.cursor()
        cols = ["id INT IDENTITY(1,1) PRIMARY KEY"]
        if columns:
            for name, col_def in columns.items():
                cols.append(f"{name} {self._translate(col_def)}")
        cur.execute(f"IF OBJECT_ID('{table}', 'U') IS NULL CREATE TABLE {table} ({', '.join(cols)})")
        self.conn.commit()
        cur.close()

    def _query(self, sql, params=None, fetchone=False, fetchall=False):
        self.connect()
        cur = self.conn.cursor(as_dict=True)
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
        self.conn.commit()
        rowcount = cur.rowcount
        cur.close()
        return rowcount

    def get_all(self, table):
        return self._query(f"SELECT * FROM {table} ORDER BY id ASC", fetchall=True)

    def get_by_id(self, table, id):
        return self._query(f"SELECT * FROM {table} WHERE id = %s", (id,), fetchone=True)

    def create(self, table, data):
        cols = ", ".join(data.keys())
        placeholders = ", ".join("%s" for _ in data)
        values = list(data.values())
        return self._query(
            f"INSERT INTO {table} ({cols}) OUTPUT INSERTED.* VALUES ({placeholders})",
            values, fetchone=True
        )

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
        if getattr(self, 'conn', None) and self.conn.connected:
            self.conn.close()
