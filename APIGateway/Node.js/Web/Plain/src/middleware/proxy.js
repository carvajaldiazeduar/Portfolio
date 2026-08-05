const { createProxyMiddleware } = require('http-proxy-middleware');

const serviceRoutes = new Map();

function registerService(prefix, target, options = {}) {
  serviceRoutes.set(prefix, { target, options });
}

function getServiceForPath(path) {
  for (const [prefix, config] of serviceRoutes.entries()) {
    if (path.startsWith(prefix)) {
      return { prefix, ...config };
    }
  }
  return null;
}

function proxyMiddleware(req, res, next) {
  const service = getServiceForPath(req.path);
  if (!service) {
    return res.status(404).json({ error: 'No service registered for this path' });
  }

  const proxy = createProxyMiddleware({
    target: service.target,
    changeOrigin: true,
    pathRewrite: { [`^${service.prefix}`]: '' },
    ...service.options,
    onError: (err, req, res) => {
      console.error('Proxy error:', err.message);
      if (!res.headersSent) {
        res.status(502).json({ error: 'Bad Gateway', message: 'Upstream service unavailable' });
      }
    },
    onProxyReq: (proxyReq, req) => {
      if (req.user) {
        proxyReq.setHeader('X-User-Id', req.user.id || '');
        proxyReq.setHeader('X-User-Roles', (req.user.roles || []).join(','));
      }
    },
  });

  return proxy(req, res, next);
}

module.exports = { proxyMiddleware, registerService, getServiceForPath };