class QueueAdapter {
  async connect() { throw new Error('Not implemented'); }
  async publish(queue, message) { throw new Error('Not implemented'); }
  async subscribe(queue, handler, options = {}) { throw new Error('Not implemented'); }
  async ack(message) { throw new Error('Not implemented'); }
  async nack(message, requeue = false) { throw new Error('Not implemented'); }
  async close() { throw new Error('Not implemented'); }
}
module.exports = QueueAdapter;