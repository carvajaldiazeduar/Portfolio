import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from semantic_search import main


def test_main_exists():
    assert callable(main)


def test_imports_vector_store():
    from storage.vector_factory import create_vector_store

    assert callable(create_vector_store)
