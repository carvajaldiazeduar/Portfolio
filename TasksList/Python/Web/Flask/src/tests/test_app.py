import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_FILE"] = "test-tasks.db"
os.environ["CACHE_TYPE"] = "local"

import pytest
from app import app, db


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.app_context():
        db.drop_all()
        db.create_all()
    with app.test_client() as c:
        yield c


def test_get_tasks_empty(client):
    resp = client.get("/api/tasks")
    assert resp.status_code == 200
    assert resp.get_json() == []


def test_add_task(client):
    resp = client.post("/api/tasks", json={"title": "Test", "description": "Desc"})
    assert resp.status_code == 201
    data = resp.get_json()
    assert data["title"] == "Test"
    assert data["description"] == "Desc"
    assert data["completed"] is False
    assert data["id"] == 1


def test_add_task_no_title(client):
    resp = client.post("/api/tasks", json={"title": "", "description": ""})
    assert resp.status_code == 400


def test_list_tasks(client):
    client.post("/api/tasks", json={"title": "A", "description": ""})
    client.post("/api/tasks", json={"title": "B", "description": ""})
    resp = client.get("/api/tasks")
    assert len(resp.get_json()) == 2


def test_complete_task(client):
    client.post("/api/tasks", json={"title": "A", "description": ""})
    resp = client.put("/api/tasks/1/complete")
    assert resp.status_code == 200
    assert resp.get_json()["completed"] is True


def test_complete_task_not_found(client):
    resp = client.put("/api/tasks/999/complete")
    assert resp.status_code == 404


def test_delete_task(client):
    client.post("/api/tasks", json={"title": "A", "description": ""})
    resp = client.delete("/api/tasks/1")
    assert resp.status_code == 200


def test_delete_task_not_found(client):
    resp = client.delete("/api/tasks/999")
    assert resp.status_code == 404


def test_index_returns_html(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"Tasks List" in resp.data
