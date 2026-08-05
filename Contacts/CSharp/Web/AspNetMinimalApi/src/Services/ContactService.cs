using System.Text.Json;
using Microsoft.EntityFrameworkCore;

public class ContactService
{
    private readonly ContactsDbContext _db;
    private readonly ICacheAdapter _cache;

    public ContactService(ContactsDbContext db, ICacheAdapter cache)
    {
        _db = db;
        _cache = cache;
    }

    public List<Contact> GetAll()
    {
        var cached = _cache.Get("contacts:all");
        if (cached != null)
            return JsonSerializer.Deserialize<List<Contact>>(cached)!;
        var list = _db.Contacts.OrderBy(c => c.Id).ToList();
        _cache.Set("contacts:all", JsonSerializer.Serialize(list));
        return list;
    }

    public Contact Create(string name, string phone, string email)
    {
        var contact = new Contact { Name = name, Phone = phone, Email = email };
        _db.Contacts.Add(contact);
        _db.SaveChanges();
        _cache.Delete("contacts:all");
        return contact;
    }

    public List<Contact> Search(string query)
    {
        var cacheKey = $"contacts:search:{query}";
        var cached = _cache.Get(cacheKey);
        if (cached != null)
            return JsonSerializer.Deserialize<List<Contact>>(cached)!;
        var q = query.ToLower();
        var list = _db.Contacts
            .Where(c => c.Name.ToLower().Contains(q))
            .OrderBy(c => c.Id)
            .ToList();
        _cache.Set(cacheKey, JsonSerializer.Serialize(list));
        return list;
    }

    public bool Delete(int id)
    {
        var contact = _db.Contacts.Find(id);
        if (contact == null) return false;
        _db.Contacts.Remove(contact);
        _db.SaveChanges();
        _cache.Delete("contacts:all");
        return true;
    }
}

public class Contact
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Email { get; set; } = "";
}
