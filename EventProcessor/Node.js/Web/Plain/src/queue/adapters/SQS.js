const QueueAdapter = require('../QueueAdapter');
const { SQSClient, SendMessageCommand, ReceiveMessageCommand, DeleteMessageCommand, ChangeMessageVisibilityCommand } = require('@aws-sdk/client-sqs');

class SQS extends QueueAdapter {
  constructor() {
    super();
    this._client = null;
    this._queueUrls = new Map();
  }

  _getClient() {
    if (!this._client) {
      this._client = new SQSClient({ region: process.env.AWS_REGION || 'us-east-1' });
    }
    return this._client;
  }

  async _getQueueUrl(queue) {
    if (this._queueUrls.has(queue)) return this._queueUrls.get(queue);
    const url = process.env[`SQS_${queue.toUpperCase()}_URL`] || `https://sqs.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com/${process.env.AWS_ACCOUNT_ID}/${queue}`;
    this._queueUrls.set(queue, url);
    return url;
  }

  async connect() {
    // SQS doesn't need explicit connection
    this._getClient();
  }

  async publish(queue, message) {
    const client = this._getClient();
    const queueUrl = await this._getQueueUrl(queue);
    await client.send(new SendMessageCommand({
      QueueUrl: queueUrl,
      MessageBody: JSON.stringify(message),
      MessageAttributes: {
        sentAt: { DataType: 'Number', StringValue: Date.now().toString() },
      },
    }));
  }

  async subscribe(queue, handler, options = {}) {
    const client = this._getClient();
    const queueUrl = await this._getQueueUrl(queue);
    
    const poll = async () => {
      try {
        const result = await client.send(new ReceiveMessageCommand({
          QueueUrl: queueUrl,
          MaxNumberOfMessages: options.maxMessages || 10,
          WaitTimeSeconds: options.waitTime || 20,
          VisibilityTimeout: options.visibilityTimeout || 30,
        }));
        
        if (result.Messages) {
          for (const msg of result.Messages) {
            try {
              const content = JSON.parse(msg.Body);
              await handler(content, msg);
              await client.send(new DeleteMessageCommand({ QueueUrl: queueUrl, ReceiptHandle: msg.ReceiptHandle }));
            } catch (err) {
              console.error('Handler error:', err.message);
              if (options.requeueOnError !== false) {
                await client.send(new ChangeMessageVisibilityCommand({
                  QueueUrl: queueUrl,
                  ReceiptHandle: msg.ReceiptHandle,
                  VisibilityTimeout: 0,
                }));
              }
            }
          }
        }
      } catch (err) {
        console.error('SQS poll error:', err.message);
      }
      setTimeout(poll, 1000);
    };
    
    poll();
  }

  async ack(message) {
    // Handled in subscribe
  }

  async nack(message, requeue = false) {
    // Handled in subscribe
  }

  async close() {
    // No persistent connections to close
  }
}

module.exports = SQS;