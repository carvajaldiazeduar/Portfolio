const request = require('supertest');
const app = require('../server');
const { createQueue } = require('../queue/QueueFactory');

jest.mock('../queue/QueueFactory', () => ({
  createQueue: () => ({
    connect: jest.fn().mockResolvedValue(undefined),
    publish: jest.fn().mockResolvedValue(undefined),
    subscribe: jest.fn().mockResolvedValue(undefined),
    close: jest.fn().mockResolvedValue(undefined),
  }),
}));

describe('Event Processor API', () => {
  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('GET /api/queues returns available queues', async () => {
    const res = await request(app).get('/api/queues');
    expect(res.status).toBe(200);
    expect(res.body.queues).toContain('image.process');
    expect(res.body.queues).toContain('email.bulk');
    expect(res.body.queues).toContain('report.generate');
  });

  test('POST /api/jobs with valid data returns 202', async () => {
    const res = await request(app)
      .post('/api/jobs')
      .send({ type: 'image.process', data: { imageUrl: 'test.jpg' } });
    expect(res.status).toBe(202);
    expect(res.body.message).toBe('Job queued');
  });

  test('POST /api/jobs without type returns 400', async () => {
    const res = await request(app)
      .post('/api/jobs')
      .send({ data: { imageUrl: 'test.jpg' } });
    expect(res.status).toBe(400);
  });

  test('POST /api/jobs with unknown type returns 400', async () => {
    const res = await request(app)
      .post('/api/jobs')
      .send({ type: 'unknown.type', data: {} });
    expect(res.status).toBe(400);
  });

  test('POST /api/jobs/batch queues multiple jobs', async () => {
    const res = await request(app)
      .post('/api/jobs/batch')
      .send({
        jobs: [
          { type: 'image.process', data: { imageUrl: '1.jpg' } },
          { type: 'email.bulk', data: { recipients: ['a@test.com'], subject: 'Test' } },
        ],
      });
    expect(res.status).toBe(202);
    expect(res.body.message).toContain('2 jobs queued');
  });
});