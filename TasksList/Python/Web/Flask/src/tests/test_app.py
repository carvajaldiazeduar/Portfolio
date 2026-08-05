import pytest
from app import app, tasks


@pytest.fixture(autouse=True)
def reset_tasks():
    tasks.clear()
    app.config["_next_id"] = 1
    yield


def _set_next_id(val):
    import app as a
    a._next_id = val


@pytest.fixture
def client():
    app.config["TESTING"] = True
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
    assert len(tasks) == 0


def test_delete_task_not_found(client):
    resp = client.delete("/api/tasks/999")
    assert resp.status_code == 404


def test_index_returns_html(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"Tasks List" in resp.data
