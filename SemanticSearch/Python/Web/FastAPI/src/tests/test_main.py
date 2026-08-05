import pytest
from main import app


@pytest.fixture
def client():
    return app.test_client()


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200


def test_search_without_query(client):
    response = client.get("/search")
    assert response.status_code == 422


def test_collections(client):
    response = client.get("/collections")
    assert response.status_code == 200