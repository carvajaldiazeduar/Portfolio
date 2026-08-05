const { createCache } = require('../cache/CacheFactory');

const cache = createCache();
const DEFAULT_LIMIT = parseInt(process.env.RATE_LIMIT_DEFAULT, 10) || 100;
const DEFAULT_WINDOW = parseInt(process.env.RATE_LIMIT_WINDOW, 10) || 60;

const routeLimits = new Map();

function setRouteLimit(path, limit, windowSec) {
  routeLimits.set(path, { limit, window: windowSec });
}

function getRouteLimit(path) {
  return routeLimits.get(path) || { limit: DEFAULT_LIMIT, window: DEFAULT_WINDOW };
}

function getClientIdentifier(req) {
  return req.ip || req.connection.remoteAddress || 'unknown';
}

async function rateLimitMiddleware(req, res, next) {
  const routeLimit = getRouteLimit(req.path);
  const identifier = getClientIdentifier(req);
  const key = `ratelimit:${req.path}:${identifier}`;

  try {
    const current = await cache.increment(key, routeLimit.window);
    const remaining = Math.max(0, routeLimit.limit - current);

    res.set({
      'X-RateLimit-Limit': routeLimit.limit,
      'X-RateLimit-Remaining': remaining,
      'X-RateLimit-Reset': Math.ceil(Date.now() / 1000) + routeLimit.window,
    });

    if (current > routeLimit.limit) {
      return res.status(429).json({
        error: 'Too Many Requests',
        message: `Rate limit exceeded. Limit: ${routeLimit.limit} requests per ${routeLimit.window}s`,
      });
    }
    next();
  } catch (err) {
    console.error('Rate limit error:', err.message);
    next();
  }
}

module.exports = { rateLimitMiddleware, setRouteLimit, getRouteLimit };