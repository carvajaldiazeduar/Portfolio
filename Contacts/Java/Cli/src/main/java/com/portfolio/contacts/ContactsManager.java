package com.portfolio.contacts;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class ContactsManager {
    private final List<Contact> contacts = new ArrayList<>();

    public List<Contact> getContacts() {
        return new ArrayList<>(contacts);
    }

    public Map<String, String> addContact(String name, String phone, String email) {
        Map<String, String> errors = ContactValidator.validate(name, phone, email);
        if (!errors.isEmpty()) {
            return errors;
        }
        contacts.add(new Contact(name.trim(), phone.trim(), email.trim()));
        return errors;
    }

    public List<Contact> searchContacts(String query) {
        List<Contact> results = new ArrayList<>();
        for (Contact c : contacts) {
            if (c.getName().toLowerCase(Locale.ROOT).contains(query.toLowerCase(Locale.ROOT))) {
                results.add(c);
            }
        }
        return results;
    }

    public boolean deleteContact(int index) {
        if (index < 0 || index >= contacts.size()) {
            return false;
        }
        contacts.remove(index);
        return true;
    }
}
