import pytest
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200


def test_search_without_query(client):
    response = client.get("/api/search")
    assert response.status_code == 400


def test_collections(client):
    response = client.get("/api/collections")
    assert response.status_code == 200