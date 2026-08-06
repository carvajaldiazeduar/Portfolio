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

app.post('/api/contacts', async (req, res) => {
  const { name, phone, email } = req.body;
  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'Name is required' });
  }
  const contact = await prisma.contact.create({
    data: { name: name.trim(), phone: (phone || '').trim(), email: (email || '').trim() }
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
module.exports.resetContacts = async () => {
  await prisma.contact.deleteMany();
};
