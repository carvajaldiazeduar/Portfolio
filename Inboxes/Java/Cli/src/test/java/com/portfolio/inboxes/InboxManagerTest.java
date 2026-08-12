package com.portfolio.inboxes;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class InboxManagerTest {

    @Test
    void sendCreatesMessage() {
        InboxManager manager = new InboxManager();
        Map<String, String> errors = manager.send("alice", "Hello", "World");
        assertTrue(errors.isEmpty());
        List<Message> messages = manager.list();
        assertEquals(1, messages.size());
        Message msg = messages.get(0);
        assertEquals(1, msg.getId());
        assertEquals("alice", msg.getFrom());
        assertEquals("Hello", msg.getSubject());
        assertEquals("World", msg.getBody());
        assertFalse(msg.isRead());
        assertNotNull(msg.getCreatedAt());
    }

    @Test
    void listIsEmptyInitially() {
        InboxManager manager = new InboxManager();
        assertTrue(manager.list().isEmpty());
    }

    @Test
    void listReturnsAll() {
        InboxManager manager = new InboxManager();
        manager.send("alice", "S1", "B1");
        manager.send("bob", "S2", "B2");
        assertEquals(2, manager.list().size());
    }

    @Test
    void readMarksAsRead() {
        InboxManager manager = new InboxManager();
        manager.send("alice", "Test", "Body");
        Message msg = manager.read(1);
        assertNotNull(msg);
        assertTrue(msg.isRead());
        assertTrue(manager.read(1).isRead());
    }

    @Test
    void deleteRemovesIt() {
        InboxManager manager = new InboxManager();
        manager.send("alice", "Del", "Me");
        assertEquals(1, manager.list().size());
        assertTrue(manager.delete(1));
        assertTrue(manager.list().isEmpty());
    }

    @Test
    void listAfterDeleteShowsRemaining() {
        InboxManager manager = new InboxManager();
        manager.send("alice", "Keep", "Me");
        manager.send("bob", "Delete", "This");
        manager.delete(2);
        List<Message> messages = manager.list();
        assertEquals(1, messages.size());
        assertEquals(1, messages.get(0).getId());
    }

    @Test
    void readNonexistentReturnsNull() {
        InboxManager manager = new InboxManager();
        assertNull(manager.read(999));
    }

    @Test
    void deleteNonexistentReturnsFalse() {
        InboxManager manager = new InboxManager();
        assertFalse(manager.delete(999));
    }

    @Test
    void sendWithEmptyFromIsNotAdded() {
        InboxManager manager = new InboxManager();
        Map<String, String> errors = manager.send("", "Hello", "World");
        assertEquals(Map.of("from", "From is required"), errors);
        assertTrue(manager.list().isEmpty());
    }

    @Test
    void sendWithEmptySubjectIsNotAdded() {
        InboxManager manager = new InboxManager();
        Map<String, String> errors = manager.send("alice", "", "World");
        assertEquals(Map.of("subject", "Subject is required"), errors);
        assertTrue(manager.list().isEmpty());
    }

    @Test
    void sendWithEmptyBodyIsNotAdded() {
        InboxManager manager = new InboxManager();
        Map<String, String> errors = manager.send("alice", "Hello", "");
        assertEquals(Map.of("body", "Body is required"), errors);
        assertTrue(manager.list().isEmpty());
    }
}
