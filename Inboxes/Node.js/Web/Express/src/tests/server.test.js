const request = require("supertest");
const app = require("../server");

describe("Inbox API", () => {
  beforeEach(async () => {
    await app.resetMessages();
  });

  test("GET /api/messages returns empty array", async () => {
    const res = await request(app).get("/api/messages");
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  test("POST /api/messages creates message", async () => {
    const res = await request(app)
      .post("/api/messages")
      .send({ from: "alice", subject: "Hello", body: "World" });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.from).toBe("alice");
    expect(res.body.subject).toBe("Hello");
    expect(res.body.body).toBe("World");
    expect(res.body.read).toBe(false);
    expect(res.body.created_at).toBeDefined();
  });

  test("GET /api/messages lists all", async () => {
    await request(app).post("/api/messages").send({ from: "a", subject: "s1", body: "b1" });
    await request(app).post("/api/messages").send({ from: "b", subject: "s2", body: "b2" });
    const res = await request(app).get("/api/messages");
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);
  });

  test("GET /api/messages/:id marks as read", async () => {
    const post = await request(app).post("/api/messages").send({ from: "a", subject: "s", body: "b" });
    const res = await request(app).get(`/api/messages/${post.body.id}`);
    expect(res.status).toBe(200);
    expect(res.body.read).toBe(true);
  });

  test("GET /api/messages/:id nonexistent returns 404", async () => {
    const res = await request(app).get("/api/messages/999");
    expect(res.status).toBe(404);
  });

  test("DELETE /api/messages/:id removes message", async () => {
    const post = await request(app).post("/api/messages").send({ from: "a", subject: "s", body: "b" });
    const del = await request(app).delete(`/api/messages/${post.body.id}`);
    expect(del.status).toBe(204);
    const list = await request(app).get("/api/messages");
    expect(list.body).toHaveLength(0);
  });

  test("DELETE /api/messages/:id nonexistent returns 404", async () => {
    const res = await request(app).delete("/api/messages/999");
    expect(res.status).toBe(404);
  });

  test("list after delete shows remaining", async () => {
    const p1 = await request(app).post("/api/messages").send({ from: "a", subject: "keep", body: "me" });
    const p2 = await request(app).post("/api/messages").send({ from: "b", subject: "del", body: "this" });
    await request(app).delete(`/api/messages/${p2.body.id}`);
    const list = await request(app).get("/api/messages");
    expect(list.body).toHaveLength(1);
    expect(list.body[0].id).toBe(p1.body.id);
  });
});
