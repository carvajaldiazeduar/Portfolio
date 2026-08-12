package com.portfolio.inboxes;

import java.time.OffsetDateTime;

public class Message {
    private int id;
    private String from;
    private String subject;
    private String body;
    private boolean read;
    private String createdAt;

    public Message() {
    }

    public Message(int id, String from, String subject, String body) {
        this.id = id;
        this.from = from;
        this.subject = subject;
        this.body = body;
        this.read = false;
        this.createdAt = OffsetDateTime.now().toString();
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getFrom() {
        return from;
    }

    public void setFrom(String from) {
        this.from = from;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public boolean isRead() {
        return read;
    }

    public void setRead(boolean read) {
        this.read = read;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}
