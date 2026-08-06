const express = require('express');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { createAdapter } = require('./storage/DatabaseFactory');
const { createCache } = require('./cache/CacheFactory');

const db = createAdapter('inboxes');
const cache = createCache();

const columns = [
  { name: 'sender', type: 'string', default: '' },
  { name: 'subject', type: 'string', required: true },
  { name: 'body', type: 'text', default: '' },
  { name: 'read', type: 'boolean', default: 0 },
  { name: 'created_at', type: 'datetime', default: 'now' },
];

(async () => {
  try {
    await db.connect();
    await db.init('messages', columns);
  } catch (err) {
    console.error('DB init error:', err.message);
  }
})();

app.get('/api/messages', async (req, res) => {
  const cached = cache.get('messages:all');
  if (cached) return res.json(cached);
  const messages = await db.getAll('messages', { orderBy: 'id', orderDir: 'ASC' });
  cache.set('messages:all', messages);
  res.json(messages);
});

app.post('/api/messages', async (req, res) => {
  const { sender, subject, body } = req.body;
  if (!subject || !subject.trim()) return res.status(400).json({ error: 'Subject is required' });
  const msg = await db.create('messages', { sender: (sender || '').trim(), subject: subject.trim(), body: (body || '').trim() });
  cache.del('messages:all');
  res.status(201).json(msg);
});

app.get('/api/messages/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const cached = cache.get('message:' + id);
  if (cached) return res.json(cached);
  const msg = await db.getById('messages', id);
  if (!msg) return res.status(404).json({ error: 'Not found' });
  await db.update('messages', id, { read: 1 });
  msg.read = true;
  cache.set('message:' + id, msg);
  cache.del('messages:all');
  res.json(msg);
});

app.delete('/api/messages/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const info = await db.delete('messages', id);
  if (info.changes === 0) return res.status(404).json({ error: 'Not found' });
  cache.del('messages:all');
  cache.del('message:' + id);
  res.status(204).send();
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) { const port = process.env.PORT || 3000; app.listen(port, () => console.log(`Plain on :${port}`)); }
module.exports = app;
module.exports.resetMessages = async () => { await db.clear('messages'); };
