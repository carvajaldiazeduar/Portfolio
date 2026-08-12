package com.portfolio.inboxes;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class InboxManager {
    private final List<Message> messages = new ArrayList<>();
    private int nextId = 1;

    public List<Message> list() {
        return new ArrayList<>(messages);
    }

    public Map<String, String> send(String from, String subject, String body) {
        Map<String, String> errors = MessageValidator.validate(from, subject, body);
        if (!errors.isEmpty()) {
            return errors;
        }
        messages.add(new Message(nextId++, from.trim(), subject.trim(), body.trim()));
        return errors;
    }

    public Message read(int id) {
        for (Message message : messages) {
            if (message.getId() == id) {
                message.setRead(true);
                return message;
            }
        }
        return null;
    }

    public boolean delete(int id) {
        for (int i = 0; i < messages.size(); i++) {
            if (messages.get(i).getId() == id) {
                messages.remove(i);
                return true;
            }
        }
        return false;
    }
}
