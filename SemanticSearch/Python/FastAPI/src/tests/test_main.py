from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_index():
    response = client.get("/")
    assert response.status_code == 200


def test_search_without_query():
    response = client.get("/search")
    assert response.status_code == 422


def test_collections():
    response = client.get("/collections")
    assert response.status_code == 200
