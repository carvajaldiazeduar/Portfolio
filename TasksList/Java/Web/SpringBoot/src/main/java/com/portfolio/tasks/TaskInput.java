package com.portfolio.tasks;

import jakarta.validation.constraints.NotBlank;

public class TaskInput {
    @NotBlank(message = "Title is required")
    private String title;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }
}
