import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from inboxes import send_message, list_messages, read_message, delete_message, messages, next_id


def setup_function():
    messages.clear()
    import inboxes
    inboxes.next_id = 1


def test_send_message():
    msg = send_message("alice", "Hello", "World")
    assert msg["id"] == 1
    assert msg["from"] == "alice"
    assert msg["subject"] == "Hello"
    assert msg["body"] == "World"
    assert msg["read"] is False
    assert msg["created_at"] is not None


def test_list_messages():
    send_message("alice", "Subject1", "Body1")
    send_message("bob", "Subject2", "Body2")
    msgs = list_messages()
    assert len(msgs) == 2


def test_read_message_marks_as_read():
    send_message("alice", "Test", "Body")
    msg = read_message(1)
    assert msg is not None
    assert msg["read"] is True
    msg2 = read_message(1)
    assert msg2["read"] is True


def test_delete_message():
    send_message("alice", "Del", "Me")
    assert len(list_messages()) == 1
    assert delete_message(1) is True
    assert len(list_messages()) == 0


def test_list_after_delete():
    send_message("alice", "Keep", "Me")
    send_message("bob", "Delete", "This")
    delete_message(2)
    msgs = list_messages()
    assert len(msgs) == 1
    assert msgs[0]["id"] == 1


def test_read_nonexistent():
    assert read_message(999) is None


def test_delete_nonexistent():
    assert delete_message(999) is False
