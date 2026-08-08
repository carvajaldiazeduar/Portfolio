import re
import sys

NAME_RE = re.compile(r"^[A-Za-zÀ-ÿ' .-]+$")
PHONE_RE = re.compile(r"^[0-9 +().-]{7,20}$")
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$")

NAME_REQUIRED = "Name is required"
PHONE_REQUIRED = "Phone is required"
EMAIL_REQUIRED = "Email is required"
NAME_FORMAT = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"
PHONE_FORMAT = "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"
EMAIL_FORMAT = "Invalid email format"

def validate_contact(data):
    errors = {}
    name = (data.get("name") or "").strip() if data else ""
    phone = (data.get("phone") or "").strip() if data else ""
    email = (data.get("email") or "").strip() if data else ""
    if not name:
        errors["name"] = NAME_REQUIRED
    elif not (2 <= len(name) <= 100) or not NAME_RE.match(name):
        errors["name"] = NAME_FORMAT
    if not phone:
        errors["phone"] = PHONE_REQUIRED
    elif not PHONE_RE.match(phone):
        errors["phone"] = PHONE_FORMAT
    if not email:
        errors["email"] = EMAIL_REQUIRED
    elif not EMAIL_RE.match(email):
        errors["email"] = EMAIL_FORMAT
    return errors, {"name": name, "phone": phone, "email": email}

def add_contact(contacts, name, phone, email):
    errors, values = validate_contact({"name": name, "phone": phone, "email": email})
    if errors:
        for msg in errors.values():
            print(msg, file=sys.stderr)
        return False
    contacts.append({"name": values["name"], "phone": values["phone"], "email": values["email"]})
    print("Contact added!")
    return True

def list_contacts(contacts):
    if not contacts:
        print("No contacts found.")
        return
    for i, c in enumerate(contacts):
        print(f"{i}. {c['name']} | {c['phone']} | {c['email']}")

def search_contacts(contacts, query):
    results = [c for c in contacts if query.lower() in c['name'].lower()]
    if not results:
        print("No contacts found.")
    else:
        for i, c in enumerate(results):
            print(f"{i}. {c['name']} | {c['phone']} | {c['email']}")
    return results

def delete_contact(contacts, index):
    if 0 <= index < len(contacts):
        removed = contacts.pop(index)
        print(f"Deleted {removed['name']}")
    else:
        print("Invalid index.")

def main():
    contacts = []
    while True:
        print("\n--- Contact Manager ---")
        print("1. Add Contact")
        print("2. List Contacts")
        print("3. Search Contacts")
        print("4. Delete Contact")
        print("5. Exit")
        choice = input("Choose an option: ").strip()
        if choice == '1':
            name = input("Name: ").strip()
            phone = input("Phone: ").strip()
            email = input("Email: ").strip()
            add_contact(contacts, name, phone, email)
        elif choice == '2':
            list_contacts(contacts)
        elif choice == '3':
            query = input("Search query: ").strip()
            search_contacts(contacts, query)
        elif choice == '4':
            list_contacts(contacts)
            try:
                idx = int(input("Enter index to delete: ").strip())
                delete_contact(contacts, idx)
            except ValueError:
                print("Invalid input.")
        elif choice == '5':
            print("Goodbye!")
            break

if __name__ == "__main__":
    main()
