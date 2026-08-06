const express = require('express');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { createAdapter } = require('./storage/DatabaseFactory');
const { createCache } = require('./cache/CacheFactory');

const db = createAdapter('tasks');
const cache = createCache();

const columns = [
  { name: 'title', type: 'string', required: true },
  { name: 'description', type: 'text', default: '' },
  { name: 'completed', type: 'boolean', default: 0 },
  { name: 'created_at', type: 'datetime', default: 'now' },
];

(async () => {
  try {
    await db.connect();
    await db.init('tasks', columns);
  } catch (err) {
    console.error('DB init error:', err.message);
  }
})();

app.get('/api/tasks', async (req, res) => {
  const cached = cache.get('tasks:all');
  if (cached) return res.json(cached);
  const tasks = await db.getAll('tasks', { orderBy: 'id', orderDir: 'ASC' });
  cache.set('tasks:all', tasks);
  res.json(tasks);
});

app.post('/api/tasks', async (req, res) => {
  const { title, description } = req.body;
  if (!title || !title.trim()) return res.status(400).json({ error: 'Title is required' });
  const task = await db.create('tasks', { title: title.trim(), description: (description || '').trim() });
  cache.del('tasks:all');
  res.status(201).json(task);
});

app.put('/api/tasks/:id/complete', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const info = await db.update('tasks', id, { completed: 1 });
  if (!info) return res.status(404).json({ error: 'Task not found' });
  cache.del('tasks:all');
  res.json({ success: true });
});

app.delete('/api/tasks/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const info = await db.delete('tasks', id);
  if (info.changes === 0) return res.status(404).json({ error: 'Task not found' });
  cache.del('tasks:all');
  res.json({ success: true });
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) { const port = process.env.PORT || 3000; app.listen(port, () => console.log(`Plain on :${port}`)); }
module.exports = app;
module.exports.resetTasks = async () => { await db.clear('tasks'); };
