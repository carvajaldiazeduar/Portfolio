const request = require('supertest');
const app = require('../server');
const { validateContact } = app;

beforeEach(async () => {
  try {
    await app.resetContacts();
  } catch (e) {
    // DB may be unavailable in this environment; validation unit tests still run.
  }
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
      .send({ name: 'Alice', phone: '1234567', email: 'a@b.com' });
    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Alice');
  });

  test('POST /api/contacts invalid email returns 400 with errors.email', async () => {
    const res = await request(app)
      .post('/api/contacts')
      .send({ name: 'Alice', phone: '1234567', email: 'not-an-email' });
    expect(res.status).toBe(400);
    expect(res.body.errors.email).toBe('Invalid email format');
  });

  test('POST /api/contacts invalid phone returns 400 with errors.phone', async () => {
    const res = await request(app)
      .post('/api/contacts')
      .send({ name: 'Alice', phone: '123', email: 'a@b.com' });
    expect(res.status).toBe(400);
    expect(res.body.errors.phone).toBe('Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)');
  });

  test('POST /api/contacts missing name returns 400 with errors.name', async () => {
    const res = await request(app)
      .post('/api/contacts')
      .send({ phone: '1234567', email: 'a@b.com' });
    expect(res.status).toBe(400);
    expect(res.body.errors.name).toBe('Name is required');
  });

  test('POST /api/contacts valid returns 201', async () => {
    const res = await request(app)
      .post('/api/contacts')
      .send({ name: 'Alice Smith', phone: '+1 (555) 123-4567', email: 'alice@test.com' });
    expect(res.status).toBe(201);
    expect(res.body.phone).toBe('+1 (555) 123-4567');
  });

  test('GET /api/contacts/search filters by name', async () => {
    await request(app).post('/api/contacts').send({ name: 'Alice', phone: '1234567', email: 'a@b.com' });
    await request(app).post('/api/contacts').send({ name: 'Bob', phone: '7654321', email: 'b@c.com' });
    const res = await request(app).get('/api/contacts/search?q=ali');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].name).toBe('Alice');
  });

  test('DELETE /api/contacts/:id removes contact', async () => {
    const post = await request(app).post('/api/contacts').send({ name: 'Alice', phone: '1234567', email: 'a@b.com' });
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

describe('validateContact', () => {
  test('rejects invalid email', () => {
    expect(validateContact('Alice', '1234567', 'not-an-email')).toEqual({ email: 'Invalid email format' });
  });

  test('rejects invalid phone', () => {
    expect(validateContact('Alice', '123', 'a@b.com')).toEqual({ phone: 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)' });
  });

  test('rejects missing or too-short name', () => {
    expect(validateContact('', '1234567', 'a@b.com')).toEqual({ name: 'Name is required' });
    expect(validateContact('A', '1234567', 'a@b.com')).toEqual({ name: 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)' });
  });

  test('rejects missing phone and email', () => {
    expect(validateContact('Alice', '', 'a@b.com')).toEqual({ phone: 'Phone is required' });
    expect(validateContact('Alice', '1234567', '')).toEqual({ email: 'Email is required' });
  });

  test('accepts a valid contact', () => {
    expect(validateContact('Alice Smith', '+1 (555) 123-4567', 'alice@test.com')).toEqual({});
  });
});
