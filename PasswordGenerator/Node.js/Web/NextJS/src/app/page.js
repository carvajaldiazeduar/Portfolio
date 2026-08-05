'use client'

import { useState, useCallback } from 'react'

const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const lower = 'abcdefghijklmnopqrstuvwxyz'
const digits = '0123456789'
const symbols = '!@#$%^&*()_+-=[]{}|;:,.<>?'

function generatePassword(length, useUpper, useLower, useDigits, useSymbols) {
  let chars = ''
  if (useUpper) chars += upper
  if (useLower) chars += lower
  if (useDigits) chars += digits
  if (useSymbols) chars += symbols
  if (!chars) return ''

  let password = ''
  for (let i = 0; i < length; i++) {
    password += chars[Math.floor(Math.random() * chars.length)]
  }
  return password
}

export default function Home() {
  const [length, setLength] = useState(12)
  const [useUpper, setUseUpper] = useState(true)
  const [useLower, setUseLower] = useState(true)
  const [useDigits, setUseDigits] = useState(true)
  const [useSymbols, setUseSymbols] = useState(false)
  const [password, setPassword] = useState('')
  const [copied, setCopied] = useState(false)

  const handleGenerate = useCallback(() => {
    setPassword(generatePassword(length, useUpper, useLower, useDigits, useSymbols))
    setCopied(false)
  }, [length, useUpper, useLower, useDigits, useSymbols])

  function copyToClipboard() {
    if (!password) return
    navigator.clipboard.writeText(password)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="container">
      <h1>Password Generator</h1>
      <div className="output">
        <input type="text" value={password} readOnly placeholder="Click Generate" />
        <button className="copy" onClick={copyToClipboard} disabled={!password}>
          {copied ? 'Copied!' : 'Copy'}
        </button>
      </div>
      <div className="options">
        <div className="form-group">
          <label>Length: {length}</label>
          <input type="range" min={4} max={32} value={length} onChange={(e) => setLength(Number(e.target.value))} />
        </div>
        <label className="checkbox">
          <input type="checkbox" checked={useUpper} onChange={(e) => setUseUpper(e.target.checked)} />
          Uppercase (A-Z)
        </label>
        <label className="checkbox">
          <input type="checkbox" checked={useLower} onChange={(e) => setUseLower(e.target.checked)} />
          Lowercase (a-z)
        </label>
        <label className="checkbox">
          <input type="checkbox" checked={useDigits} onChange={(e) => setUseDigits(e.target.checked)} />
          Digits (0-9)
        </label>
        <label className="checkbox">
          <input type="checkbox" checked={useSymbols} onChange={(e) => setUseSymbols(e.target.checked)} />
          Symbols (!@#$%...)
        </label>
      </div>
      <button className="generate" onClick={handleGenerate}>Generate Password</button>
    </div>
  )
}
