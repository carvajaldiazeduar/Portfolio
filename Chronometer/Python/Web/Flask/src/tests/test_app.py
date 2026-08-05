import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app import app, format_time


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client
    with app.app_context():
        from app import state
        state["running"] = False
        state["start_time"] = 0.0
        state["elapsed"] = 0.0
        state["laps"] = []


class TestChronometerAPI:
    def test_index(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_get_state(self, client):
        response = client.get("/api/state")
        assert response.status_code == 200
        data = response.get_json()
        assert data["running"] is False
        assert data["time_str"] == "00:00:00.000"

    def test_start(self, client):
        response = client.get("/api/start")
        assert response.status_code == 200
        data = response.get_json()
        assert data["running"] is True

    def test_stop(self, client):
        client.get("/api/start")
        response = client.get("/api/stop")
        assert response.status_code == 200
        data = response.get_json()
        assert data["running"] is False

    def test_reset(self, client):
        client.get("/api/start")
        client.get("/api/stop")
        response = client.get("/api/reset")
        assert response.status_code == 200
        data = response.get_json()
        assert data["running"] is False
        assert data["time_str"] == "00:00:00.000"

    def test_format_time(self):
        assert format_time(0) == "00:00:00.000"
        assert format_time(3661) == "01:01:01.000"
        assert format_time(0.001) == "00:00:00.001"
