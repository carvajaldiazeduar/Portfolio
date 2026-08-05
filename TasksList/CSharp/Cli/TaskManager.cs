namespace TasksListCli;

public class TaskItem
{
    public int Id { get; set; }
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public bool Completed { get; set; }
    public string CreatedAt { get; set; } = "";
}

public static class TaskManager
{
    private static int _nextId(List<TaskItem> tasks) =>
        tasks.Count == 0 ? 1 : tasks.Max(t => t.Id) + 1;

    public static int AddTask(List<TaskItem> tasks, string title, string description)
    {
        var task = new TaskItem
        {
            Id = _nextId(tasks),
            Title = title,
            Description = description,
            Completed = false,
            CreatedAt = DateTime.Now.ToString("o")
        };
        tasks.Add(task);
        return task.Id;
    }

    public static void ListTasks(List<TaskItem> tasks)
    {
        if (tasks.Count == 0)
        {
            Console.WriteLine("No tasks found.");
            return;
        }
        foreach (var t in tasks)
        {
            var status = t.Completed ? "[x]" : "[ ]";
            Console.WriteLine($"{status} {t.Id}. {t.Title} \u2014 {t.CreatedAt}");
        }
    }

    public static bool CompleteTask(List<TaskItem> tasks, int id)
    {
        var task = tasks.Find(t => t.Id == id);
        if (task == null) return false;
        task.Completed = true;
        return true;
    }

    public static bool DeleteTask(List<TaskItem> tasks, int id)
    {
        var task = tasks.Find(t => t.Id == id);
        if (task == null) return false;
        tasks.Remove(task);
        return true;
    }

}
