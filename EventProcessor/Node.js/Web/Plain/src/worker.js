const { createQueue } = require('./queue/QueueFactory');
const { getHandler } = require('./handlers');

const queue = createQueue();
const QUEUES = ['image.process', 'email.bulk', 'report.generate', 'default'];

async function startWorker() {
  try {
    await queue.connect();
    console.log('Connected to queue');
    
    for (const queueName of QUEUES) {
      const handler = getHandler(queueName) || defaultHandler;
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