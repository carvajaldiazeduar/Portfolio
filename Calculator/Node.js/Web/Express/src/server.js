const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

const allowedOperators = new Set(["add", "subtract", "multiply", "divide"]);

function calculate(a, b, operator) {
  switch (operator) {
    case "add":
      return a + b;
    case "subtract":
      return a - b;
    case "multiply":
      return a * b;
    case "divide":
      if (b === 0) return null;
      return a / b;
    default:
      return null;
  }
}

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.post("/calculate", (req, res) => {
  const { a, b, operator } = req.body;

  if (!allowedOperators.has(operator)) {
    return res.status(400).json({ error: "Invalid operator" });
  }

  const numA = parseFloat(a);
  const numB = parseFloat(b);

  if (isNaN(numA) || isNaN(numB)) {
    return res.status(400).json({ error: "Invalid number input" });
  }

  if (operator === "divide" && numB === 0) {
    return res.status(400).json({ error: "Cannot divide by zero" });
  }

  const result = calculate(numA, numB, operator);

  if (result === null) {
    return res.status(400).json({ error: "Calculation error" });
  }

  res.json({ result });
});

app.get('/swagger', (req, res) => res.redirect('/swagger.html'));

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Calculator server running on http://localhost:${PORT}`);
  });
}

module.exports = app;
