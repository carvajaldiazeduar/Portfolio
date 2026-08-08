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

function clean(value) {
  return String(value == null ? '' : value).trim();
}

function validateContact(name, phone, email) {
  const errors = {};
  const n = clean(name);
  const p = clean(phone);
  const e = clean(email);
  if (!n) {
    errors.name = 'Name is required';
  } else if (n.length < 2 || n.length > 100 || !/^[A-Za-zÀ-ÿ' .-]+$/.test(n)) {
    errors.name = 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)';
  }
  if (!p) {
    errors.phone = 'Phone is required';
  } else if (!/^[0-9 +().-]{7,20}$/.test(p)) {
    errors.phone = 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)';
  }
  if (!e) {
    errors.email = 'Email is required';
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e)) {
    errors.email = 'Invalid email format';
  }
  return errors;
}

app.post('/api/contacts', async (req, res) => {
  const { name, phone, email } = req.body;
  const errors = validateContact(name, phone, email);
  if (Object.keys(errors).length > 0) return res.status(400).json({ errors });
  const contact = await db.create('contacts', { name: clean(name), phone: clean(phone), email: clean(email) });
  cache.del('contacts:all');
  res.status(201).json(contact);
});

app.put('/api/contacts/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const { name, phone, email } = req.body;
  const errors = validateContact(name, phone, email);
  if (Object.keys(errors).length > 0) return res.status(400).json({ errors });
  const contact = await db.update('contacts', id, { name: clean(name), phone: clean(phone), email: clean(email) });
  if (!contact) return res.status(404).json({ error: 'Not found' });
  cache.del('contacts:all');
  res.json(contact);
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
module.exports.validateContact = validateContact;
module.exports.resetContacts = async () => { await db.clear('contacts'); };
