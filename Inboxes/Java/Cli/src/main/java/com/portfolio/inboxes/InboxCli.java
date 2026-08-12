package com.portfolio.inboxes;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;
import java.util.Map;

public class InboxCli {
    private final InboxManager manager = new InboxManager();
    private final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

    public static void main(String[] args) {
        new InboxCli().run();
    }

    public void run() {
        while (true) {
            System.out.println("\n=== Inbox CLI ===");
            System.out.println("1. Send message");
            System.out.println("2. List messages");
            System.out.println("3. Read message");
            System.out.println("4. Delete message");
            System.out.println("5. Exit");
            System.out.print("Choice: ");
            String choice = readLine();
            switch (choice) {
                case "1" -> sendFlow();
                case "2" -> listMessages();
                case "3" -> readFlow();
                case "4" -> deleteFlow();
                case "5" -> {
                    return;
                }
                default -> {
                }
            }
        }
    }

    private void sendFlow() {
        System.out.print("From: ");
        String from = readLine();
        System.out.print("Subject: ");
        String subject = readLine();
        System.out.print("Body: ");
        String body = readLine();
        Map<String, String> errors = manager.send(from, subject, body);
        if (!errors.isEmpty()) {
            for (Map.Entry<String, String> e : errors.entrySet()) {
                System.err.println(e.getKey() + ": " + e.getValue());
            }
        } else {
            List<Message> all = manager.list();
            System.out.println("Message sent (id=" + all.get(all.size() - 1).getId() + ")");
        }
    }

    private void listMessages() {
        List<Message> all = manager.list();
        if (all.isEmpty()) {
            System.out.println("No messages.");
            return;
        }
        for (Message m : all) {
            String status = m.isRead() ? "✓" : "✗";
            System.out.println("[" + m.getId() + "] " + status + " From: " + m.getFrom() + " | Subject: " + m.getSubject() + " | " + m.getCreatedAt());
        }
    }

    private void readFlow() {
        System.out.print("Message ID: ");
        String input = readLine();
        try {
            int id = Integer.parseInt(input.trim());
            Message msg = manager.read(id);
            if (msg != null) {
                System.out.println("From: " + msg.getFrom());
                System.out.println("Subject: " + msg.getSubject());
                System.out.println("Date: " + msg.getCreatedAt());
                System.out.println("---\n" + msg.getBody());
            } else {
                System.out.println("Message not found.");
            }
        } catch (NumberFormatException e) {
        }
    }

    private void deleteFlow() {
        System.out.print("Message ID: ");
        String input = readLine();
        try {
            int id = Integer.parseInt(input.trim());
            if (manager.delete(id)) {
                System.out.println("Message deleted.");
            } else {
                System.out.println("Message not found.");
            }
        } catch (NumberFormatException e) {
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
