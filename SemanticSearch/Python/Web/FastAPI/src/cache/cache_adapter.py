from abc import ABC, abstractmethod


class CacheAdapter(ABC):
    @abstractmethod
    def get(self, key): pass

    @abstractmethod
    def set(self, key, value, ttl=300): pass

    @abstractmethod
    def delete(self, key): pass