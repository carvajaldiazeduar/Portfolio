import sys

def add_contact(contacts, name, phone, email):
    contacts.append({"name": name, "phone": phone, "email": email})
    print("Contact added!")

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
