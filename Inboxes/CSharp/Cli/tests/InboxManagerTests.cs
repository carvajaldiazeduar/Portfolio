using InboxesCli;
using Xunit;

namespace InboxesCli.Tests;

public class InboxManagerTests
{
    private readonly InboxManager _manager = new();

    public InboxManagerTests()
    {
        _manager = new InboxManager();
    }

    [Fact]
    public void SendMessage_CreatesMessage()
    {
        var msg = _manager.Send("alice", "Hello", "World");
        Assert.Equal(1, msg.Id);
        Assert.Equal("alice", msg.From);
        Assert.Equal("Hello", msg.Subject);
        Assert.Equal("World", msg.Body);
        Assert.False(msg.Read);
        Assert.NotNull(msg.CreatedAt);
    }

    [Fact]
    public void ListMessages_ReturnsAll()
    {
        _manager.Send("alice", "S1", "B1");
        _manager.Send("bob", "S2", "B2");
        Assert.Equal(2, _manager.List().Count);
    }

    [Fact]
    public void ReadMessage_MarksAsRead()
    {
        _manager.Send("alice", "Test", "Body");
        var msg = _manager.Read(1);
        Assert.NotNull(msg);
        Assert.True(msg.Read);
        var msg2 = _manager.Read(1);
        Assert.True(msg2!.Read);
    }

    [Fact]
    public void DeleteMessage_RemovesIt()
    {
        _manager.Send("alice", "Del", "Me");
        Assert.Single(_manager.List());
        Assert.True(_manager.Delete(1));
        Assert.Empty(_manager.List());
    }

    [Fact]
    public void ListAfterDelete_ShowsRemaining()
    {
        _manager.Send("alice", "Keep", "Me");
        _manager.Send("bob", "Delete", "This");
        _manager.Delete(2);
        var msgs = _manager.List();
        Assert.Single(msgs);
        Assert.Equal(1, msgs[0].Id);
    }

    [Fact]
    public void ReadNonexistent_ReturnsNull()
    {
        Assert.Null(_manager.Read(999));
    }

    [Fact]
    public void DeleteNonexistent_ReturnsFalse()
    {
        Assert.False(_manager.Delete(999));
    }
}
