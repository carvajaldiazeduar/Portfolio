const readline = require('readline');

function validateContact(name, phone, email) {
  const errors = {};
  const n = String(name == null ? '' : name).trim();
  const p = String(phone == null ? '' : phone).trim();
  const e = String(email == null ? '' : email).trim();
  if (!n) {
    errors.name = 'Name is required';
  } else if (n.length < 2 || n.length > 100 || !/^[A-Za-zÀ-ÿ' .-]+$/.test(n)) {
    errors.name = 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)';
  }
  if (!p) {
    errors.phone = 'Phone is required';
  } else if (!/^[0-9 +().-]{7,20}$/.test(p)) {
    errors.phone = 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)';
  }
  if (!e) {
    errors.email = 'Email is required';
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e)) {
    errors.email = 'Invalid email format';
  }
  return errors;
}

function addContact(contacts, name, phone, email) {
  const errors = validateContact(name, phone, email);
  if (Object.keys(errors).length > 0) {
    for (const field of Object.keys(errors)) {
      console.error(errors[field]);
    }
    return false;
  }
  contacts.push({
    name: String(name == null ? '' : name).trim(),
    phone: String(phone == null ? '' : phone).trim(),
    email: String(email == null ? '' : email).trim()
  });
  console.log('Contact added!');
  return true;
}

function listContacts(contacts) {
  if (contacts.length === 0) {
    console.log('No contacts found.');
    return;
  }
  contacts.forEach((c, i) => {
    console.log(`${i}. ${c.name} | ${c.phone} | ${c.email}`);
  });
}

function searchContacts(contacts, query) {
  const q = query.toLowerCase();
  const results = contacts.filter(c => c.name.toLowerCase().includes(q));
  if (results.length === 0) {
    console.log('No contacts found.');
  } else {
    results.forEach((c, i) => {
      console.log(`${i}. ${c.name} | ${c.phone} | ${c.email}`);
    });
  }
  return results;
}

function deleteContact(contacts, index) {
  if (index >= 0 && index < contacts.length) {
    const removed = contacts.splice(index, 1)[0];
    console.log(`Deleted ${removed.name}`);
  } else {
    console.log('Invalid index.');
  }
}

function main() {
  const contacts = [];
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  function prompt() {
    console.log('\n--- Contact Manager ---');
    console.log('1. Add Contact');
    console.log('2. List Contacts');
    console.log('3. Search Contacts');
    console.log('4. Delete Contact');
    console.log('5. Exit');
    rl.question('Choose an option: ', (choice) => {
      switch (choice.trim()) {
        case '1':
          rl.question('Name: ', (name) => {
            rl.question('Phone: ', (phone) => {
              rl.question('Email: ', (email) => {
                addContact(contacts, name.trim(), phone.trim(), email.trim());
                prompt();
              });
            });
          });
          break;
        case '2':
          listContacts(contacts);
          prompt();
          break;
        case '3':
          rl.question('Search query: ', (query) => {
            searchContacts(contacts, query.trim());
            prompt();
          });
          break;
        case '4':
          listContacts(contacts);
          rl.question('Enter index to delete: ', (idx) => {
            deleteContact(contacts, parseInt(idx.trim(), 10));
            prompt();
          });
          break;
        case '5':
          console.log('Goodbye!');
          rl.close();
          break;
        default:
          prompt();
      }
    });
  }

  prompt();
}

module.exports = { addContact, listContacts, searchContacts, deleteContact, validateContact };

if (require.main === module) {
  main();
}
