const { addContact, listContacts, searchContacts, deleteContact } = require('../contacts');

describe('Contacts CLI', () => {
  test('addContact adds a contact', () => {
    const contacts = [];
    addContact(contacts, 'Alice', '123-456', 'alice@test.com');
    expect(contacts).toHaveLength(1);
    expect(contacts[0].name).toBe('Alice');
    expect(contacts[0].phone).toBe('123-456');
    expect(contacts[0].email).toBe('alice@test.com');
  });

  test('searchContacts finds by name', () => {
    const contacts = [
      { name: 'Alice', phone: '123', email: 'a@b.com' },
      { name: 'Bob', phone: '456', email: 'b@c.com' },
      { name: 'Alexander', phone: '789', email: 'alex@d.com' }
    ];
    const results = searchContacts(contacts, 'al');
    expect(results).toHaveLength(2);
  });

  test('searchContacts returns empty for no match', () => {
    const contacts = [
      { name: 'Alice', phone: '123', email: 'a@b.com' }
    ];
    const results = searchContacts(contacts, 'zzz');
    expect(results).toHaveLength(0);
  });

  test('deleteContact removes by index', () => {
    const contacts = [
      { name: 'Alice', phone: '123', email: 'a@b.com' },
      { name: 'Bob', phone: '456', email: 'b@c.com' }
    ];
    deleteContact(contacts, 0);
    expect(contacts).toHaveLength(1);
    expect(contacts[0].name).toBe('Bob');
  });

  test('deleteContact with invalid index does nothing', () => {
    const contacts = [
      { name: 'Alice', phone: '123', email: 'a@b.com' }
    ];
    deleteContact(contacts, 5);
    expect(contacts).toHaveLength(1);
  });
});
