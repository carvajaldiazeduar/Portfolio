package com.portfolio.tasks;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class TasksManager {
    private final List<Task> tasks = new ArrayList<>();

    public List<Task> getTasks() {
        return new ArrayList<>(tasks);
    }

    public Map<String, String> addTask(String title, String description) {
        Map<String, String> errors = TaskValidator.validate(title);
        if (!errors.isEmpty()) {
            return errors;
        }
        tasks.add(new Task(nextId(), title.trim(), description == null ? "" : description.trim(),
                false, OffsetDateTime.now().toString()));
        return errors;
    }

    public void listTasks() {
        if (tasks.isEmpty()) {
            System.out.println("No tasks found.");
            return;
        }
        for (Task t : tasks) {
            String status = t.isCompleted() ? "[x]" : "[ ]";
            System.out.println(status + " " + t.getId() + ". " + t.getTitle() + " \u2014 " + t.getCreatedAt());
        }
    }

    public boolean completeTask(int id) {
        Task task = findById(id);
        if (task == null) {
            return false;
        }
        task.setCompleted(true);
        return true;
    }

    public boolean deleteTask(int id) {
        Task task = findById(id);
        if (task == null) {
            return false;
        }
        tasks.remove(task);
        return true;
    }

    private Task findById(int id) {
        for (Task t : tasks) {
            if (t.getId() == id) {
                return t;
            }
        }
        return null;
    }

    private int nextId() {
        int max = 0;
        for (Task t : tasks) {
            max = Math.max(max, t.getId());
        }
        return max + 1;
    }
}
