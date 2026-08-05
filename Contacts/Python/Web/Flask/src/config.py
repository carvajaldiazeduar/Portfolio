import os

DB_DRIVER = os.getenv("DB_DRIVER", "postgresql")
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "contacts")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_FILE = os.getenv("DB_FILE", "")

if DB_DRIVER == "sqlite":
    DATABASE_URL = f"sqlite:///{DB_FILE}" if DB_FILE else "sqlite:///db.sqlite3"
elif DB_DRIVER == "mysql":
    DATABASE_URL = f"mysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
elif DB_DRIVER == "mongodb":
    DATABASE_URL = f"mongodb://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
elif DB_DRIVER == "mssql":
    DATABASE_URL = f"mssql+pymssql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
else:
    DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

CACHE_TYPE = os.getenv("CACHE_TYPE", "redis")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
