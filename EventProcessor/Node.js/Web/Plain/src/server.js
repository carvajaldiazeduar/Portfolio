const express = require('express');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { createQueue } = require('./queue/QueueFactory');
const { getHandler, HANDLERS } = require('./handlers');
const { instrumentRequest, observeJobPublish, metricsRouter } = require('./metrics');

const queue = createQueue();

app.use(instrumentRequest);
app.use(metricsRouter());

(async () => {
  try {
    await queue.connect();
    console.log('Connected to queue');
  } catch (err) {
    console.error('Queue connection error:', err.message);
  }
})();

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/queues', (req, res) => {
  res.json({ queues: Object.keys(HANDLERS) });
});

app.post('/api/jobs', async (req, res) => {
  const { type, data } = req.body;
  if (!type || !data) {
    return res.status(400).json({ error: 'Type and data are required' });
  }
  
  if (!getHandler(type)) {
    return res.status(400).json({ error: `Unknown job type: ${type}` });
  }
  
  try {
    observeJobPublish(type);
    await queue.publish(type, data);
    res.status(202).json({ message: 'Job queued', type, status: 'pending' });
  } catch (err) {
    console.error('Publish error:', err.message);
    res.status(500).json({ error: 'Failed to queue job' });
  }
});

app.post('/api/jobs/batch', async (req, res) => {
  const { jobs } = req.body;
  if (!Array.isArray(jobs) || jobs.length === 0) {
    return res.status(400).json({ error: 'Jobs array is required' });
  }
  
  try {
    await Promise.all(jobs.map(({ type, data }) => {
      observeJobPublish(type);
      return queue.publish(type, data);
    }));
    res.status(202).json({ message: `${jobs.length} jobs queued`, status: 'pending' });
  } catch (err) {
    console.error('Batch publish error:', err.message);
    res.status(500).json({ error: 'Failed to queue jobs' });
  }
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`Event Processor API running on :${port}`));
}

module.exports = app;