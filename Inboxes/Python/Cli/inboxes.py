import sys
from datetime import datetime

messages = []
next_id = 1


def send_message(from_, subject, body):
    global next_id
    msg = {
        "id": next_id,
        "from": from_,
        "subject": subject,
        "body": body,
        "read": False,
        "created_at": datetime.now().isoformat(),
    }
    messages.append(msg)
    next_id += 1
    return msg


def list_messages():
    return messages


def read_message(id):
    for m in messages:
        if m["id"] == id:
            m["read"] = True
            return m
    return None


def delete_message(id):
    global messages
    for i, m in enumerate(messages):
        if m["id"] == id:
            messages.pop(i)
            return True
    return False


def main():
    while True:
        print("\n=== Inbox CLI ===")
        print("1. Send message")
        print("2. List messages")
        print("3. Read message")
        print("4. Delete message")
        print("5. Exit")
        choice = input("Choice: ").strip()

        if choice == "1":
            from_ = input("From: ").strip()
            subject = input("Subject: ").strip()
            body = input("Body: ").strip()
            msg = send_message(from_, subject, body)
            print(f"Message sent (id={msg['id']})")
        elif choice == "2":
            msgs = list_messages()
            if not msgs:
                print("No messages.")
            else:
                for m in msgs:
                    status = "✓" if m["read"] else "✗"
                    print(
                        f"[{m['id']}] {status} From: {m['from']} | "
                        f"Subject: {m['subject']} | {m['created_at']}"
                    )
        elif choice == "3":
            try:
                id = int(input("Message ID: ").strip())
            except ValueError:
                print("Invalid ID.")
                continue
            msg = read_message(id)
            if msg:
                print(f"From: {msg['from']}")
                print(f"Subject: {msg['subject']}")
                print(f"Date: {msg['created_at']}")
                print(f"---\n{msg['body']}")
            else:
                print("Message not found.")
        elif choice == "4":
            try:
                id = int(input("Message ID: ").strip())
            except ValueError:
                print("Invalid ID.")
                continue
            if delete_message(id):
                print("Message deleted.")
            else:
                print("Message not found.")
        elif choice == "5":
            break


if __name__ == "__main__":
    main()
