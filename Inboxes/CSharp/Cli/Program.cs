using InboxesCli;

var manager = new InboxManager();

while (true)
{
    Console.WriteLine("\n=== Inbox CLI ===");
    Console.WriteLine("1. Send message");
    Console.WriteLine("2. List messages");
    Console.WriteLine("3. Read message");
    Console.WriteLine("4. Delete message");
    Console.WriteLine("5. Exit");
    Console.Write("Choice: ");
    var choice = Console.ReadLine()?.Trim();

    switch (choice)
    {
        case "1":
            Console.Write("From: ");
            var from = Console.ReadLine()?.Trim() ?? "";
            Console.Write("Subject: ");
            var subject = Console.ReadLine()?.Trim() ?? "";
            Console.Write("Body: ");
            var body = Console.ReadLine()?.Trim() ?? "";
            var msg = manager.Send(from, subject, body);
            Console.WriteLine($"Message sent (id={msg.Id})");
            break;
        case "2":
            var msgs = manager.List();
            if (msgs.Count == 0)
            {
                Console.WriteLine("No messages.");
            }
            else
            {
                foreach (var m in msgs)
                {
                    var status = m.Read ? "✓" : "✗";
                    Console.WriteLine($"[{m.Id}] {status} From: {m.From} | Subject: {m.Subject} | {m.CreatedAt}");
                }
            }
            break;
        case "3":
            Console.Write("Message ID: ");
            if (int.TryParse(Console.ReadLine(), out var readId))
            {
                var readMsg = manager.Read(readId);
                if (readMsg != null)
                {
                    Console.WriteLine($"From: {readMsg.From}");
                    Console.WriteLine($"Subject: {readMsg.Subject}");
                    Console.WriteLine($"Date: {readMsg.CreatedAt}");
                    Console.WriteLine($"---\n{readMsg.Body}");
                }
                else
                {
                    Console.WriteLine("Message not found.");
                }
            }
            break;
        case "4":
            Console.Write("Message ID: ");
            if (int.TryParse(Console.ReadLine(), out var delId))
            {
                Console.WriteLine(manager.Delete(delId) ? "Message deleted." : "Message not found.");
            }
            break;
        case "5":
            return;
    }
}
