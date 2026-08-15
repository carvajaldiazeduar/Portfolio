const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { createCache } = require('./cache');

const DB_DRIVER = process.env.DB_DRIVER || 'postgresql';
const DB_HOST = process.env.DB_HOST || 'db';
const DB_PORT = process.env.DB_PORT || '5432';
const DB_NAME = process.env.DB_NAME || 'taskslist';
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

app.get('/api/tasks', async (req, res) => {
  const cached = await cache.get('tasks:all');
  if (cached) return res.json(cached);
  const tasks = await prisma.task.findMany({ orderBy: { id: 'asc' } });
  await cache.set('tasks:all', tasks, CACHE_TTL);
  res.json(tasks);
});

app.post('/api/tasks', async (req, res) => {
  const { title, description } = req.body;
  if (!title || !title.trim()) {
    return res.status(400).json({ error: 'Title is required' });
  }
  const task = await prisma.task.create({
    data: { title: title.trim(), description: (description || '').trim() }
  });
  await cache.delete('tasks:all');
  res.status(201).json(task);
});

app.put('/api/tasks/:id/complete', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  try {
    const task = await prisma.task.update({ where: { id }, data: { completed: true } });
    await cache.delete('tasks:all');
    res.json(task);
  } catch (e) {
    res.status(404).json({ error: 'Task not found' });
  }
});

app.delete('/api/tasks/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  try {
    await prisma.task.delete({ where: { id } });
    await cache.delete('tasks:all');
    res.json({ result: 'deleted' });
  } catch (e) {
    res.status(404).json({ error: 'Task not found' });
  }
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

module.exports = app;
module.exports.resetTasks = async () => {
  await prisma.task.deleteMany();
  await cache.delete('tasks:all');
};

if (require.main === module) {
  app.listen(process.env.PORT || 3000, () => console.log('Server running'));
}
