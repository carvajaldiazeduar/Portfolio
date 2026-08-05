import { useState } from 'react'

const operations = [
  { value: 'add', label: 'Add' },
  { value: 'subtract', label: 'Subtract' },
  { value: 'multiply', label: 'Multiply' },
  { value: 'divide', label: 'Divide' },
]

function compute(num1, num2, op) {
  const a = parseFloat(num1)
  const b = parseFloat(num2)

  if (isNaN(a) || isNaN(b)) {
    return { error: 'Please enter valid numbers.' }
  }

  switch (op) {
    case 'add':
      return { result: a + b }
    case 'subtract':
      return { result: a - b }
    case 'multiply':
      return { result: a * b }
    case 'divide':
      if (b === 0) {
        return { error: 'Cannot divide by zero.' }
      }
      return { result: a / b }
    default:
      return { error: 'Invalid operation.' }
  }
}

function App() {
  const [num1, setNum1] = useState('')
  const [num2, setNum2] = useState('')
  const [operation, setOperation] = useState('add')
  const [result, setResult] = useState(null)
  const [error, setError] = useState(null)

  function handleCalculate() {
    const output = compute(num1, num2, operation)
    setResult(output.result ?? null)
    setError(output.error ?? null)
  }

  return (
    <div className="calculator">
      <h1>Calculator</h1>

      <div className="inputs">
        <input
          type="number"
          value={num1}
          onChange={(e) => setNum1(e.target.value)}
          placeholder="First number"
        />

        <select value={operation} onChange={(e) => setOperation(e.target.value)}>
          {operations.map((op) => (
            <option key={op.value} value={op.value}>
              {op.label}
            </option>
          ))}
        </select>

        <input
          type="number"
          value={num2}
          onChange={(e) => setNum2(e.target.value)}
          placeholder="Second number"
        />
      </div>

      <button onClick={handleCalculate}>Calculate</button>

      {error && <p className="error">{error}</p>}

      {result !== null && !error && (
        <p className="result">Result: {result}</p>
      )}
    </div>
  )
}

export default App
