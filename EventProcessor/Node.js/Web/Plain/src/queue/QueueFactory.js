const RabbitMQAdapter = require('./adapters/RabbitMQ');
const KafkaAdapter = require('./adapters/Kafka');
const SQSAdapter = require('./adapters/SQS');
const RedisQueueAdapter = require('./adapters/RedisQueue');

function createQueue() {
  const driver = process.env.QUEUE_DRIVER || 'redis';
  switch (driver) {
    case 'rabbitmq':
      return new RabbitMQAdapter();
    case 'kafka':
      return new KafkaAdapter();
    case 'sqs':
      return new SQSAdapter();
    case 'redis':
    default:
      return new RedisQueueAdapter();
  }
}

module.exports = { createQueue };