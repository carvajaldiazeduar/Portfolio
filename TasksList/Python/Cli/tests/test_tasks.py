from tasks import add_task, list_tasks, complete_task, delete_task, _next_id
import io
import sys


def _make_tasks(*items):
    return [dict(t) for t in items]


def test_add_task():
    tasks = []
    tid = add_task(tasks, "Test", "A task")
    assert tid == 1
    assert len(tasks) == 1
    assert tasks[0]["title"] == "Test"
    assert tasks[0]["description"] == "A task"
    assert tasks[0]["completed"] is False
    assert "created_at" in tasks[0]


def test_add_task_auto_increment():
    tasks = [{"id": 1, "title": "a", "description": "", "completed": False, "created_at": ""}]
    tid = add_task(tasks, "b", "")
    assert tid == 2


def test_list_tasks_no_tasks(capsys):
    list_tasks([])
    captured = capsys.readouterr()
    assert "No tasks found." in captured.out


def test_list_tasks(capsys):
    tasks = [{"id": 1, "title": "Buy milk", "description": "", "completed": False, "created_at": "now"}]
    list_tasks(tasks)
    captured = capsys.readouterr()
    assert "[ ]" in captured.out
    assert "Buy milk" in captured.out


def test_list_tasks_completed(capsys):
    tasks = [{"id": 1, "title": "Done", "description": "", "completed": True, "created_at": "now"}]
    list_tasks(tasks)
    captured = capsys.readouterr()
    assert "[x]" in captured.out


def test_complete_task():
    tasks = [{"id": 1, "title": "a", "description": "", "completed": False, "created_at": ""}]
    result = complete_task(tasks, 1)
    assert result is True
    assert tasks[0]["completed"] is True


def test_complete_task_not_found():
    result = complete_task([], 99)
    assert result is False


def test_delete_task():
    tasks = [{"id": 1, "title": "a", "description": "", "completed": False, "created_at": ""}]
    result = delete_task(tasks, 1)
    assert result is True
    assert len(tasks) == 0


def test_delete_task_not_found():
    tasks = [{"id": 1, "title": "a", "description": "", "completed": False, "created_at": ""}]
    result = delete_task(tasks, 99)
    assert result is False
    assert len(tasks) == 1
