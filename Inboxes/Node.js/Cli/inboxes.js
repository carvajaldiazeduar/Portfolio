const messages = [];
let nextId = 1;

function sendMessage(from, subject, body) {
  const msg = {
    id: nextId++,
    from,
    subject,
    body,
    read: false,
    created_at: new Date().toISOString(),
  };
  messages.push(msg);
  return msg;
}

function listMessages() {
  return messages;
}

function readMessage(id) {
  const msg = messages.find((m) => m.id === id);
  if (msg) msg.read = true;
  return msg || null;
}

function deleteMessage(id) {
  const idx = messages.findIndex((m) => m.id === id);
  if (idx !== -1) {
    messages.splice(idx, 1);
    return true;
  }
  return false;
}

module.exports = { sendMessage, listMessages, readMessage, deleteMessage };

if (require.main === module) {
  const readline = require("readline").createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  function prompt(question) {
    return new Promise((resolve) => readline.question(question, resolve));
  }

  (async () => {
    while (true) {
      console.log("\n=== Inbox CLI ===");
      console.log("1. Send message");
      console.log("2. List messages");
      console.log("3. Read message");
      console.log("4. Delete message");
      console.log("5. Exit");
      const choice = (await prompt("Choice: ")).trim();

      if (choice === "1") {
        const from = (await prompt("From: ")).trim();
        const subject = (await prompt("Subject: ")).trim();
        const body = (await prompt("Body: ")).trim();
        const msg = sendMessage(from, subject, body);
        console.log(`Message sent (id=${msg.id})`);
      } else if (choice === "2") {
        const msgs = listMessages();
        if (msgs.length === 0) {
          console.log("No messages.");
        } else {
          for (const m of msgs) {
            const status = m.read ? "✓" : "✗";
            console.log(
              `[${m.id}] ${status} From: ${m.from} | Subject: ${m.subject} | ${m.created_at}`
            );
          }
        }
      } else if (choice === "3") {
        const id = parseInt((await prompt("Message ID: ")).trim(), 10);
        const msg = readMessage(id);
        if (msg) {
          console.log(`From: ${msg.from}`);
          console.log(`Subject: ${msg.subject}`);
          console.log(`Date: ${msg.created_at}`);
          console.log(`---\n${msg.body}`);
        } else {
          console.log("Message not found.");
        }
      } else if (choice === "4") {
        const id = parseInt((await prompt("Message ID: ")).trim(), 10);
        if (deleteMessage(id)) {
          console.log("Message deleted.");
        } else {
          console.log("Message not found.");
        }
      } else if (choice === "5") {
        break;
      }
    }
    readline.close();
  })();
}
