from abc import ABC, abstractmethod

class DatabaseAdapter(ABC):
    @abstractmethod
    def connect(self): pass
    @abstractmethod
    def init_table(self, table, columns=None): pass
    @abstractmethod
    def get_all(self, table): pass
    @abstractmethod
    def get_by_id(self, table, id): pass
    @abstractmethod
    def create(self, table, data): pass
    @abstractmethod
    def update(self, table, id, data): pass
    @abstractmethod
    def delete(self, table, id): pass
    @abstractmethod
    def search(self, table, field, query): pass
    @abstractmethod
    def close(self): pass
