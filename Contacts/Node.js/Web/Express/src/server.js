const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { createCache } = require('./cache');

const DB_DRIVER = process.env.DB_DRIVER || 'postgresql';
const DB_HOST = process.env.DB_HOST || 'db';
const DB_PORT = process.env.DB_PORT || '5432';
const DB_NAME = process.env.DB_NAME || 'contacts';
const DB_USER = process.env.DB_USER || 'postgres';
const DB_PASSWORD = process.env.DB_PASSWORD || 'postgres';
const DB_FILE = process.env.DB_FILE || '';
if (!process.env.DATABASE_URL) {
  if (DB_DRIVER === 'sqlite') {
    process.env.DATABASE_URL = `sqlite:///${DB_FILE || 'db.sqlite3'}`;
  } else if (DB_DRIVER === 'mysql') {
    process.env.DATABASE_URL = `mysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}`;
  } else if (DB_DRIVER === 'mongodb') {
    process.env.DATABASE_URL = `mongodb://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}`;
  } else if (DB_DRIVER === 'sqlserver') {
    process.env.DATABASE_URL = `sqlserver://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT};database=${DB_NAME}`;
  } else {
    process.env.DATABASE_URL = `postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}`;
  }
}

const app = express();
const prisma = new PrismaClient();
const cache = createCache();
const CACHE_TTL = parseInt(process.env.CACHE_TTL || '300');

app.use(express.json());
app.use(express.static('public'));

app.get('/api/contacts', async (req, res) => {
  const cached = await cache.get('contacts:all');
  if (cached) return res.json(cached);
  const contacts = await prisma.contact.findMany({ orderBy: { id: 'asc' } });
  await cache.set('contacts:all', contacts, CACHE_TTL);
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
  if (Object.keys(errors).length > 0) {
    return res.status(400).json({ errors });
  }
  const contact = await prisma.contact.create({
    data: { name: clean(name), phone: clean(phone), email: clean(email) }
  });
  await cache.delete('contacts:all');
  res.status(201).json(contact);
});

app.get('/api/contacts/search', async (req, res) => {
  const q = (req.query.q || '').toLowerCase();
  const cached = await cache.get('contacts:search:' + q);
  if (cached) return res.json(cached);
  const results = await prisma.contact.findMany({
    where: { name: { contains: q, mode: 'insensitive' } }
  });
  await cache.set('contacts:search:' + q, results, CACHE_TTL);
  res.json(results);
});

app.delete('/api/contacts/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  try {
    await prisma.contact.delete({ where: { id } });
    await cache.delete('contacts:all');
    res.json({ result: 'deleted' });
  } catch (e) {
    res.status(404).json({ error: 'Not found' });
  }
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

module.exports = app;
module.exports.validateContact = validateContact;
module.exports.resetContacts = async () => {
  await prisma.contact.deleteMany();
};

if (require.main === module) {
  app.listen(process.env.PORT || 3000, () => console.log('Server running'));
}
