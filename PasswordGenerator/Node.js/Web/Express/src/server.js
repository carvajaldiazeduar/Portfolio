const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { createCache } = require('./cache');

const DB_DRIVER = process.env.DB_DRIVER || 'postgresql';
const DB_HOST = process.env.DB_HOST || 'db';
const DB_PORT = process.env.DB_PORT || '5432';
const DB_NAME = process.env.DB_NAME || 'passwords';
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

const UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const LOWERCASE = 'abcdefghijklmnopqrstuvwxyz';
const DIGITS = '0123456789';
const SYMBOLS = '!@#$%^&*()_+-=[]{}|;:,.<>?';

function generatePassword(length = 16, useUpper = true, useLower = true, useDigits = true, useSymbols = false) {
  if (!Number.isInteger(length) || length <= 0) throw new Error('Length must be a positive integer');
  const categories = [];
  if (useUpper) categories.push(UPPERCASE);
  if (useLower) categories.push(LOWERCASE);
  if (useDigits) categories.push(DIGITS);
  if (useSymbols) categories.push(SYMBOLS);
  if (categories.length === 0) throw new Error('At least one category required');
  let pw = categories.map(c => c[Math.floor(Math.random() * c.length)]);
  const all = categories.join('');
  for (let i = pw.length; i < length; i++) {
    pw.push(all[Math.floor(Math.random() * all.length)]);
  }
  for (let i = pw.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [pw[i], pw[j]] = [pw[j], pw[i]];
  }
  return pw.join('');
}

app.post('/api/generate', async (req, res) => {
  const { length = 16, use_upper = true, use_lower = true, use_digits = true, use_symbols = true } = req.body;
  try {
    const password = generatePassword(length, use_upper, use_lower, use_digits, use_symbols);
    const entry = await prisma.passwordEntry.create({ data: { password, length } });
    await cache.delete('passwords:recent');
    res.json({ password, id: entry.id });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.get('/api/passwords', async (req, res) => {
  const cached = await cache.get('passwords:recent');
  if (cached) return res.json(cached);
  const entries = await prisma.passwordEntry.findMany({ orderBy: { id: 'desc' }, take: 50 });
  await cache.set('passwords:recent', entries, CACHE_TTL);
  res.json(entries);
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

module.exports = app;
module.exports.app = app;
module.exports.generatePassword = generatePassword;
module.exports.UPPERCASE = UPPERCASE;
module.exports.LOWERCASE = LOWERCASE;
module.exports.DIGITS = DIGITS;
module.exports.SYMBOLS = SYMBOLS;
