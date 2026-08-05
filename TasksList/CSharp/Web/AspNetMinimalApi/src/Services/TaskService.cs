using System.Text.Json;
using Microsoft.EntityFrameworkCore;

public class TaskService
{
    private readonly TasksListDbContext _db;
    private readonly ICacheAdapter _cache;

    public TaskService(TasksListDbContext db, ICacheAdapter cache)
    {
        _db = db;
        _cache = cache;
    }

    public List<TaskItem> GetAll()
    {
        var cached = _cache.Get("tasks:all");
        if (cached != null)
            return JsonSerializer.Deserialize<List<TaskItem>>(cached)!;
        var list = _db.Tasks.OrderBy(t => t.Id).ToList();
        _cache.Set("tasks:all", JsonSerializer.Serialize(list));
        return list;
    }

    public TaskItem Create(string title, string description)
    {
        var task = new TaskItem { Title = title, Description = description, Completed = false, CreatedAt = DateTime.UtcNow.ToString("o") };
        _db.Tasks.Add(task);
        _db.SaveChanges();
        _cache.Delete("tasks:all");
        return task;
    }

    public bool Complete(int id)
    {
        var task = _db.Tasks.Find(id);
        if (task == null) return false;
        task.Completed = true;
        _db.Tasks.Update(task);
        _db.SaveChanges();
        _cache.Delete("tasks:all");
        return true;
    }

    public bool Delete(int id)
    {
        var task = _db.Tasks.Find(id);
        if (task == null) return false;
        _db.Tasks.Remove(task);
        _db.SaveChanges();
        _cache.Delete("tasks:all");
        return true;
    }
}