var manager = new ContactsManager();

while (true)
{
    Console.WriteLine("\n--- Contact Manager ---");
    Console.WriteLine("1. Add Contact");
    Console.WriteLine("2. List Contacts");
    Console.WriteLine("3. Search Contacts");
    Console.WriteLine("4. Delete Contact");
    Console.WriteLine("5. Exit");
    Console.Write("Choose an option: ");
    var choice = Console.ReadLine()?.Trim();

    switch (choice)
    {
        case "1":
            Console.Write("Name: ");
            var name = Console.ReadLine()?.Trim() ?? "";
            Console.Write("Phone: ");
            var phone = Console.ReadLine()?.Trim() ?? "";
            Console.Write("Email: ");
            var email = Console.ReadLine()?.Trim() ?? "";
            var errors = manager.AddContact(name, phone, email);
            if (errors.Count > 0)
            {
                foreach (var e in errors)
                    Console.Error.WriteLine($"{e.Key}: {e.Value}");
            }
            else
            {
                Console.WriteLine("Contact added!");
            }
            break;

        case "2":
            var all = manager.Contacts;
            if (all.Count == 0)
            {
                Console.WriteLine("No contacts found.");
            }
            else
            {
                for (int i = 0; i < all.Count; i++)
                    Console.WriteLine($"{i}. {all[i].Name} | {all[i].Phone} | {all[i].Email}");
            }
            break;

        case "3":
            Console.Write("Search query: ");
            var query = Console.ReadLine()?.Trim() ?? "";
            var results = manager.SearchContacts(query);
            if (results.Count == 0)
            {
                Console.WriteLine("No contacts found.");
            }
            else
            {
                for (int i = 0; i < results.Count; i++)
                    Console.WriteLine($"{i}. {results[i].Name} | {results[i].Phone} | {results[i].Email}");
            }
            break;

        case "4":
            var list = manager.Contacts;
            if (list.Count == 0)
            {
                Console.WriteLine("No contacts to delete.");
                break;
            }
            for (int i = 0; i < list.Count; i++)
                Console.WriteLine($"{i}. {list[i].Name} | {list[i].Phone} | {list[i].Email}");
            Console.Write("Enter index to delete: ");
            if (int.TryParse(Console.ReadLine()?.Trim(), out int idx))
            {
                if (manager.DeleteContact(idx, out var removed))
                    Console.WriteLine($"Deleted {removed!.Name}");
                else
                    Console.WriteLine("Invalid index.");
            }
            else
            {
                Console.WriteLine("Invalid input.");
            }
            break;

        case "5":
            Console.WriteLine("Goodbye!");
            return;
    }
}
