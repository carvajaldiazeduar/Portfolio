const QueueAdapter = require('../QueueAdapter');
const { Queue, Worker } = require('bullmq');
const IORedis = require('ioredis');

class RedisQueue extends QueueAdapter {
  constructor() {
    super();
    this._connection = null;
    this._queues = new Map();
    this._workers = new Map();
    try {
      this._connection = new IORedis(process.env.REDIS_HOST || 'localhost:6379', { maxRetriesPerRequest: null });
    } catch { this._connection = null; }
  }

  _getQueue(name) {
    if (!this._queues.has(name)) {
      this._queues.set(name, new Queue(name, { connection: this._connection }));
    }
    return this._queues.get(name);
  }

  async connect() {
    if (this._connection) {
      await this._connection.ping();
    }
  }

  async publish(queue, message) {
    const q = this._getQueue(queue);
    await q.add('job', message, { attempts: 3, backoff: { type: 'exponential', delay: 1000 } });
  }

  async subscribe(queue, handler, options = {}) {
    const worker = new Worker(queue, async (job) => {
      try {
        await handler(job.data, job);
      } catch (err) {
        throw err;
      }
    }, {
      connection: this._connection,
      concurrency: options.concurrency || 5,
      ...options,
    });

    worker.on('failed', (job, err) => {
      console.error(`Job ${job.id} failed:`, err.message);
    });

    this._workers.set(queue, worker);
  }

  async ack(message) {
    // BullMQ handles ack automatically on successful completion
  }

  async nack(message, requeue = false) {
    // BullMQ handles retry via attempts/backoff config
  }

  async close() {
    for (const worker of this._workers.values()) {
      await worker.close();
    }
    for (const queue of this._queues.values()) {
      await queue.close();
    }
    if (this._connection) {
      await this._connection.quit();
    }
  }
}

module.exports = RedisQueue;