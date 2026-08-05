'use client'

import { useState } from 'react'

export default function Home() {
  const [contacts, setContacts] = useState([])
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')

  function addContact() {
    if (!name.trim() || !phone.trim() || !email.trim()) return
    setContacts([...contacts, { id: Date.now(), name, phone, email }])
    setName('')
    setPhone('')
    setEmail('')
  }

  function deleteContact(id) {
    setContacts(contacts.filter((c) => c.id !== id))
  }

  return (
    <div className="container">
      <h1>Contacts</h1>
      <div className="form">
        <div className="form-group">
          <label htmlFor="name">Name</label>
          <input id="name" value={name} onChange={(e) => setName(e.target.value)} placeholder="Enter name" />
        </div>
        <div className="form-group">
          <label htmlFor="phone">Phone</label>
          <input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="Enter phone" />
        </div>
        <div className="form-group">
          <label htmlFor="email">Email</label>
          <input id="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Enter email" />
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
