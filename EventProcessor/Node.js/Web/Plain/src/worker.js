const http = require('http');
const { createQueue } = require('./queue/QueueFactory');
const { getHandler } = require('./handlers');
const { withJobMetrics, metricsBody } = require('./metrics');

const queue = createQueue();
const QUEUES = ['image.process', 'email.bulk', 'report.generate', 'default'];

function startMetricsServer() {
  const port = process.env.WORKER_METRICS_PORT || 3001;
  const server = http.createServer(async (req, res) => {
    if (req.url === '/metrics') {
      res.setHeader('Content-Type', 'text/plain');
      res.end(await metricsBody());
    } else {
      res.statusCode = 404;
      res.end('Not found');
    }
  });
  server.listen(port, () => console.log(`Worker metrics available on :${port}/metrics`));
}

async function startWorker() {
  try {
    await queue.connect();
    console.log('Connected to queue');
    
    for (const queueName of QUEUES) {
      const handler = withJobMetrics(queueName, getHandler(queueName) || defaultHandler);
      await queue.subscribe(queueName, handler, { concurrency: 5 });
      console.log(`Subscribed to queue: ${queueName}`);
    }
    
    console.log('Worker started, waiting for jobs...');
  } catch (err) {
    console.error('Worker error:', err.message);
    process.exit(1);
  }
}

async function defaultHandler(jobData, job) {
  console.log(`Processing job: ${JSON.stringify(jobData)}`);
  await new Promise(resolve => setTimeout(resolve, 500));
  return { success: true, processed: jobData };
}

process.on('SIGINT', async () => {
  console.log('Shutting down worker...');
  await queue.close();
  process.exit(0);
});

startWorker();
startMetricsServer();
