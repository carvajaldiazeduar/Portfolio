const request = require('supertest');
const app = require('../server');

const OPENAI_OK = {
  id: 'chatcmpl-test',
  model: 'gpt-4o-mini',
  choices: [{ message: { role: 'assistant', content: 'Hello!' } }],
  usage: { prompt_tokens: 5, completion_tokens: 3, total_tokens: 8 },
};

const GOOGLE_OK = {
  candidates: [{ content: { role: 'model', parts: [{ text: 'Hi from google' }] } }],
  usageMetadata: { promptTokens: 5, candidatesTokens: 3, totalTokens: 8 },
};

const ANTHROPIC_OK = {
  content: [{ type: 'text', text: 'Hi from anthropic' }],
  usage: { input_tokens: 5, output_tokens: 3 },
};

function mockFetchReturning(body) {
  global.fetch = jest.fn().mockResolvedValue({ ok: true, json: async () => body });
}

function captureFetch(body) {
  let captured;
  global.fetch = jest.fn((url, opts) => {
    captured = { url, opts };
    return Promise.resolve({ ok: true, json: async () => body });
  });
  return () => captured;
}

function mockFetchFailure(status, text) {
  global.fetch = jest.fn().mockResolvedValue({ ok: false, status, text: async () => text });
}

const ORIGINAL_ENV = { ...process.env };

