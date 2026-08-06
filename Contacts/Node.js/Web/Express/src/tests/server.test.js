const request = require('supertest');
const app = require('../server');

beforeEach(() => {
  app.resetContacts();
});

describe('Contacts API', () => {
  test('GET /api/contacts returns empty array', async () => {
    const res = await request(app).get('/api/contacts');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  test('POST /api/contacts adds a contact', async () => {
    const res = await request(app)
      .post('/api/contacts')
      .send({ name: 'Alice', phone: '123', email: 'a@b.com' });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Alice');
  });

  test('POST /api/contacts missing name returns 400', async () => {
    const res = await request(app)
      .post('/api/contacts')
      .send({ phone: '123' });
    expect(res.status).toBe(400);
  });

  test('GET /api/contacts/search filters by name', async () => {
    await request(app).post('/api/contacts').send({ name: 'Alice', phone: '123', email: 'a@b.com' });
    await request(app).post('/api/contacts').send({ name: 'Bob', phone: '456', email: 'b@c.com' });
    const res = await request(app).get('/api/contacts/search?q=ali');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].name).toBe('Alice');
  });

  test('DELETE /api/contacts/:id removes contact', async () => {
    const post = await request(app).post('/api/contacts').send({ name: 'Alice', phone: '123', email: 'a@b.com' });
    const res = await request(app).delete(`/api/contacts/${post.body.id}`);
    expect(res.status).toBe(200);
    const getRes = await request(app).get('/api/contacts');
    expect(getRes.body).toEqual([]);
  });

  test('DELETE /api/contacts/:index invalid returns 404', async () => {
    const res = await request(app).delete('/api/contacts/99');
    expect(res.status).toBe(404);
  });
});
