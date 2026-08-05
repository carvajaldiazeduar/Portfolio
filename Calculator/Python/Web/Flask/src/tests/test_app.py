import pytest
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


class TestCalculatorAPI:
    def test_index(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_add(self, client):
        response = client.post("/calculate", json={"a": 2, "b": 3, "operator": "add"})
        assert response.status_code == 200
        assert response.get_json()["result"] == 5

    def test_subtract(self, client):
        response = client.post(
            "/calculate", json={"a": 5, "b": 3, "operator": "subtract"}
        )
        assert response.status_code == 200
        assert response.get_json()["result"] == 2

    def test_multiply(self, client):
        response = client.post(
            "/calculate", json={"a": 2, "b": 3, "operator": "multiply"}
        )
        assert response.status_code == 200
        assert response.get_json()["result"] == 6

    def test_divide(self, client):
        response = client.post(
            "/calculate", json={"a": 6, "b": 3, "operator": "divide"}
        )
        assert response.status_code == 200
        assert response.get_json()["result"] == 2

    def test_divide_by_zero(self, client):
        response = client.post(
            "/calculate", json={"a": 5, "b": 0, "operator": "divide"}
        )
        assert response.status_code == 400

    def test_invalid_operator(self, client):
        response = client.post(
            "/calculate", json={"a": 2, "b": 3, "operator": "power"}
        )
        assert response.status_code == 400

    def test_invalid_input(self, client):
        response = client.post(
            "/calculate", json={"a": "foo", "b": 3, "operator": "add"}
        )
        assert response.status_code == 400
