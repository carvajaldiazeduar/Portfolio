import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from contacts import add_contact, list_contacts, search_contacts, delete_contact

def test_add_contact():
    contacts = []
    add_contact(contacts, "Alice", "123-456", "alice@test.com")
    assert len(contacts) == 1
    assert contacts[0]["name"] == "Alice"
    assert contacts[0]["phone"] == "123-456"
    assert contacts[0]["email"] == "alice@test.com"

def test_list_contacts_empty(capsys):
    contacts = []
    list_contacts(contacts)
    captured = capsys.readouterr()
    assert "No contacts" in captured.out

def test_list_contacts_with_data(capsys):
    contacts = [{"name": "Alice", "phone": "123", "email": "a@b.com"}]
    list_contacts(contacts)
    captured = capsys.readouterr()
    assert "Alice" in captured.out

def test_search_contacts_found():
    contacts = [
        {"name": "Alice", "phone": "123", "email": "a@b.com"},
        {"name": "Bob", "phone": "456", "email": "b@c.com"},
        {"name": "Alexander", "phone": "789", "email": "alex@d.com"}
    ]
    results = search_contacts(contacts, "al")
    assert len(results) == 2

def test_search_contacts_not_found(capsys):
    contacts = [{"name": "Alice", "phone": "123", "email": "a@b.com"}]
    results = search_contacts(contacts, "zzz")
    assert len(results) == 0
    captured = capsys.readouterr()
    assert "No contacts" in captured.out

def test_delete_contact_valid():
    contacts = [{"name": "Alice", "phone": "123", "email": "a@b.com"}, {"name": "Bob", "phone": "456", "email": "b@c.com"}]
    delete_contact(contacts, 0)
    assert len(contacts) == 1
    assert contacts[0]["name"] == "Bob"

def test_delete_contact_invalid(capsys):
    contacts = [{"name": "Alice", "phone": "123", "email": "a@b.com"}]
    delete_contact(contacts, 5)
    assert len(contacts) == 1
    captured = capsys.readouterr()
    assert "Invalid" in captured.out

def test_add_contact_invalid_email_not_added():
    contacts = []
    result = add_contact(contacts, "Alice", "123-4567", "not-an-email")
    assert result is False
    assert len(contacts) == 0

def test_add_contact_invalid_email_stderr(capsys):
    contacts = []
    add_contact(contacts, "Alice", "123-4567", "not-an-email")
    captured = capsys.readouterr()
    assert "Invalid email format" in captured.err

def test_add_contact_invalid_phone_not_added():
    contacts = []
    result = add_contact(contacts, "Alice", "abc", "alice@test.com")
    assert result is False
    assert len(contacts) == 0

def test_add_contact_invalid_phone_stderr(capsys):
    contacts = []
    add_contact(contacts, "Alice", "123", "alice@test.com")
    captured = capsys.readouterr()
    assert "Phone must be 7-20" in captured.err

def test_add_contact_missing_name_not_added():
    contacts = []
    result = add_contact(contacts, "   ", "123-4567", "alice@test.com")
    assert result is False
    assert len(contacts) == 0

def test_add_contact_short_name_not_added():
    contacts = []
    result = add_contact(contacts, "A", "123-4567", "alice@test.com")
    assert result is False
    assert len(contacts) == 0

def test_add_contact_missing_name_stderr(capsys):
    contacts = []
    add_contact(contacts, "", "123-4567", "alice@test.com")
    captured = capsys.readouterr()
    assert "Name is required" in captured.err
