using System.Text.Json;
using Microsoft.EntityFrameworkCore;

public class MessageService
{
    private readonly InboxesDbContext _db;
    private readonly ICacheAdapter _cache;

    public MessageService(InboxesDbContext db, ICacheAdapter cache)
    {
        _db = db;
        _cache = cache;
    }

    public List<Message> GetAll()
    {
        var cached = _cache.Get("messages:all");
        if (cached != null)
            return JsonSerializer.Deserialize<List<Message>>(cached)!;
        var list = _db.Messages.OrderBy(m => m.Id).ToList();
        _cache.Set("messages:all", JsonSerializer.Serialize(list));
        return list;
    }

    public Message Add(string sender, string subject, string body)
    {
        var msg = new Message { Sender = sender, Subject = subject, Body = body, Read = false, CreatedAt = DateTime.UtcNow.ToString("o") };
        _db.Messages.Add(msg);
        _db.SaveChanges();
        _cache.Delete("messages:all");
        return msg;
    }

    public Message? GetById(int id)
    {
        var cached = _cache.Get($"message:{id}");
        if (cached != null)
            return JsonSerializer.Deserialize<Message>(cached);
        var msg = _db.Messages.Find(id);
        if (msg == null) return null;
        msg.Read = true;
        _db.Messages.Update(msg);
        _db.SaveChanges();
        _cache.Delete("messages:all");
        _cache.Set($"message:{id}", JsonSerializer.Serialize(msg));
        return msg;
    }

    public bool Delete(int id)
    {
        var msg = _db.Messages.Find(id);
        if (msg == null) return false;
        _db.Messages.Remove(msg);
        _db.SaveChanges();
        _cache.Delete("messages:all");
        _cache.Delete($"message:{id}");
        return true;
    }
}