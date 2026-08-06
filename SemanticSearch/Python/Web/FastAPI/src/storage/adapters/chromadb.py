import os
from storage.vector_adapter import VectorStoreAdapter


class ChromaDB(VectorStoreAdapter):
    def __init__(self):
        self._client = None
        self._collections = {}
        self.connect()

    def connect(self):
        if self._client is not None:
            return
        try:
            import chromadb
            host = os.getenv("CHROMA_HOST", "localhost")
            port = int(os.getenv("CHROMA_PORT", "8000"))
            self._client = chromadb.HttpClient(host=host, port=port)
        except Exception:
            self._client = chromadb.Client()

    def add_documents(self, documents, embeddings, metadata):
        collection_name = os.getenv("VECTOR_COLLECTION", "documents")
        if collection_name not in self._collections:
            self._collections[collection_name] = self._client.get_or_create_collection(collection_name)
        collection = self._collections[collection_name]
        ids = [f"doc_{i}" for i in range(len(documents))]
        collection.add(documents=documents, embeddings=embeddings, metadatas=metadata, ids=ids)

    def search(self, query_embedding, n_results=5):
        collection_name = os.getenv("VECTOR_COLLECTION", "documents")
        if collection_name not in self._collections:
            return []
        collection = self._collections[collection_name]
        results = collection.query(query_embeddings=[query_embedding], n_results=n_results)
        return [
            {"document": doc, "metadata": meta, "distance": dist}
            for doc, meta, dist in zip(
                results.get("documents", [[]])[0],
                results.get("metadatas", [[]])[0],
                results.get("distances", [[]])[0],
            )
        ]

    def delete_collection(self, collection_name):
        if collection_name in self._collections:
            del self._collections[collection_name]
        try:
            self._client.delete_collection(collection_name)
        except Exception:
            pass

    def list_collections(self):
        return [c.name for c in self._client.list_collections()]

    def close(self):
        self._collections.clear()
        self._client = None