namespace InboxesCli;

public class Message
{
    public int Id { get; set; }
    public string From { get; set; } = "";
    public string Subject { get; set; } = "";
    public string Body { get; set; } = "";
    public bool Read { get; set; }
    public string CreatedAt { get; set; } = "";
}

public class InboxManager
{
    private readonly List<Message> _messages = [];
    private int _nextId = 1;

    public Message Send(string from, string subject, string body)
    {
        var msg = new Message
        {
            Id = _nextId++,
            From = from,
            Subject = subject,
            Body = body,
            Read = false,
            CreatedAt = DateTime.UtcNow.ToString("o"),
        };
        _messages.Add(msg);
        return msg;
    }

    public List<Message> List()
    {
        return [.. _messages];
    }

    public Message? Read(int id)
    {
        var msg = _messages.Find(m => m.Id == id);
        if (msg != null) msg.Read = true;
        return msg;
    }

    public bool Delete(int id)
    {
        return _messages.RemoveAll(m => m.Id == id) > 0;
    }
}
