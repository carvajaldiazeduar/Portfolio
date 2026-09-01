package com.portfolio.inboxes;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class MessageInput {
    @NotBlank(message = "From is required")
    @Size(max = 255, message = "From must be 1-255 characters")
    private String from;

    @NotBlank(message = "Subject is required")
    @Size(max = 300, message = "Subject must be 1-300 characters")
    private String subject;

    @NotBlank(message = "Body is required")
    @Size(max = 1000, message = "Body must be 1-1000 characters")
    private String body;

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
}
