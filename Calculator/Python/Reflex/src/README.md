# Calculator — Reflex

A web calculator built entirely in Python using [Reflex](https://reflex.dev/).

---

## Requirements

- Python 3.12+ **64-bit** (recommended) or 32-bit with manual stubs
- `pip install reflex`

## Setup (64-bit Python)

```bash
pip install reflex
cd Calculator/Reflex
reflex run
```

Open `http://localhost:3000`

## Setup (32-bit Python)

On 32-bit Python, packages like `granian` lack pre-built wheels. Create a stub:

```bash
mkdir -p <python>/Lib/site-packages/granian
echo "" > <python>/Lib/site-packages/granian/__init__.py
reflex run
```

## Structure

```
Calculator/Reflex/
├── rxconfig.py
├── calculator/
│   ├── __init__.py
│   └── calculator.py
└── README.md
```

## Features

- Addition, subtraction, multiplication, division
- Division by zero handling
- Button-based calculator interface
