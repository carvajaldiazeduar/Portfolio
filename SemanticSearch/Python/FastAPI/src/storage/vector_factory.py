import os
from storage.vector_adapter import VectorStoreAdapter
from storage.adapters.chromadb import ChromaDB
from storage.adapters.pinecone import Pinecone
from storage.adapters.pgvector import PgVector


def create_vector_store() -> VectorStoreAdapter:
    driver = os.getenv("VECTOR_DRIVER", "chromadb")
    if driver == "pinecone":
        return Pinecone()
    if driver == "pgvector":
        return PgVector()
    return ChromaDB()