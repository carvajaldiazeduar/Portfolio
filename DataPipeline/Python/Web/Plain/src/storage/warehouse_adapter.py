from abc import ABC, abstractmethod
from typing import List, Dict, Optional


class DataWarehouseAdapter(ABC):
    @abstractmethod
    def connect(self): pass

    @abstractmethod
    def execute(self, query: str, params: Optional[tuple] = None) -> List[Dict]: pass

    @abstractmethod
    def bulk_insert(self, table: str, records: List[Dict]) -> None: pass

    @abstractmethod
    def create_table(self, table: str, schema: Dict[str, str]) -> None: pass

    @abstractmethod
    def list_tables(self) -> List[str]: pass

    @abstractmethod
    def close(self): pass