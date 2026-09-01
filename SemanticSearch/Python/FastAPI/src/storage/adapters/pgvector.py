import os
import psycopg2
import psycopg2.extras
from storage.vector_adapter import VectorStoreAdapter


class PgVector(VectorStoreAdapter):
    def __init__(self):
        self.conn = None
        self.connect()

    def connect(self):
        if self.conn and not self.conn.closed:
            return
        self.conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "db"),
            port=int(os.getenv("DB_PORT", "5432")),
            dbname=os.getenv("DB_NAME", "semantic_search"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "postgres"),
        )
        self.conn.autocommit = True
        self._ensure_extension()

    def _ensure_extension(self):
        cur = self.conn.cursor()
        cur.execute("CREATE EXTENSION IF NOT EXISTS vector")
        cur.close()

    def _get_collection_table(self, collection_name):
        return f"vector_{collection_name.replace('-', '_')}"

    def add_documents(self, documents, embeddings, metadata):
        collection_name = os.getenv("VECTOR_COLLECTION", "documents")
        table = self._get_collection_table(collection_name)
        cur = self.conn.cursor()
        cur.execute(
            f"CREATE TABLE IF NOT EXISTS {table} (id SERIAL PRIMARY KEY, document TEXT, embedding vector, metadata JSONB)"
        )
        for doc, emb, meta in zip(documents, embeddings, metadata):
            cur.execute(
                f"INSERT INTO {table} (document, embedding, metadata) VALUES (%s, %s, %s)",
                (doc, emb, psycopg2.extras.Json(meta)),
            )
        cur.close()

    def search(self, query_embedding, n_results=5):
        collection_name = os.getenv("VECTOR_COLLECTION", "documents")
        table = self._get_collection_table(collection_name)
        cur = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(
            f"SELECT document, metadata, embedding <=> %s::vector AS distance FROM {table} ORDER BY embedding <=> %s::vector LIMIT %s",
            (query_embedding, query_embedding, n_results),
        )
        rows = cur.fetchall()
        cur.close()
        return [
            {"document": row["document"], "metadata": row["metadata"], "distance": row["distance"]}
            for row in rows
        ]

    def delete_collection(self, collection_name):
        table = self._get_collection_table(collection_name)
        cur = self.conn.cursor()
        cur.execute(f"DROP TABLE IF EXISTS {table}")
        cur.close()

    def list_collections(self):
        cur = self.conn.cursor()
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'vector_%'")
        tables = [row[0] for row in cur.fetchall()]
        cur.close()
        return tables

    def close(self):
        if self.conn and not self.conn.closed:
            self.conn.close()