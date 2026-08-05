const request = require("supertest");
const app = require("../server");

describe("Calculator API", () => {
  test("GET / returns HTML", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toMatch(/html/);
  });

  test("POST /calculate add", async () => {
    const res = await request(app)
      .post("/calculate")
      .send({ a: 2, b: 3, operator: "add" });
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(5);
  });

  test("POST /calculate subtract", async () => {
    const res = await request(app)
      .post("/calculate")
      .send({ a: 5, b: 3, operator: "subtract" });
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(2);
  });

  test("POST /calculate multiply", async () => {
    const res = await request(app)
      .post("/calculate")
      .send({ a: 2, b: 3, operator: "multiply" });
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(6);
  });

  test("POST /calculate divide", async () => {
    const res = await request(app)
      .post("/calculate")
      .send({ a: 6, b: 3, operator: "divide" });
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(2);
  });

  test("POST /calculate divide by zero", async () => {
    const res = await request(app)
      .post("/calculate")
      .send({ a: 5, b: 0, operator: "divide" });
    expect(res.status).toBe(400);
  });

  test("POST /calculate invalid operator", async () => {
    const res = await request(app)
      .post("/calculate")
      .send({ a: 2, b: 3, operator: "power" });
    expect(res.status).toBe(400);
  });

  test("POST /calculate invalid input", async () => {
    const res = await request(app)
      .post("/calculate")
      .send({ a: "foo", b: 3, operator: "add" });
    expect(res.status).toBe(400);
  });
});
