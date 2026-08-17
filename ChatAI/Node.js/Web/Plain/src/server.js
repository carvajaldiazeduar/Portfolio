const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

const env = (name, fallback) => process.env[name] || fallback;

class ProviderNotConfiguredError extends Error {}
class UnsupportedProviderError extends Error {}

const PROVIDER_CONFIGS = {
  'openai': {
    key: () => process.env.OPENAI_API_KEY || '',
    base: () => (process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1').replace(/\/+$/, ''),
  },
  'openai-compatible': {
    key: () => process.env.OPENAI_API_KEY || '',
    base: () => (process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1').replace(/\/+$/, ''),
  },
  'azure': {
    key: () => process.env.AZURE_OPENAI_API_KEY || '',
    base: () => (process.env.AZURE_OPENAI_ENDPOINT || 'https://api.openai.com/v1').replace(/\/+$/, ''),
  },
  'google': {
    key: () => process.env.GOOGLE_API_KEY || '',
    base: () => (process.env.GOOGLE_BASE_URL || 'https://generativelanguage.googleapis.com').replace(/\/+$/, ''),
  },
  'anthropic': {
    key: () => process.env.ANTHROPIC_API_KEY || '',
    base: () => (process.env.ANTHROPIC_BASE_URL || 'https://api.anthropic.com').replace(/\/+$/, ''),
  },
};

function providerConfig(name) {
  const cfg = PROVIDER_CONFIGS[name];
  if (!cfg) throw new UnsupportedProviderError(`Unsupported provider: ${name}`);
  return cfg;
}

function requireKey(name) {
  const cfg = providerConfig(name);
  if (!cfg.key()) throw new ProviderNotConfiguredError(`Provider '${name}' is not configured (missing API key)`);
  return cfg;
}

function resolveProvider(requested) {
  return requested && requested.trim() ? requested : env('CHAT_PROVIDER', 'openai');
}

function fallbackProvider() {
  const fb = process.env.CHAT_FALLBACK_PROVIDER;
  return fb && fb.trim() ? fb : null;
}

function timeoutMs() {
  const raw = parseInt(env('CHAT_TIMEOUT_MS', '30000'), 10);
  return Number.isFinite(raw) && raw > 0 ? raw : 30000;
}

function ragEnabled() {
  return ['1', 'true', 'yes'].includes((process.env.RAG_ENABLED || '').toLowerCase());
}

function ragTopK() {
  const raw = parseInt(env('RAG_TOP_K', '3'), 10);
  return Number.isFinite(raw) && raw > 0 ? raw : 3;
}

async function retrieveContext(query) {
  const url = `${env('RAG_SEARCH_URL', 'http://semantic-search:5000/api/search')}?q=${encodeURIComponent(query)}&k=${ragTopK()}`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs());
  try {
    const res = await fetch(url, { signal: controller.signal });
    if (!res.ok) return [];
    const data = await res.json();
    return (data.results || []).map((r) => r.document).filter(Boolean);
  } finally {
    clearTimeout(timer);
  }
}

function requestDefaults(body) {
  const model = body.model || env('CHAT_MODEL', 'gpt-4o-mini');
  const temperature = body.temperature != null ? body.temperature : parseFloat(env('CHAT_TEMPERATURE', '0.7'));
  const maxTokens = body.max_tokens != null ? body.max_tokens : parseInt(env('CHAT_MAX_TOKENS', '1024'), 10);
  return { model, temperature, maxTokens };
}

function normalizeResponse(provider, result, model) {
  if (provider === 'google') {
    const candidates = (result.candidates || []).map((c) =>
      ((c.content && c.content.parts) || []).map((p) => p.text || '').join('')
    ).join('');
    const usage = result.usageMetadata || {};
    return {
      id: '',
      model,
      provider,
      choices: [{ role: 'assistant', content: candidates }],
      usage: {
        prompt_tokens: usage.promptTokens || 0,
        completion_tokens: usage.candidatesTokens || 0,
        total_tokens: usage.totalTokens || 0,
      },
    };
  }
  if (provider === 'anthropic') {
    const content = (result.content || []).filter((c) => c.type === 'text').map((c) => c.text || '').join('');
    const usage = result.usage || {};
    const prompt = usage.input_tokens || 0;
    const completion = usage.output_tokens || 0;
    return {
      id: '',
      model,
      provider,
      choices: [{ role: 'assistant', content }],
      usage: { prompt_tokens: prompt, completion_tokens: completion, total_tokens: prompt + completion },
    };
  }
  const choices = (result.choices || []).map((c) => ({
    role: (c.message && c.message.role) || 'assistant',
    content: (c.message && c.message.content) || '',
  }));
  const usage = result.usage || {};
  return {
    id: result.id || '',
    model: result.model || model,
    provider,
    choices,
    usage: {
      prompt_tokens: usage.prompt_tokens || 0,
      completion_tokens: usage.completion_tokens || 0,
      total_tokens: usage.total_tokens || 0,
    },
  };
}

async function completeChat(provider, body) {
  const cfg = requireKey(provider);
  const { model, temperature, maxTokens } = requestDefaults(body);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs());

  let url;
  let headers;
  let payload;
  if (provider === 'openai' || provider === 'openai-compatible') {
    url = `${cfg.base()}/chat/completions`;
    headers = { 'Content-Type': 'application/json', ...(cfg.key() ? { Authorization: `Bearer ${cfg.key()}` } : {}) };
    payload = { model, messages: body.messages, temperature, max_tokens: maxTokens };
  } else if (provider === 'azure') {
    const apiVersion = env('AZURE_OPENAI_API_VERSION', '2024-06-01-preview');
    const deployment = env('AZURE_OPENAI_DEPLOYMENT', 'gpt-4o-mini');
    url = `${cfg.base()}/openai/deployments/${deployment}/chat/completions?api-version=${apiVersion}`;
    headers = { 'Content-Type': 'application/json', 'api-key': cfg.key() };
    payload = { model, messages: body.messages, temperature, max_tokens: maxTokens };
  } else if (provider === 'google') {
    url = `${cfg.base()}/v1beta/models/${model}:generateContent?key=${cfg.key()}`;
    headers = { 'Content-Type': 'application/json' };
    const contents = body.messages.map((m) => ({
      role: m.role.toLowerCase() === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));
    payload = { contents, generationConfig: { temperature, maxOutputTokens: maxTokens } };
  } else if (provider === 'anthropic') {
    url = `${cfg.base()}/v1/messages`;
    headers = { 'Content-Type': 'application/json', 'x-api-key': cfg.key(), 'anthropic-version': '2023-06-01' };
    const messages = [];
    let system = null;
    for (const m of body.messages) {
      if (m.role.toLowerCase() === 'system') {
        system = m.content;
        continue;
      }
      messages.push({ role: m.role.toLowerCase() === 'assistant' ? 'assistant' : 'user', content: m.content });
    }
    payload = { model, messages, max_tokens: maxTokens, temperature };
    if (system) payload.system = system;
  }

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Provider error ${res.status}: ${text}`);
    }
    return normalizeResponse(provider, await res.json(), model);
  } catch (err) {
    if (err.name === 'AbortError') throw new Error('Provider error: CHAT_TIMEOUT_MS exceeded');
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/chat', async (req, res) => {
  const body = req.body || {};
  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return res.status(400).json({ error: 'Messages must not be empty' });
  }

  const provider = resolveProvider(body.provider);

  try {
    requireKey(provider);
  } catch (err) {
    if (err instanceof ProviderNotConfiguredError || err instanceof UnsupportedProviderError) {
      return res.status(400).json({ error: err.message });
    }
    throw err;
  }

  if (ragEnabled()) {
    const userMsg = [...body.messages].reverse().find((m) => m.role === 'user');
    if (userMsg) {
      try {
        const documents = await retrieveContext(userMsg.content || '');
        if (documents.length) {
          const context = 'Use the following context to answer the user\'s question:\n\n'
            + documents.map((d) => `- ${d}`).join('\n');
          body.messages = [{ role: 'system', content: context }, ...body.messages];
        }
      } catch (err) {
        console.error(`RAG retrieval failed: ${err.message}`);
      }
    }
  }

  try {
    const result = await completeChat(provider, body);
    result.provider = provider;
    return res.json(result);
  } catch (err) {
    const fallback = fallbackProvider();
    if (fallback) {
      try {
        requireKey(fallback);
        const fbResult = await completeChat(fallback, body);
        fbResult.provider = fallback;
        return res.json(fbResult);
      } catch (_) { /* fallback unavailable -> 502 */ }
    }
    return res.status(502).json({ error: err.message });
  }
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) {
  app.listen(PORT, () => console.log(`ChatAI server on :${PORT}`));
}

module.exports = app;
