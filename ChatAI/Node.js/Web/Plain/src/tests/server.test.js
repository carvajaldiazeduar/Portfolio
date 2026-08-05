const request = require('supertest');
const app = require('../server');

jest.mock('node:fs');

describe('ChatAI API', () => {
  test('GET / returns HTML', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
  });

  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('POST /api/chat with empty messages returns 400', async () => {
    const res = await request(app).post('/api/chat').send({ messages: [] });
    expect(res.statusCode).toBe(400);
  });

  test('POST /api/chat returns assistant response', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        id: 'chatcmpl-test',
        model: 'gpt-4o-mini',
        choices: [{ message: { role: 'assistant', content: 'Hello!' } }],
        usage: { prompt_tokens: 5, completion_tokens: 3, total_tokens: 8 },
      }),
    });
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.choices[0].role).toBe('assistant');
    expect(res.body.choices[0].content).toBe('Hello!');
    expect(res.body.id).toBe('chatcmpl-test');
    expect(res.body.usage.total_tokens).toBe(8);
  });

  test('POST /api/chat provider failure returns 502', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 500,
      text: async () => 'boom',
    });
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
    });
    expect(res.statusCode).toBe(502);
  });
});
