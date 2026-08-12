package com.portfolio.contacts;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ContactsManagerTest {

    @Test
    void addContactAddsContact() {
        ContactsManager manager = new ContactsManager();
        Map<String, String> errors = manager.addContact("Alice", "123-4567", "alice@example.com");
        assertTrue(errors.isEmpty());
        assertEquals(1, manager.getContacts().size());
        assertEquals("Alice", manager.getContacts().get(0).getName());
    }

    @Test
    void searchContactsFindsByName() {
        ContactsManager manager = new ContactsManager();
        manager.addContact("Alice", "123-4567", "alice@example.com");
        manager.addContact("Alexander", "789-0123", "alex@example.com");
        List<Contact> results = manager.searchContacts("al");
        assertEquals(2, results.size());
    }

    @Test
    void searchContactsReturnsEmptyForNoMatch() {
        ContactsManager manager = new ContactsManager();
        manager.addContact("Alice", "123-4567", "alice@example.com");
        assertTrue(manager.searchContacts("nobody").isEmpty());
    }

    @Test
    void deleteContactRemovesByIndex() {
        ContactsManager manager = new ContactsManager();
        manager.addContact("Alice", "123-4567", "alice@example.com");
        assertTrue(manager.deleteContact(0));
        assertTrue(manager.getContacts().isEmpty());
    }

    @Test
    void deleteContactWithInvalidIndexDoesNothing() {
        ContactsManager manager = new ContactsManager();
        manager.addContact("Alice", "123-4567", "alice@example.com");
        assertFalse(manager.deleteContact(5));
        assertEquals(1, manager.getContacts().size());
    }

    @Test
    void addContactWithInvalidEmailIsNotAdded() {
        ContactsManager manager = new ContactsManager();
        Map<String, String> errors = manager.addContact("Alice", "123-4567", "not-an-email");
        assertEquals(Map.of("email", "Invalid email format"), errors);
        assertTrue(manager.getContacts().isEmpty());
    }

    @Test
    void addContactWithInvalidPhoneIsNotAdded() {
        ContactsManager manager = new ContactsManager();
        Map<String, String> errors = manager.addContact("Alice", "abc", "alice@example.com");
        assertEquals(Map.of("phone", "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"), errors);
        assertTrue(manager.getContacts().isEmpty());
    }

    @Test
    void addContactWithMissingOrTooShortNameIsNotAdded() {
        ContactsManager manager = new ContactsManager();
        Map<String, String> errors = manager.addContact("", "123-4567", "alice@example.com");
        assertEquals(Map.of("name", "Name is required"), errors);
        assertTrue(manager.getContacts().isEmpty());
    }
}
