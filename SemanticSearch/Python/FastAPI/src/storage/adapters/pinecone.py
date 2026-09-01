import os
from storage.vector_adapter import VectorStoreAdapter


class Pinecone(VectorStoreAdapter):
    def __init__(self):
        self._index = None
        self.connect()

    def connect(self):
        if self._index is not None:
            return
        import pinecone
        api_key = os.getenv("PINECONE_API_KEY", "")
        environment = os.getenv("PINECONE_ENVIRONMENT", "us-west1-gcp")
        pinecone.init(api_key=api_key, environment=environment)
        index_name = os.getenv("PINECONE_INDEX", "documents")
        if index_name not in pinecone.list_indexes():
            pinecone.create_index(index_name, dimension=int(os.getenv("VECTOR_DIMENSION", "1536")))
        self._index = pinecone.Index(index_name)

    def add_documents(self, documents, embeddings, metadata):
        vectors = []
        for i, (doc, emb, meta) in enumerate(zip(documents, embeddings, metadata)):
            vectors.append({
                "id": f"doc_{i}",
                "values": emb,
                "metadata": meta | {"text": doc},
            })
        self._index.upsert(vectors=vectors)

    def search(self, query_embedding, n_results=5):
        if self._index is None:
            return []
        results = self._index.query(vector=query_embedding, top_k=n_results, include_metadata=True)
        return [
            {"document": match["metadata"].get("text", ""), "metadata": {k: v for k, v in match["metadata"].items() if k != "text"}, "distance": match["score"]}
            for match in results.get("matches", [])
        ]

    def delete_collection(self, collection_name):
        pass

    def list_collections(self):
        try:
            import pinecone
            return pinecone.list_indexes()
        except Exception:
            return []

    def close(self):
        self._index = None