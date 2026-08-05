import os
from storage.adapters.postgresql import PostgreSQL
from storage.adapters.mysql import MySQL
from storage.adapters.sqlite import SQLite
from storage.adapters.sqlserver import SQLServer
from storage.adapters.mongodb import MongoDB

def create_adapter():
    driver = os.getenv("DB_DRIVER", "pgsql")
    if driver == "sqlite":
        return SQLite()
    if driver in ("sqlserver", "mssql"):
        return SQLServer()
    if driver == "mongodb":
        return MongoDB()
    if driver == "mysql":
        return MySQL()
    return PostgreSQL()
