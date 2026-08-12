package com.portfolio.tasks;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Map;

public class TasksCli {
    private final TasksManager manager = new TasksManager();
    private final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

    public static void main(String[] args) {
        new TasksCli().run();
    }

    public void run() {
        while (true) {
            System.out.println("\n=== Tasks List ===");
            System.out.println("1. Add Task");
            System.out.println("2. List Tasks");
            System.out.println("3. Complete Task");
            System.out.println("4. Delete Task");
            System.out.println("5. Exit");
            System.out.print("Choose an option: ");
            String choice = readLine();
            switch (choice) {
                case "1" -> addTaskFlow();
                case "2" -> manager.listTasks();
                case "3" -> completeTaskFlow();
                case "4" -> deleteTaskFlow();
                case "5" -> {
                    System.out.println("Goodbye!");
                    return;
                }
                default -> System.out.println("Invalid option.");
            }
        }
    }

    private void addTaskFlow() {
        System.out.print("Title: ");
        String title = readLine();
        System.out.print("Description: ");
        String description = readLine();
        Map<String, String> errors = manager.addTask(title, description);
        if (!errors.isEmpty()) {
            for (Map.Entry<String, String> e : errors.entrySet()) {
                System.err.println(e.getKey() + ": " + e.getValue());
            }
        } else {
            System.out.println("Task added.");
        }
    }

    private void completeTaskFlow() {
        System.out.print("Task ID to complete: ");
        String input = readLine();
        try {
            int id = Integer.parseInt(input.trim());
            if (manager.completeTask(id)) {
                System.out.println("Task completed.");
            } else {
                System.out.println("Task not found.");
            }
        } catch (NumberFormatException e) {
            System.out.println("Invalid ID.");
        }
    }

    private void deleteTaskFlow() {
        System.out.print("Task ID to delete: ");
        String input = readLine();
        try {
            int id = Integer.parseInt(input.trim());
            if (manager.deleteTask(id)) {
                System.out.println("Task deleted.");
            } else {
                System.out.println("Task not found.");
            }
        } catch (NumberFormatException e) {
            System.out.println("Invalid ID.");
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
