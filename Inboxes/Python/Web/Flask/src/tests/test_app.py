import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import json
from app import app, messages, next_id


def setup_method():
    messages.clear()
    app.next_id = 1


class TestApp:
    def setup_method(self):
        messages.clear()
        import app as a
        a.next_id = 1
        self.client = app.test_client()

    def test_list_empty(self):
        res = self.client.get("/api/messages")
        assert res.status_code == 200
        assert res.get_json() == []

    def test_send_message(self):
        res = self.client.post(
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

    def test_list_messages(self):
        self.client.post("/api/messages", json={"from": "a", "subject": "s", "body": "b"})
        self.client.post("/api/messages", json={"from": "b", "subject": "s2", "body": "b2"})
        res = self.client.get("/api/messages")
        assert len(res.get_json()) == 2

    def test_read_message_marks_as_read(self):
        self.client.post("/api/messages", json={"from": "a", "subject": "s", "body": "b"})
        res = self.client.get("/api/messages/1")
        assert res.status_code == 200
        assert res.get_json()["read"] is True

    def test_read_nonexistent(self):
        res = self.client.get("/api/messages/999")
        assert res.status_code == 404

    def test_delete_message(self):
        self.client.post("/api/messages", json={"from": "a", "subject": "s", "body": "b"})
        res = self.client.delete("/api/messages/1")
        assert res.status_code == 204
        res2 = self.client.get("/api/messages")
        assert len(res2.get_json()) == 0

    def test_delete_nonexistent(self):
        res = self.client.delete("/api/messages/999")
        assert res.status_code == 404

    def test_list_after_delete(self):
        self.client.post("/api/messages", json={"from": "a", "subject": "s1", "body": "b1"})
        self.client.post("/api/messages", json={"from": "b", "subject": "s2", "body": "b2"})
        self.client.delete("/api/messages/2")
        res = self.client.get("/api/messages")
        assert len(res.get_json()) == 1
        assert res.get_json()[0]["id"] == 1
