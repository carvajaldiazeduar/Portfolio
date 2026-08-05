const request = require('supertest');
const { app, generatePassword, UPPERCASE, LOWERCASE, DIGITS, SYMBOLS } = require('../server');

describe('Password Generator API', () => {
  test('POST /api/generate returns default length 16', async () => {
    const res = await request(app).post('/api/generate').send({});
    expect(res.status).toBe(200);
    expect(res.body.password).toHaveLength(16);
  });

  test('POST /api/generate custom length', async () => {
    const res = await request(app).post('/api/generate').send({ length: 24 });
    expect(res.status).toBe(200);
    expect(res.body.password).toHaveLength(24);
  });

  test('POST /api/generate no uppercase', async () => {
    const res = await request(app).post('/api/generate').send({ use_upper: false });
    expect(res.status).toBe(200);
    expect(res.body.password).not.toMatch(/[A-Z]/);
  });

  test('POST /api/generate no symbols', async () => {
    const res = await request(app).post('/api/generate').send({ use_symbols: false });
    expect(res.status).toBe(200);
    expect(res.body.password).not.toMatch(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/);
  });

  test('POST /api/generate all disabled returns 400', async () => {
    const res = await request(app).post('/api/generate').send({
      use_upper: false, use_lower: false, use_digits: false, use_symbols: false
    });
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  test('POST /api/generate bad length returns 400', async () => {
    const res = await request(app).post('/api/generate').send({ length: -1 });
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  test('POST /api/generate at least one from each', async () => {
    const res = await request(app).post('/api/generate').send({
      length: 20, use_upper: true, use_lower: true, use_digits: true, use_symbols: true
    });
    expect(res.status).toBe(200);
    expect(res.body.password).toMatch(/[A-Z]/);
    expect(res.body.password).toMatch(/[a-z]/);
    expect(res.body.password).toMatch(/[0-9]/);
    expect(res.body.password).toMatch(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/);
  });

  test('GET / serves index.html', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/html/);
  });
});

describe('generatePassword unit tests', () => {
  test('default length is 16', () => {
    expect(generatePassword()).toHaveLength(16);
  });

  test('throws on length 0', () => {
    expect(() => generatePassword(0)).toThrow();
  });

  test('no uppercase when disabled', () => {
    expect(generatePassword(16, false)).not.toMatch(/[A-Z]/);
  });

  test('no symbols when disabled', () => {
    expect(generatePassword(16, true, true, true, false)).not.toMatch(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/);
  });

  test('all disabled throws', () => {
    expect(() => generatePassword(10, false, false, false, false)).toThrow();
  });
});
