import { useState } from 'react'

function validateContact(name, phone, email) {
  const errors = {}
  const n = String(name == null ? '' : name).trim()
  const p = String(phone == null ? '' : phone).trim()
  const e = String(email == null ? '' : email).trim()
  if (!n) {
    errors.name = 'Name is required'
  } else if (n.length < 2 || n.length > 100 || !/^[A-Za-zÀ-ÿ' .-]+$/.test(n)) {
    errors.name = 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)'
  }
  if (!p) {
    errors.phone = 'Phone is required'
  } else if (!/^[0-9 +().-]{7,20}$/.test(p)) {
    errors.phone = 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)'
  }
  if (!e) {
    errors.email = 'Email is required'
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e)) {
    errors.email = 'Invalid email format'
  }
  return errors
}

function App() {
  const [contacts, setContacts] = useState([])
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [errors, setErrors] = useState({})
  const [attempted, setAttempted] = useState(false)

  function addContact() {
    const errs = validateContact(name, phone, email)
    setErrors(errs)
    setAttempted(true)
    if (Object.keys(errs).length > 0) return
    setContacts([...contacts, { id: Date.now(), name: name.trim(), phone: phone.trim(), email: email.trim() }])
    setName('')
    setPhone('')
    setEmail('')
    setErrors({})
    setAttempted(false)
  }

  function fieldClass(field) {
    return attempted ? (errors[field] ? 'invalid' : 'valid') : ''
  }

  function deleteContact(id) {
    setContacts(contacts.filter((c) => c.id !== id))
  }

  return (
    <div className="contacts">
      <h1>Contacts</h1>
      <div className="form">
        <div className="form-field">
          <input className={fieldClass('name')} value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" />
          {attempted && errors.name && <span className="field-error">{errors.name}</span>}
        </div>
        <div className="form-field">
          <input className={fieldClass('phone')} value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="Phone" />
          {attempted && errors.phone && <span className="field-error">{errors.phone}</span>}
        </div>
        <div className="form-field">
          <input className={fieldClass('email')} value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" />
          {attempted && errors.email && <span className="field-error">{errors.email}</span>}
        </div>
        <button onClick={addContact}>Add Contact</button>
      </div>
      <div className="list">
        {contacts.length === 0 && <p className="empty">No contacts yet.</p>}
        {contacts.map((c) => (
          <div key={c.id} className="card">
            <div className="info">
              <strong>{c.name}</strong>
              <span>{c.phone}</span>
              <span>{c.email}</span>
            </div>
            <button className="delete" onClick={() => deleteContact(c.id)}>Delete</button>
          </div>
        ))}
      </div>
    </div>
  )
}

export default App
