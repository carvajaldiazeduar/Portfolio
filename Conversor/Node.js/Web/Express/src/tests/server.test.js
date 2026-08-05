const request = require('supertest');
const app = require('../server');

describe('GET /api/categories', () => {
  it('returns all categories with units', async () => {
    const res = await request(app).get('/api/categories');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('length');
    expect(res.body).toHaveProperty('weight');
    expect(res.body).toHaveProperty('temperature');
  });
});

describe('POST /api/convert', () => {
  it('converts length', async () => {
    const res = await request(app)
      .post('/api/convert')
      .send({ value: 1, from: 'm', to: 'cm' });
    expect(res.status).toBe(200);
    expect(Math.abs(res.body.result - 100)).toBeLessThan(0.001);
  });

  it('converts weight', async () => {
    const res = await request(app)
      .post('/api/convert')
      .send({ value: 1, from: 'kg', to: 'g' });
    expect(res.status).toBe(200);
    expect(Math.abs(res.body.result - 1000)).toBeLessThan(0.001);
  });

  it('converts temperature C to F', async () => {
    const res = await request(app)
      .post('/api/convert')
      .send({ value: 0, from: 'C', to: 'F' });
    expect(res.status).toBe(200);
    expect(Math.abs(res.body.result - 32)).toBeLessThan(0.001);
  });

  it('returns 400 for incompatible units', async () => {
    const res = await request(app)
      .post('/api/convert')
      .send({ value: 1, from: 'm', to: 'kg' });
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  it('returns 400 for missing fields', async () => {
    const res = await request(app)
      .post('/api/convert')
      .send({ value: 1 });
    expect(res.status).toBe(400);
  });
});
