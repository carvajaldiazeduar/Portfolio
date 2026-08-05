const QueueAdapter = require('../QueueAdapter');
const amqp = require('amqplib');

class RabbitMQ extends QueueAdapter {
  constructor() {
    super();
    this._connection = null;
    this._channel = null;
    this._consumers = new Map();
  }

  async connect() {
    const url = process.env.RABBITMQ_URL || 'amqp://localhost:5672';
    this._connection = await amqp.connect(url);
    this._channel = await this._connection.createChannel();
    this._connection.on('error', (err) => console.error('RabbitMQ connection error:', err.message));
    this._connection.on('close', () => console.log('RabbitMQ connection closed'));
  }

  async publish(queue, message) {
    if (!this._channel) await this.connect();
    await this._channel.assertQueue(queue, { durable: true });
    this._channel.sendToQueue(queue, Buffer.from(JSON.stringify(message)), { persistent: true });
  }

  async subscribe(queue, handler, options = {}) {
    if (!this._channel) await this.connect();
    await this._channel.assertQueue(queue, { durable: true });
    await this._channel.prefetch(options.prefetch || 10);
    
    const consumer = await this._channel.consume(queue, async (msg) => {
      if (!msg) return;
      try {
        const content = JSON.parse(msg.content.toString());
        await handler(content, msg);
        this._channel.ack(msg);
      } catch (err) {
        console.error('Handler error:', err.message);
        const requeue = options.requeueOnError !== false;
        this._channel.nack(msg, false, requeue);
      }
    });
    
    this._consumers.set(queue, consumer);
  }

  async ack(message) {
    if (this._channel && message) this._channel.ack(message);
  }

  async nack(message, requeue = false) {
    if (this._channel && message) this._channel.nack(message, false, requeue);
  }

  async close() {
    for (const consumer of this._consumers.values()) {
      await this._channel.cancel(consumer.consumerTag);
    }
    if (this._channel) await this._channel.close();
    if (this._connection) await this._connection.close();
  }
}

module.exports = RabbitMQ;