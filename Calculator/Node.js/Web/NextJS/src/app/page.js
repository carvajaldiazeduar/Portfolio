'use client'

import { useState } from 'react'

export default function Home() {
  const [num1, setNum1] = useState('')
  const [num2, setNum2] = useState('')
  const [operator, setOperator] = useState('add')
  const [result, setResult] = useState(null)
  const [error, setError] = useState('')

  const calculate = () => {
    setError('')
    setResult(null)

    const a = parseFloat(num1)
    const b = parseFloat(num2)

    if (isNaN(a) || isNaN(b)) {
      setError('Please enter valid numbers')
      return
    }

    if (operator === 'divide' && b === 0) {
      setError('Cannot divide by zero')
      return
    }

    let res
    switch (operator) {
      case 'add':
        res = a + b
        break
      case 'subtract':
        res = a - b
        break
      case 'multiply':
        res = a * b
        break
      case 'divide':
        res = a / b
        break
      default:
        res = 0
    }

    setResult(res)
  }

  return (
    <div className="container">
      <h1>Calculator</h1>

      <div className="form-group">
        <label htmlFor="num1">First Number</label>
        <input
          id="num1"
          type="number"
          value={num1}
          onChange={(e) => setNum1(e.target.value)}
          placeholder="Enter first number"
        />
      </div>

      <div className="form-group">
        <label htmlFor="operator">Operation</label>
        <select
          id="operator"
          value={operator}
          onChange={(e) => setOperator(e.target.value)}
        >
          <option value="add">Add (+)</option>
          <option value="subtract">Subtract (−)</option>
          <option value="multiply">Multiply (×)</option>
          <option value="divide">Divide (÷)</option>
        </select>
      </div>

      <div className="form-group">
        <label htmlFor="num2">Second Number</label>
        <input
          id="num2"
          type="number"
          value={num2}
          onChange={(e) => setNum2(e.target.value)}
          placeholder="Enter second number"
        />
      </div>

      <button onClick={calculate}>Calculate</button>

      {result !== null && (
        <div className="result success">
          Result: {result}
        </div>
      )}

      {error && (
        <div className="result error">
          {error}
        </div>
      )}
    </div>
  )
}
