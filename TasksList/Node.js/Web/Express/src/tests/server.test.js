const request = require("supertest");
const app = require("../server");

describe("Tasks API", () => {
  test("GET / returns HTML", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toMatch(/html/);
  });

  test("POST /api/tasks adds task", async () => {
    const res = await request(app)
      .post("/api/tasks")
      .send({ title: "Test", description: "A task" });
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(1);
  });

  test("GET /api/tasks lists tasks", async () => {
    await request(app).post("/api/tasks").send({ title: "Test" });
    const res = await request(app).get("/api/tasks");
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
  });

  test("PUT /api/tasks/:id/complete marks task as done", async () => {
    const post = await request(app).post("/api/tasks").send({ title: "Test" });
    const res = await request(app).put(`/api/tasks/${post.body.id}/complete`);
    expect(res.status).toBe(200);
  });

  test("DELETE /api/tasks/:id removes task", async () => {
    const post = await request(app).post("/api/tasks").send({ title: "Test" });
    const res = await request(app).delete(`/api/tasks/${post.body.id}`);
    expect(res.status).toBe(200);
  });
});
