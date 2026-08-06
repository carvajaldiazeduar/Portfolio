const express = require('express');
const multer = require('multer');
const path = require('path');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { createDatabaseAdapter } = require('./storage/DatabaseFactory');
const { createCache } = require('./cache/CacheFactory');
const { PipelineService } = require('./services/PipelineService');
const { getHandler, HANDLERS } = require('./handlers');

const db = createDatabaseAdapter();
const cache = createCache();
const pipeline = new PipelineService();

const upload = multer({ storage: multer.memoryStorage() });

const AWS_ENDPOINT_URL = process.env.AWS_ENDPOINT_URL || 'http://localhost:4566';
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/pipeline/status', async (req, res) => {
  res.json({
    service: 'pipeline',
    awsEndpoint: AWS_ENDPOINT_URL,
    region: AWS_REGION,
    dbDriver: process.env.DB_DRIVER || 'postgresql',
    uptime: process.uptime(),
  });
});

app.post('/api/pipeline/upload', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const fileName = req.file.originalname;
  const fileType = path.extname(fileName).slice(1).toLowerCase();
  const fileSize = req.file.size;

  try {
    const result = await pipeline.ingestFile({
      fileName,
      fileType,
      fileSize,
      buffer: req.file.buffer,
    });
    res.status(201).json(result);
  } catch (err) {
    console.error('Pipeline error:', err.message);
    res.status(500).json({ error: 'Pipeline processing failed', details: err.message });
  }
});

app.get('/api/pipeline/files', async (req, res) => {
  try {
    const files = await pipeline.listFiles();
    res.json({ files, count: files.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/pipeline/files/:key', async (req, res) => {
  try {
    const metadata = await pipeline.getFileMetadata(req.params.key);
    if (!metadata) {
      return res.status(404).json({ error: 'File not found' });
    }
    res.json(metadata);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/pipeline/metrics', async (req, res) => {
  try {
    const metrics = await pipeline.getMetrics();
    res.json({ metrics, count: metrics.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/handlers', (req, res) => {
  res.json({ handlers: Object.keys(HANDLERS) });
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) {
  const port = process.env.PORT || 8080;
  app.listen(port, () => console.log(`Pipeline API running on :${port}`));
}

module.exports = app;