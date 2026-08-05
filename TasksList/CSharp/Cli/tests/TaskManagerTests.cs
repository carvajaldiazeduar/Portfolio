using Xunit;
using TasksListCli;

namespace TasksListCli.Tests;

public class TaskManagerTests
{
    [Fact]
    public void AddTask_ShouldAddAndReturnId()
    {
        var tasks = new List<TaskItem>();
        var id = TaskManager.AddTask(tasks, "Test", "A task");
        Assert.Equal(1, id);
        Assert.Single(tasks);
        Assert.Equal("Test", tasks[0].Title);
        Assert.Equal("A task", tasks[0].Description);
        Assert.False(tasks[0].Completed);
        Assert.NotNull(tasks[0].CreatedAt);
    }

    [Fact]
    public void AddTask_ShouldAutoIncrement()
    {
        var tasks = new List<TaskItem>
        {
            new() { Id = 1, Title = "a", Description = "", Completed = false, CreatedAt = "" }
        };
        var id = TaskManager.AddTask(tasks, "b", "");
        Assert.Equal(2, id);
    }

    [Fact]
    public void ListTasks_NoTasks_ShouldPrintMessage()
    {
        var writer = new StringWriter();
        Console.SetOut(writer);
        TaskManager.ListTasks(new List<TaskItem>());
        Assert.Contains("No tasks found.", writer.ToString());
    }

    [Fact]
    public void ListTasks_ShouldShowIncomplete()
    {
        var tasks = new List<TaskItem>
        {
            new() { Id = 1, Title = "Buy milk", Description = "", Completed = false, CreatedAt = "now" }
        };
        var writer = new StringWriter();
        Console.SetOut(writer);
        TaskManager.ListTasks(tasks);
        var output = writer.ToString();
        Assert.Contains("[ ]", output);
        Assert.Contains("Buy milk", output);
    }

    [Fact]
    public void ListTasks_ShouldShowCompleted()
    {
        var tasks = new List<TaskItem>
        {
            new() { Id = 1, Title = "Done", Description = "", Completed = true, CreatedAt = "now" }
        };
        var writer = new StringWriter();
        Console.SetOut(writer);
        TaskManager.ListTasks(tasks);
        Assert.Contains("[x]", writer.ToString());
    }

    [Fact]
    public void CompleteTask_ShouldMarkComplete()
    {
        var tasks = new List<TaskItem>
        {
            new() { Id = 1, Title = "a", Description = "", Completed = false, CreatedAt = "" }
        };
        var result = TaskManager.CompleteTask(tasks, 1);
        Assert.True(result);
        Assert.True(tasks[0].Completed);
    }

    [Fact]
    public void CompleteTask_NotFound_ReturnsFalse()
    {
        var result = TaskManager.CompleteTask(new List<TaskItem>(), 99);
        Assert.False(result);
    }

    [Fact]
    public void DeleteTask_ShouldRemove()
    {
        var tasks = new List<TaskItem>
        {
            new() { Id = 1, Title = "a", Description = "", Completed = false, CreatedAt = "" }
        };
        var result = TaskManager.DeleteTask(tasks, 1);
        Assert.True(result);
        Assert.Empty(tasks);
    }

    [Fact]
    public void DeleteTask_NotFound_ReturnsFalse()
    {
        var tasks = new List<TaskItem>
        {
            new() { Id = 1, Title = "a", Description = "", Completed = false, CreatedAt = "" }
        };
        var result = TaskManager.DeleteTask(tasks, 99);
        Assert.False(result);
        Assert.Single(tasks);
    }
}
