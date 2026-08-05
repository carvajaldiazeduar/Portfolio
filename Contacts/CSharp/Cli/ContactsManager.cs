namespace ContactsCli;

public class Contact
{
    public string Name { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Email { get; set; } = "";
}

public class ContactsManager
{
    private readonly List<Contact> _contacts = new();

    public IReadOnlyList<Contact> Contacts => _contacts.AsReadOnly();

    public void AddContact(string name, string phone, string email)
    {
        _contacts.Add(new Contact { Name = name, Phone = phone, Email = email });
    }

    public List<Contact> SearchContacts(string query)
    {
        return _contacts
            .Where(c => c.Name.Contains(query, StringComparison.OrdinalIgnoreCase))
            .ToList();
    }

    public bool DeleteContact(int index, out Contact? removed)
    {
        if (index < 0 || index >= _contacts.Count)
        {
            removed = null;
            return false;
        }
        removed = _contacts[index];
        _contacts.RemoveAt(index);
        return true;
    }
}
