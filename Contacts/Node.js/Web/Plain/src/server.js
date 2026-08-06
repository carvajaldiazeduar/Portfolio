const express = require('express');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { createAdapter } = require('./storage/DatabaseFactory');
const { createCache } = require('./cache/CacheFactory');

const db = createAdapter('contacts');
const cache = createCache();

const columns = [
  { name: 'name', type: 'string', required: true },
  { name: 'phone', type: 'string', default: '' },
  { name: 'email', type: 'string', default: '' },
];

(async () => {
  try {
    await db.connect();
    await db.init('contacts', columns);
  } catch (err) {
    console.error('DB init error:', err.message);
  }
})();

app.get('/api/contacts', async (req, res) => {
  const cached = cache.get('contacts:all');
  if (cached) return res.json(cached);
  const contacts = await db.getAll('contacts', { orderBy: 'id', orderDir: 'ASC' });
  cache.set('contacts:all', contacts);
  res.json(contacts);
});

app.post('/api/contacts', async (req, res) => {
  const { name, phone, email } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: 'Name is required' });
  const contact = await db.create('contacts', { name: name.trim(), phone: (phone || '').trim(), email: (email || '').trim() });
  cache.del('contacts:all');
  res.status(201).json(contact);
});

app.get('/api/contacts/search', async (req, res) => {
  const q = (req.query.q || '').toLowerCase();
  const cacheKey = 'contacts:search:' + q;
  const cached = cache.get(cacheKey);
  if (cached) return res.json(cached);
  const results = await db.search('contacts', 'name', q);
  cache.set(cacheKey, results);
  res.json(results);
});

app.delete('/api/contacts/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const info = await db.delete('contacts', id);
  if (info.changes === 0) return res.status(404).json({ error: 'Not found' });
  cache.del('contacts:all');
  res.json({ message: 'Deleted' });
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`Plain server on :${port}`));
}

module.exports = app;
module.exports.resetContacts = async () => { await db.clear('contacts'); };
