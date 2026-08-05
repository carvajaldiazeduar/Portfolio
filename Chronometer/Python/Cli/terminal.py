from abc import ABC, abstractmethod


class TerminalAdapter(ABC):

    @abstractmethod
    def setup(self):
        pass

    @abstractmethod
    def get_key(self):
        pass

    @abstractmethod
    def restore(self):
        pass
