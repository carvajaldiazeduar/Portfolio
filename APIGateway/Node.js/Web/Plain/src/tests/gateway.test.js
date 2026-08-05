const request = require('supertest');
const app = require('../server');
const { generateToken } = require('../middleware/auth');

describe('API Gateway', () => {
  let adminToken, userToken;

  beforeAll(() => {
    adminToken = generateToken({ id: 1, username: 'admin', roles: ['admin'] });
    userToken = generateToken({ id: 2, username: 'user', roles: ['user'] });
  });

  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('POST /auth/login with valid credentials returns token', async () => {
    const res = await request(app)
      .post('/auth/login')
      .send({ username: 'admin', password: 'admin' });
    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
  });

  test('POST /auth/login with invalid credentials returns 401', async () => {
    const res = await request(app)
      .post('/auth/login')
      .send({ username: 'wrong', password: 'wrong' });
    expect(res.status).toBe(401);
  });

  test('Protected route without token returns 401', async () => {
    const res = await request(app).get('/api/users');
    expect(res.status).toBe(401);
  });

  test('Protected route with valid token passes auth', async () => {
    const res = await request(app)
      .get('/api/users')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).not.toBe(401);
  });

  test('Rate limiting works', async () => {
    for (let i = 0; i < 55; i++) {
      await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${userToken}`);
    }
    const res = await request(app)
      .get('/api/users')
      .set('Authorization', `Bearer ${userToken}`);
    expect(res.status).toBe(429);
  });
});