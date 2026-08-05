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


def test_pipelines(client):
    response = client.get("/api/pipelines")
    assert response.status_code == 200


def test_sources(client):
    response = client.get("/api/sources")
    assert response.status_code == 200


def test_health(client):
    response = client.get("/api/health")
    assert response.status_code == 200