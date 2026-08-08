using System.Text.RegularExpressions;

public class Contact
{
    public string Name { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Email { get; set; } = "";
}

public static class ContactValidator
{
    private static readonly Regex NameRegex = new(@"^[A-Za-zÀ-ÿ' .-]+$", RegexOptions.Compiled);
    private static readonly Regex PhoneRegex = new(@"^[0-9 +().-]{7,20}$", RegexOptions.Compiled);
    private static readonly Regex EmailRegex = new(@"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$", RegexOptions.Compiled);

    public static Dictionary<string, string> Validate(string? name, string? phone, string? email)
    {
        var errors = new Dictionary<string, string>();
        var n = name?.Trim() ?? "";
        var p = phone?.Trim() ?? "";
        var e = email?.Trim() ?? "";

        if (n.Length == 0)
        {
            errors["name"] = "Name is required";
        }
        else if (n.Length < 2 || n.Length > 100 || !NameRegex.IsMatch(n))
        {
            errors["name"] = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)";
        }

        if (p.Length == 0)
        {
            errors["phone"] = "Phone is required";
        }
        else if (!PhoneRegex.IsMatch(p))
        {
            errors["phone"] = "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)";
        }

        if (e.Length == 0)
        {
            errors["email"] = "Email is required";
        }
        else if (!EmailRegex.IsMatch(e))
        {
            errors["email"] = "Invalid email format";
        }

        return errors;
    }
}

public class ContactsManager
{
    private readonly List<Contact> _contacts = new();

    public IReadOnlyList<Contact> Contacts => _contacts.AsReadOnly();

    public Dictionary<string, string> AddContact(string name, string phone, string email)
    {
        var errors = ContactValidator.Validate(name, phone, email);
        if (errors.Count > 0)
        {
            return errors;
        }
        _contacts.Add(new Contact
        {
            Name = name.Trim(),
            Phone = phone.Trim(),
            Email = email.Trim()
        });
        return errors;
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
