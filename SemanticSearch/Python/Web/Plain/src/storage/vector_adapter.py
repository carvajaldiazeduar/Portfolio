from abc import ABC, abstractmethod
from typing import List, Dict, Optional, Tuple


class VectorStoreAdapter(ABC):
    @abstractmethod
    def connect(self): pass

    @abstractmethod
    def add_documents(self, documents: List[Dict], embeddings: List[List[float]], metadata: List[Dict]) -> None: pass

    @abstractmethod
    def search(self, query_embedding: List[float], n_results: int = 5) -> List[Dict]: pass

    @abstractmethod
    def delete_collection(self, collection_name: str) -> None: pass

    @abstractmethod
    def list_collections(self) -> List[str]: pass

    @abstractmethod
    def close(self): pass