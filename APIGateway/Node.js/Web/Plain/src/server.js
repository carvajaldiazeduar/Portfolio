const express = require('express');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const { authMiddleware } = require('./middleware/auth');
const { rateLimitMiddleware, setRouteLimit } = require('./middleware/rateLimit');
const { proxyMiddleware, registerService } = require('./middleware/proxy');

registerService('/api/users', process.env.USERS_SERVICE_URL || 'http://localhost:3001');
registerService('/api/orders', process.env.ORDERS_SERVICE_URL || 'http://localhost:3002');
registerService('/api/products', process.env.PRODUCTS_SERVICE_URL || 'http://localhost:3003');

setRouteLimit('/api/users', 50, 60);
setRouteLimit('/api/orders', 30, 60);
setRouteLimit('/api/products', 100, 60);

app.post('/auth/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }
  if (username === 'admin' && password === 'admin') {
    const { generateToken } = require('./middleware/auth');
    const token = generateToken({ id: 1, username: 'admin', roles: ['admin'] });
    return res.json({ token, expiresIn: '1h' });
  }
  if (username === 'user' && password === 'user') {
    const { generateToken } = require('./middleware/auth');
    const token = generateToken({ id: 2, username: 'user', roles: ['user'] });
    return res.json({ token, expiresIn: '1h' });
  }
  res.status(401).json({ error: 'Invalid credentials' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

app.use(rateLimitMiddleware);
app.use(authMiddleware);
app.use(proxyMiddleware);

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`API Gateway running on :${port}`));
}

module.exports = app;