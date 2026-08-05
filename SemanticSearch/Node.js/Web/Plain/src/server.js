const express = require('express');
const multer = require('multer');
const path = require('path');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { createVectorStore } = require('./storage/VectorFactory');
const { createCache } = require('./cache/CacheFactory');

const vectorStore = createVectorStore();
const cache = createCache();
const CACHE_TTL = parseInt(process.env.CACHE_TTL || '300');
const VECTOR_DIMENSION = parseInt(process.env.VECTOR_DIMENSION || '1536');

const upload = multer({ dest: 'uploads/' });

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.post('/api/upload', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file provided' });
  const fs = require('fs');
  const content = fs.readFileSync(req.file.path, 'utf-8', { errors: 'replace' });
  const metadata = { filename: req.file.originalname, source: 'upload' };
  await vectorStore.addDocuments([content], [new Array(VECTOR_DIMENSION).fill(0.0)], [metadata]);
  fs.unlinkSync(req.file.path);
  cache.del('search:results');
  res.json({ message: 'Document indexed', filename: req.file.originalname });
});

app.get('/api/search', async (req, res) => {
  const q = req.query.q || '';
  if (!q) return res.status(400).json({ error: "Query parameter 'q' is required" });
  const cached = cache.get(`search:${q}`);
  if (cached) return res.json({ query: q, results: cached });
  const embedding = new Array(VECTOR_DIMENSION).fill(0.0);
  const results = await vectorStore.search(embedding, 5);
  cache.set(`search:${q}`, results, CACHE_TTL);
  res.json({ query: q, results });
});

app.get('/api/collections', async (req, res) => {
  const collections = await vectorStore.listCollections();
  res.json({ collections });
});

app.delete('/api/collections/:name', async (req, res) => {
  await vectorStore.deleteCollection(req.params.name);
  cache.del('search:results');
  res.json({ message: `Collection '${req.params.name}' deleted` });
});

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`SemanticSearch server on :${port}`));
}

module.exports = app;