import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_FILE"] = "test-inboxes.db"
os.environ["CACHE_TYPE"] = "local"

import pytest
from app import app, db


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.app_context():
        db.drop_all()
        db.create_all()
    with app.test_client() as client:
        yield client


class TestApp:
    def test_list_empty(self, client):
        res = client.get("/api/messages")
        assert res.status_code == 200
        assert res.get_json() == []

    def test_send_message(self, client):
        res = client.post(
            "/api/messages",
            json={"from": "alice", "subject": "Hello", "body": "World"},
        )
        assert res.status_code == 201
        data = res.get_json()
        assert data["id"] == 1
        assert data["from"] == "alice"
        assert data["subject"] == "Hello"
        assert data["body"] == "World"
        assert data["read"] is False

    def test_list_messages(self, client):
        client.post("/api/messages", json={"from": "a", "subject": "s", "body": "b"})
        client.post("/api/messages", json={"from": "b", "subject": "s2", "body": "b2"})
        res = client.get("/api/messages")
        assert len(res.get_json()) == 2

    def test_read_message_marks_as_read(self, client):
        client.post("/api/messages", json={"from": "a", "subject": "s", "body": "b"})
        res = client.get("/api/messages/1")
        assert res.status_code == 200
        assert res.get_json()["read"] is True

    def test_read_nonexistent(self, client):
        res = client.get("/api/messages/999")
        assert res.status_code == 404

    def test_delete_message(self, client):
        client.post("/api/messages", json={"from": "a", "subject": "s", "body": "b"})
        res = client.delete("/api/messages/1")
        assert res.status_code == 204
        res2 = client.get("/api/messages")
        assert len(res2.get_json()) == 0

    def test_delete_nonexistent(self, client):
        res = client.delete("/api/messages/999")
        assert res.status_code == 404

    def test_list_after_delete(self, client):
        client.post("/api/messages", json={"from": "a", "subject": "s1", "body": "b1"})
        client.post("/api/messages", json={"from": "b", "subject": "s2", "body": "b2"})
        client.delete("/api/messages/2")
        res = client.get("/api/messages")
        assert len(res.get_json()) == 1
        assert res.get_json()[0]["id"] == 1
