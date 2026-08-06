const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { createCache } = require('./cache');

const DB_DRIVER = process.env.DB_DRIVER || 'postgresql';
const DB_HOST = process.env.DB_HOST || 'db';
const DB_PORT = process.env.DB_PORT || '5432';
const DB_NAME = process.env.DB_NAME || 'inboxes';
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

const toDto = (msg) => ({
  id: msg.id,
  from: msg.sender,
  subject: msg.subject,
  body: msg.body,
  read: msg.read,
  created_at: msg.createdAt ? msg.createdAt.toISOString() : null,
});

app.use(express.json());
app.use(express.static('public'));

app.get('/api/messages', async (req, res) => {
  const cached = await cache.get('messages:all');
  if (cached) return res.json(cached);
  const msgs = await prisma.message.findMany({ orderBy: { id: 'asc' } });
  const data = msgs.map(toDto);
  await cache.set('messages:all', data, CACHE_TTL);
  res.json(data);
});

app.post('/api/messages', async (req, res) => {
  const from = req.body.from || req.body.sender;
  const { subject, body } = req.body;
  if (!from || !subject) {
    return res.status(400).json({ error: 'from and subject are required' });
  }
  const msg = await prisma.message.create({
    data: { sender: from, subject, body: body || '' }
  });
  await cache.delete('messages:all');
  res.status(201).json(toDto(msg));
});

app.get('/api/messages/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const cached = await cache.get('message:' + id);
  if (cached) return res.json(cached);
  try {
    const msg = await prisma.message.update({
      where: { id },
      data: { read: true }
    });
    const data = toDto(msg);
    await cache.set('message:' + id, data, CACHE_TTL);
    await cache.delete('messages:all');
    res.json(data);
  } catch (e) {
    res.status(404).json({ error: 'not found' });
  }
});

app.delete('/api/messages/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  try {
    await prisma.message.delete({ where: { id } });
    await cache.delete('messages:all');
    await cache.delete('message:' + id);
    res.status(204).send();
  } catch (e) {
    res.status(404).json({ error: 'not found' });
  }
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

module.exports = app;
module.exports.resetMessages = async () => {
  await prisma.message.deleteMany();
  await cache.delete('messages:all');
};
