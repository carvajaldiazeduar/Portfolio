const QueueAdapter = require('../QueueAdapter');
const { Kafka } = require('kafkajs');

class Kafka extends QueueAdapter {
  constructor() {
    super();
    this._kafka = null;
    this._producer = null;
    this._consumers = new Map();
  }

  async connect() {
    const brokers = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
    this._kafka = new Kafka({ clientId: 'event-processor', brokers });
    this._producer = this._kafka.producer();
    await this._producer.connect();
  }

  async publish(topic, message) {
    if (!this._producer) await this.connect();
    await this._producer.send({
      topic,
      messages: [{ value: JSON.stringify(message) }],
    });
  }

  async subscribe(topic, handler, options = {}) {
    if (!this._kafka) await this.connect();
    const consumer = this._kafka.consumer({ groupId: options.groupId || 'event-processor-group' });
    await consumer.connect();
    await consumer.subscribe({ topic, fromBeginning: options.fromBeginning || false });
    
    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const content = JSON.parse(message.value.toString());
          await handler(content, { topic, partition, offset: message.offset });
        } catch (err) {
          console.error('Handler error:', err.message);
          // Kafka doesn't have built-in requeue, implement DLQ pattern
          if (options.dlqTopic) {
            await this.publish(options.dlqTopic, { originalTopic: topic, message: content, error: err.message });
          }
        }
      },
    });
    
    this._consumers.set(topic, consumer);
  }

  async ack(message) {
    // Kafka uses offset commits, handled by consumer group
  }

  async nack(message, requeue = false) {
    // For requeue, would need to seek backwards or use DLQ
  }

  async close() {
    for (const consumer of this._consumers.values()) {
      await consumer.disconnect();
    }
    if (this._producer) await this._producer.disconnect();
  }
}

module.exports = Kafka;