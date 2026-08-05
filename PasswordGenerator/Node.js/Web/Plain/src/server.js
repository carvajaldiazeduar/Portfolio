const express = require('express');
const crypto = require('crypto');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { createAdapter } = require('./storage/DatabaseFactory');
const { createCache } = require('./cache/CacheFactory');

const db = createAdapter('passwords');
const cache = createCache();

const columns = [
  { name: 'password', type: 'string', required: true },
  { name: 'length', type: 'integer', default: 16 },
  { name: 'created_at', type: 'datetime', default: 'now' },
];

(async () => {
  try {
    await db.connect();
    await db.init('password_entries', columns);
  } catch (err) {
    console.error('DB init error:', err.message);
  }
})();

const UPPER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const LOWER = 'abcdefghijklmnopqrstuvwxyz';
const DIGITS = '0123456789';
const SYMBOLS = '!@#$%^&*()_+-=[]{}|;:,.<>?';

function generatePassword(length, useUpper, useLower, useDigits, useSymbols) {
  let chars = '';
  if (useUpper) chars += UPPER;
  if (useLower) chars += LOWER;
  if (useDigits) chars += DIGITS;
  if (useSymbols) chars += SYMBOLS;
  if (!chars) throw new Error('Select at least one character type');
  return Array.from(crypto.randomFillSync(new Uint8Array(length)), b => chars[b % chars.length]).join('');
}

app.post('/api/generate', async (req, res) => {
  const { length = 16, use_upper = true, use_lower = true, use_digits = true, use_symbols = false } = req.body;
  try {
    const password = generatePassword(length, use_upper, use_lower, use_digits, use_symbols);
    await db.create('password_entries', { password, length });
    cache.del('passwords:recent');
    res.json({ password });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.get('/api/passwords', async (req, res) => {
  const cached = cache.get('passwords:recent');
  if (cached) return res.json(cached);
  const entries = await db.getAll('password_entries', { orderBy: 'id', orderDir: 'DESC', limit: 50 });
  cache.set('passwords:recent', entries);
  res.json(entries);
});

if (require.main === module) { const port = process.env.PORT || 3000; app.listen(port, () => console.log(`Plain on :${port}`)); }
module.exports = app;
module.exports.resetEntries = async () => { await db.clear('password_entries'); };
