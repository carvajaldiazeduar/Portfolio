const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

const DEFAULT_MODEL = process.env.CHAT_MODEL || 'gpt-4o-mini';
const DEFAULT_TEMPERATURE = parseFloat(process.env.CHAT_TEMPERATURE || '0.7');
const DEFAULT_MAX_TOKENS = parseInt(process.env.CHAT_MAX_TOKENS || '1024');
const API_KEY = process.env.OPENAI_API_KEY || '';
const BASE_URL = (process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1').replace(/\/+$/, '');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

async function completeChat(messages, model, temperature, maxTokens) {
  const res = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(API_KEY ? { Authorization: `Bearer ${API_KEY}` } : {}),
    },
    body: JSON.stringify({ model, messages, temperature, max_tokens: maxTokens }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Provider error ${res.status}: ${body}`);
  }
  return res.json();
}

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/chat', async (req, res) => {
  const messages = req.body && req.body.messages;
  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: 'Messages must not be empty' });
  }
  const model = req.body.model || DEFAULT_MODEL;
  const temperature = req.body.temperature != null ? req.body.temperature : DEFAULT_TEMPERATURE;
  const maxTokens = req.body.max_tokens != null ? req.body.max_tokens : DEFAULT_MAX_TOKENS;
  try {
    const result = await completeChat(messages, model, temperature, maxTokens);
    const choices = (result.choices || []).map((c) => ({
      role: (c.message && c.message.role) || 'assistant',
      content: (c.message && c.message.content) || '',
    }));
    const usage = result.usage || {};
    res.json({
      id: result.id || '',
      model: result.model || model,
      choices,
      usage: {
        prompt_tokens: usage.prompt_tokens || 0,
        completion_tokens: usage.completion_tokens || 0,
        total_tokens: usage.total_tokens || 0,
      },
    });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) {
  app.listen(PORT, () => console.log(`ChatAI server on :${PORT}`));
}

module.exports = app;