afterEach(() => {
  delete process.env.OPENAI_API_KEY;
  delete process.env.CHAT_PROVIDER;
  delete process.env.CHAT_FALLBACK_PROVIDER;
  delete process.env.CHAT_TIMEOUT_MS;
  delete process.env.AZURE_OPENAI_API_KEY;
  delete process.env.GOOGLE_API_KEY;
  delete process.env.ANTHROPIC_API_KEY;
  delete global.fetch;
});

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

  test('POST /api/chat returns assistant response with resolved provider', async () => {
    process.env.OPENAI_API_KEY = 'test-key';
    mockFetchReturning(OPENAI_OK);
    const res = await request(app).post('/api/chat').send({ messages: [{ role: 'user', content: 'Hi' }] });
    expect(res.statusCode).toBe(200);
    expect(res.body.choices[0].role).toBe('assistant');
    expect(res.body.choices[0].content).toBe('Hello!');
    expect(res.body.id).toBe('chatcmpl-test');
    expect(res.body.provider).toBe('openai');
    expect(res.body.usage.total_tokens).toBe(8);
  });

  test('client overrides model/temperature/max_tokens', async () => {
    process.env.OPENAI_API_KEY = 'test-key';
    const getCaptured = captureFetch(OPENAI_OK);
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
      model: 'gpt-4-turbo',
      temperature: 0.2,
      max_tokens: 500,
    });
    expect(res.statusCode).toBe(200);
    const { opts } = getCaptured();
    const body = JSON.parse(opts.body);
    expect(body.model).toBe('gpt-4-turbo');
    expect(body.temperature).toBe(0.2);
    expect(body.max_tokens).toBe(500);
  });

  test('openai sends bearer auth and correct payload', async () => {
    process.env.OPENAI_API_KEY = 'test-key';
    const getCaptured = captureFetch(OPENAI_OK);
    await request(app).post('/api/chat').send({ messages: [{ role: 'user', content: 'Hi' }] });
    const { url, opts } = getCaptured();
    expect(url).toBe('https://api.openai.com/v1/chat/completions');
    expect(opts.headers.Authorization).toBe('Bearer test-key');
    const body = JSON.parse(opts.body);
    expect(body.messages).toEqual([{ role: 'user', content: 'Hi' }]);
  });

  test('POST /api/chat provider failure returns 502', async () => {
    process.env.OPENAI_API_KEY = 'test-key';
    mockFetchFailure(500, 'boom');
    const res = await request(app).post('/api/chat').send({ messages: [{ role: 'user', content: 'Hi' }] });
    expect(res.statusCode).toBe(502);
    expect(res.body.error).toContain('Provider error 500');
  });

  test('request provider overrides CHAT_PROVIDER', async () => {
    process.env.CHAT_PROVIDER = 'openai';
    process.env.AZURE_OPENAI_API_KEY = 'az-key';
    mockFetchReturning(OPENAI_OK);
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
      provider: 'azure',
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.provider).toBe('azure');
  });

  test('requested provider without API key returns 400', async () => {
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
      provider: 'azure',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe("Provider 'azure' is not configured (missing API key)");
  });

  test('unsupported provider returns 400', async () => {
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
      provider: 'not-a-provider',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe('Unsupported provider: not-a-provider');
  });

  test('fallback provider is used on primary failure and returns 200', async () => {
    process.env.OPENAI_API_KEY = 'pk';
    process.env.CHAT_FALLBACK_PROVIDER = 'azure';
    process.env.AZURE_OPENAI_API_KEY = 'az';
    let calls = 0;
    global.fetch = jest.fn(() => {
      calls += 1;
      if (calls === 1) return Promise.resolve({ ok: false, status: 503, text: async () => 'down' });
      return Promise.resolve({ ok: true, json: async () => OPENAI_OK });
    });
    const res = await request(app).post('/api/chat').send({ messages: [{ role: 'user', content: 'Hi' }] });
    expect(res.statusCode).toBe(200);
    expect(calls).toBe(2);
    expect(res.body.provider).toBe('azure');
  });

  test('fallback without API key returns 502', async () => {
    process.env.OPENAI_API_KEY = 'pk';
    process.env.CHAT_FALLBACK_PROVIDER = 'azure';
    mockFetchFailure(503, 'down');
    const res = await request(app).post('/api/chat').send({ messages: [{ role: 'user', content: 'Hi' }] });
    expect(res.statusCode).toBe(502);
  });

  test('CHAT_TIMEOUT_MS expiry returns 502 with timeout error', async () => {
    process.env.OPENAI_API_KEY = 'test-key';
    process.env.CHAT_TIMEOUT_MS = '100';
    global.fetch = jest.fn((url, opts) => new Promise((_, reject) => {
      if (opts.signal) {
        opts.signal.addEventListener('abort', () => reject(Object.assign(new Error('aborted'), { name: 'AbortError' })));
      }
    }));
    const res = await request(app).post('/api/chat').send({ messages: [{ role: 'user', content: 'Hi' }] });
    expect(res.statusCode).toBe(502);
    expect(res.body.error).toContain('CHAT_TIMEOUT_MS');
  });

  test('google provider builds contents payload and normalizes response', async () => {
    process.env.GOOGLE_API_KEY = 'g-key';
    const getCaptured = captureFetch(GOOGLE_OK);
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
      provider: 'google',
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.provider).toBe('google');
    expect(res.body.choices[0].content).toBe('Hi from google');
    const { url, opts } = getCaptured();
    expect(url).toContain('/v1beta/models/gpt-4o-mini:generateContent?key=g-key');
    const body = JSON.parse(opts.body);
    expect(body.contents[0].role).toBe('user');
  });

  test('anthropic provider sends x-api-key and normalizes response', async () => {
    process.env.ANTHROPIC_API_KEY = 'a-key';
    const getCaptured = captureFetch(ANTHROPIC_OK);
    const res = await request(app).post('/api/chat').send({
      messages: [{ role: 'user', content: 'Hi' }],
      provider: 'anthropic',
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.provider).toBe('anthropic');
    expect(res.body.choices[0].content).toBe('Hi from anthropic');
    expect(res.body.usage.total_tokens).toBe(8);
    const { url, opts } = getCaptured();
    expect(url).toBe('https://api.anthropic.com/v1/messages');
    expect(opts.headers['x-api-key']).toBe('a-key');
    expect(opts.headers['anthropic-version']).toBe('2023-06-01');
  });
});
