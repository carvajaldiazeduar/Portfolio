const {
  sendMessage,
  listMessages,
  readMessage,
  deleteMessage,
} = require("../inboxes");

let fresh;

beforeEach(() => {
  jest.resetModules();
  fresh = require("../inboxes");
});

describe("Inbox CLI", () => {
  test("sendMessage creates message", () => {
    const msg = fresh.sendMessage("alice", "Hello", "World");
    expect(msg.id).toBe(1);
    expect(msg.from).toBe("alice");
    expect(msg.subject).toBe("Hello");
    expect(msg.body).toBe("World");
    expect(msg.read).toBe(false);
    expect(msg.created_at).toBeDefined();
  });

  test("listMessages returns all", () => {
    fresh.sendMessage("alice", "S1", "B1");
    fresh.sendMessage("bob", "S2", "B2");
    expect(fresh.listMessages()).toHaveLength(2);
  });

  test("readMessage marks as read", () => {
    fresh.sendMessage("alice", "Test", "Body");
    const msg = fresh.readMessage(1);
    expect(msg).not.toBeNull();
    expect(msg.read).toBe(true);
    const msg2 = fresh.readMessage(1);
    expect(msg2.read).toBe(true);
  });

  test("deleteMessage removes it", () => {
    fresh.sendMessage("alice", "Del", "Me");
    expect(fresh.listMessages()).toHaveLength(1);
    expect(fresh.deleteMessage(1)).toBe(true);
    expect(fresh.listMessages()).toHaveLength(0);
  });

  test("listAfterDelete shows remaining", () => {
    fresh.sendMessage("alice", "Keep", "Me");
    fresh.sendMessage("bob", "Delete", "This");
    fresh.deleteMessage(2);
    const msgs = fresh.listMessages();
    expect(msgs).toHaveLength(1);
    expect(msgs[0].id).toBe(1);
  });

  test("readMessage nonexistent returns null", () => {
    expect(fresh.readMessage(999)).toBeNull();
  });

  test("deleteMessage nonexistent returns false", () => {
    expect(fresh.deleteMessage(999)).toBe(false);
  });
});
