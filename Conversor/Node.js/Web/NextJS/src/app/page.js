'use client'

import { useState } from 'react'

const categories = {
  length: {
    name: 'Length',
    units: ['Meters', 'Kilometers', 'Miles', 'Feet', 'Inches', 'Centimeters'],
    factors: {
      Meters: 1,
      Kilometers: 1000,
      Miles: 1609.344,
      Feet: 0.3048,
      Inches: 0.0254,
      Centimeters: 0.01,
    },
  },
  weight: {
    name: 'Weight',
    units: ['Kilograms', 'Grams', 'Pounds', 'Ounces', 'Tons'],
    factors: {
      Kilograms: 1,
      Grams: 0.001,
      Pounds: 0.453592,
      Ounces: 0.0283495,
      Tons: 1000,
    },
  },
  temperature: {
    name: 'Temperature',
    units: ['Celsius', 'Fahrenheit', 'Kelvin'],
    factors: null,
  },
}

function convertTemp(value, from, to) {
  if (from === to) return value
  let celsius
  if (from === 'Celsius') celsius = value
  else if (from === 'Fahrenheit') celsius = (value - 32) * (5 / 9)
  else celsius = value - 273.15

  if (to === 'Celsius') return celsius
  if (to === 'Fahrenheit') return celsius * (9 / 5) + 32
  return celsius + 273.15
}

export default function Home() {
  const [category, setCategory] = useState('length')
  const [fromUnit, setFromUnit] = useState('Meters')
  const [toUnit, setToUnit] = useState('Kilometers')
  const [value, setValue] = useState('')
  const [result, setResult] = useState(null)

  function handleConvert() {
    const num = parseFloat(value)
    if (isNaN(num)) return
    if (category === 'temperature') {
      setResult(convertTemp(num, fromUnit, toUnit))
    } else {
      const factorFrom = categories[category].factors[fromUnit]
      const factorTo = categories[category].factors[toUnit]
      setResult((num * factorFrom) / factorTo)
    }
  }

  const current = categories[category]

  return (
    <div className="container">
      <h1>Unit Conversor</h1>
      <div className="form">
        <div className="form-group">
          <label htmlFor="category">Category</label>
          <select id="category" value={category} onChange={(e) => { setCategory(e.target.value); setFromUnit(categories[e.target.value].units[0]); setToUnit(categories[e.target.value].units[1] || categories[e.target.value].units[0]); setResult(null) }}>
            {Object.entries(categories).map(([key, cat]) => (
              <option key={key} value={key}>{cat.name}</option>
            ))}
          </select>
        </div>
        <div className="form-group">
          <label htmlFor="value">Value</label>
          <input id="value" type="number" value={value} onChange={(e) => setValue(e.target.value)} placeholder="Enter value" />
        </div>
        <div className="form-group">
          <label htmlFor="fromUnit">From</label>
          <select id="fromUnit" value={fromUnit} onChange={(e) => setFromUnit(e.target.value)}>
            {current.units.map((u) => <option key={u} value={u}>{u}</option>)}
          </select>
        </div>
        <div className="form-group">
          <label htmlFor="toUnit">To</label>
          <select id="toUnit" value={toUnit} onChange={(e) => setToUnit(e.target.value)}>
            {current.units.map((u) => <option key={u} value={u}>{u}</option>)}
          </select>
        </div>
        <button onClick={handleConvert}>Convert</button>
      </div>
      {result !== null && (
        <div className="result success">
          {value} {fromUnit} = {result.toFixed(4)} {toUnit}
        </div>
      )}
    </div>
  )
}
