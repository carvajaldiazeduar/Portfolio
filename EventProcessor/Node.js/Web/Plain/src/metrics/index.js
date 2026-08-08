const express = require('express');
const client = require('prom-client');

client.collectDefaultMetrics();

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2.5, 5, 10],
});

const jobsPublishedTotal = new client.Counter({
  name: 'jobs_published_total',
  help: 'Total number of jobs published to the queue',
  labelNames: ['type'],
});

const jobsProcessedTotal = new client.Counter({
  name: 'jobs_processed_total',
  help: 'Total number of jobs processed by the worker',
  labelNames: ['type', 'status'],
});

const jobsProcessingDuration = new client.Histogram({
  name: 'jobs_processing_duration_seconds',
  help: 'Duration of job processing in seconds',
  labelNames: ['type'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10, 30],
});

function instrumentRequest(req, res, next) {
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    const durationSeconds = Number(process.hrtime.bigint() - start) / 1e9;
    const route = (req.route && req.route.path) || req.path;
    httpRequestsTotal.labels(req.method, route, res.statusCode).inc();
    httpRequestDuration.labels(req.method, route, res.statusCode).observe(durationSeconds);
  });
  next();
}

function observeJobPublish(type) {
  jobsPublishedTotal.labels(type).inc();
}

function observeJobProcessing(type) {
  const start = process.hrtime.bigint();
  return {
    success() {
      jobsProcessedTotal.labels(type, 'success').inc();
      jobsProcessingDuration.labels(type).observe(Number(process.hrtime.bigint() - start) / 1e9);
    },
    failure() {
      jobsProcessedTotal.labels(type, 'failed').inc();
      jobsProcessingDuration.labels(type).observe(Number(process.hrtime.bigint() - start) / 1e9);
    },
  };
}

function withJobMetrics(type, handler) {
  return async (jobData, job) => {
    const timer = observeJobProcessing(type);
    try {
      const result = await handler(jobData, job);
      timer.success();
      return result;
    } catch (err) {
      timer.failure();
      throw err;
    }
  };
}

function metricsRouter() {
  const router = express.Router();
  router.get('/metrics', async (req, res) => {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  });
  return router;
}

async function metricsBody() {
  return client.register.metrics();
}

module.exports = {
  instrumentRequest,
  observeJobPublish,
  observeJobProcessing,
  withJobMetrics,
  metricsRouter,
  metricsBody,
};
