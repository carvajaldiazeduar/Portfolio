package com.portfolio.tasks;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TasksManagerTest {

    @Test
    void addTaskAddsTaskAndReturnsId() {
        TasksManager manager = new TasksManager();
        Map<String, String> errors = manager.addTask("Test", "A task");
        assertTrue(errors.isEmpty());
        List<Task> tasks = manager.getTasks();
        assertEquals(1, tasks.size());
        assertEquals("Test", tasks.get(0).getTitle());
        assertEquals("A task", tasks.get(0).getDescription());
        assertFalse(tasks.get(0).isCompleted());
        assertNotNull(tasks.get(0).getCreatedAt());
    }

    @Test
    void addTaskAutoIncrementsId() {
        TasksManager manager = new TasksManager();
        manager.addTask("a", "");
        manager.addTask("b", "");
        List<Task> tasks = manager.getTasks();
        assertEquals(1, tasks.get(0).getId());
        assertEquals(2, tasks.get(1).getId());
    }

    @Test
    void listTasksEmptyPrintsMessage() {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        System.setOut(new PrintStream(out));
        try {
            new TasksManager().listTasks();
            assertTrue(out.toString().contains("No tasks found."));
        } finally {
            System.setOut(System.out);
        }
    }

    @Test
    void listTasksShowsIncomplete() {
        TasksManager manager = new TasksManager();
        manager.addTask("Buy milk", "");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        System.setOut(new PrintStream(out));
        try {
            manager.listTasks();
            String output = out.toString();
            assertTrue(output.contains("[ ]"));
            assertTrue(output.contains("Buy milk"));
        } finally {
            System.setOut(System.out);
        }
    }

    @Test
    void listTasksShowsCompleted() {
        TasksManager manager = new TasksManager();
        manager.addTask("Done", "");
        manager.completeTask(1);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        System.setOut(new PrintStream(out));
        try {
            manager.listTasks();
            assertTrue(out.toString().contains("[x]"));
        } finally {
            System.setOut(System.out);
        }
    }

    @Test
    void completeTaskMarksComplete() {
        TasksManager manager = new TasksManager();
        manager.addTask("a", "");
        assertTrue(manager.completeTask(1));
        assertTrue(manager.getTasks().get(0).isCompleted());
    }

    @Test
    void completeTaskNotFoundReturnsFalse() {
        TasksManager manager = new TasksManager();
        assertFalse(manager.completeTask(99));
    }

    @Test
    void deleteTaskRemoves() {
        TasksManager manager = new TasksManager();
        manager.addTask("a", "");
        assertTrue(manager.deleteTask(1));
        assertTrue(manager.getTasks().isEmpty());
    }

    @Test
    void deleteTaskNotFoundReturnsFalse() {
        TasksManager manager = new TasksManager();
        manager.addTask("a", "");
        assertFalse(manager.deleteTask(99));
        assertEquals(1, manager.getTasks().size());
    }

    @Test
    void addTaskWithBlankTitleReturnsError() {
        TasksManager manager = new TasksManager();
        Map<String, String> errors = manager.addTask("", "");
        assertEquals(Map.of("title", "Title is required"), errors);
        assertTrue(manager.getTasks().isEmpty());
    }
}
