const request = require('supertest');
const app = require('../server');

describe('SemanticSearch API', () => {
  test('GET / returns HTML', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
  });

  test('GET /api/search without query returns 400', async () => {
    const res = await request(app).get('/api/search');
    expect(res.statusCode).toBe(400);
  });

  test('GET /api/collections returns list', async () => {
    const res = await request(app).get('/api/collections');
    expect(res.statusCode).toBe(200);
  });
});