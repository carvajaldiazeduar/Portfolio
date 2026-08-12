package com.portfolio.contacts;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;
import java.util.Map;

public class ContactsCli {
    private final ContactsManager manager = new ContactsManager();
    private final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

    public static void main(String[] args) {
        new ContactsCli().run();
    }

    public void run() {
        while (true) {
            System.out.println("\n--- Contact Manager ---");
            System.out.println("1. Add Contact");
            System.out.println("2. List Contacts");
            System.out.println("3. Search Contacts");
            System.out.println("4. Delete Contact");
            System.out.println("5. Exit");
            System.out.print("Choose an option: ");
            String choice = readLine();
            switch (choice) {
                case "1" -> addContactFlow();
                case "2" -> listContacts();
                case "3" -> searchContactsFlow();
                case "4" -> deleteContactFlow();
                case "5" -> {
                    System.out.println("Goodbye!");
                    return;
                }
                default -> {
                }
            }
        }
    }

    private void addContactFlow() {
        System.out.print("Name: ");
        String name = readLine();
        System.out.print("Phone: ");
        String phone = readLine();
        System.out.print("Email: ");
        String email = readLine();
        Map<String, String> errors = manager.addContact(name, phone, email);
        if (!errors.isEmpty()) {
            for (Map.Entry<String, String> e : errors.entrySet()) {
                System.err.println(e.getKey() + ": " + e.getValue());
            }
        } else {
            System.out.println("Contact added!");
        }
    }

    private void listContacts() {
        List<Contact> all = manager.getContacts();
        if (all.isEmpty()) {
            System.out.println("No contacts found.");
            return;
        }
        for (int i = 0; i < all.size(); i++) {
            Contact c = all.get(i);
            System.out.println(i + ". " + c.getName() + " | " + c.getPhone() + " | " + c.getEmail());
        }
    }

    private void searchContactsFlow() {
        System.out.print("Search query: ");
        String query = readLine();
        List<Contact> results = manager.searchContacts(query);
        if (results.isEmpty()) {
            System.out.println("No contacts found.");
            return;
        }
        for (int i = 0; i < results.size(); i++) {
            Contact c = results.get(i);
            System.out.println(i + ". " + c.getName() + " | " + c.getPhone() + " | " + c.getEmail());
        }
    }

    private void deleteContactFlow() {
        List<Contact> list = manager.getContacts();
        if (list.isEmpty()) {
            System.out.println("No contacts to delete.");
            return;
        }
        for (int i = 0; i < list.size(); i++) {
            Contact c = list.get(i);
            System.out.println(i + ". " + c.getName() + " | " + c.getPhone() + " | " + c.getEmail());
        }
        System.out.print("Enter index to delete: ");
        String input = readLine();
        try {
            int idx = Integer.parseInt(input.trim());
            if (manager.deleteContact(idx)) {
                System.out.println("Deleted " + list.get(idx).getName());
            } else {
                System.out.println("Invalid index.");
            }
        } catch (NumberFormatException e) {
            System.out.println("Invalid input.");
        }
    }

    private String readLine() {
        try {
            return reader.readLine();
        } catch (IOException e) {
            return "";
        }
    }
}
