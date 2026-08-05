using TasksListCli;

var tasks = new List<TaskItem>();

while (true)
{
    Console.WriteLine("\n=== Tasks List ===");
    Console.WriteLine("1. Add Task");
    Console.WriteLine("2. List Tasks");
    Console.WriteLine("3. Complete Task");
    Console.WriteLine("4. Delete Task");
    Console.WriteLine("5. Exit");
    Console.Write("Choose an option: ");
    var choice = Console.ReadLine()?.Trim();

    switch (choice)
    {
        case "1":
            Console.Write("Title: ");
            var title = Console.ReadLine()?.Trim() ?? "";
            Console.Write("Description: ");
            var description = Console.ReadLine()?.Trim() ?? "";
            TaskManager.AddTask(tasks, title, description);
            Console.WriteLine("Task added.");
            break;
        case "2":
            TaskManager.ListTasks(tasks);
            break;
        case "3":
            Console.Write("Task ID to complete: ");
            if (int.TryParse(Console.ReadLine()?.Trim(), out var completeId))
            {
                if (TaskManager.CompleteTask(tasks, completeId))
                    Console.WriteLine("Task completed.");
                else
                    Console.WriteLine("Task not found.");
            }
            else
            {
                Console.WriteLine("Invalid ID.");
            }
            break;
        case "4":
            Console.Write("Task ID to delete: ");
            if (int.TryParse(Console.ReadLine()?.Trim(), out var deleteId))
            {
                if (TaskManager.DeleteTask(tasks, deleteId))
                    Console.WriteLine("Task deleted.");
                else
                    Console.WriteLine("Task not found.");
            }
            else
            {
                Console.WriteLine("Invalid ID.");
            }
            break;
        case "5":
            Console.WriteLine("Goodbye!");
            return;
        default:
            Console.WriteLine("Invalid option.");
            break;
    }
}
