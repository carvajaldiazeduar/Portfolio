const express = require('express');
const path = require('path');
const { convert, listCategories, CATEGORY_UNITS } = require('../../../Cli/conversor');

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/categories', (req, res) => {
  const result = {};
  for (const cat of listCategories()) {
    result[cat] = CATEGORY_UNITS[cat];
  }
  res.json(result);
});

app.post('/api/convert', (req, res) => {
  const { value, from, to } = req.body;
  if (value === undefined || !from || !to) {
    return res.status(400).json({ error: 'Missing fields: value, from, to' });
  }
  try {
    const result = convert(Number(value), from, to);
    res.json({ result, from, to, value: Number(value) });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
}

module.exports = app;
