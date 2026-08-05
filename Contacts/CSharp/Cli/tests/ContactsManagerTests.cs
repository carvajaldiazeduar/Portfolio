using ContactsCli;
using Xunit;

namespace ContactsCli.Tests;

public class ContactsManagerTests
{
    [Fact]
    public void AddContact_ShouldAddContact()
    {
        var mgr = new ContactsManager();
        mgr.AddContact("Alice", "123-456", "alice@test.com");
        Assert.Single(mgr.Contacts);
        Assert.Equal("Alice", mgr.Contacts[0].Name);
        Assert.Equal("123-456", mgr.Contacts[0].Phone);
        Assert.Equal("alice@test.com", mgr.Contacts[0].Email);
    }

    [Fact]
    public void SearchContacts_ShouldReturnMatching()
    {
        var mgr = new ContactsManager();
        mgr.AddContact("Alice", "123", "a@b.com");
        mgr.AddContact("Bob", "456", "b@c.com");
        mgr.AddContact("Alexander", "789", "alex@d.com");
        var results = mgr.SearchContacts("al");
        Assert.Equal(2, results.Count);
    }

    [Fact]
    public void SearchContacts_ShouldReturnEmpty_WhenNoMatch()
    {
        var mgr = new ContactsManager();
        mgr.AddContact("Alice", "123", "a@b.com");
        var results = mgr.SearchContacts("zzz");
        Assert.Empty(results);
    }

    [Fact]
    public void DeleteContact_ValidIndex_ShouldRemove()
    {
        var mgr = new ContactsManager();
        mgr.AddContact("Alice", "123", "a@b.com");
        mgr.AddContact("Bob", "456", "b@c.com");
        var success = mgr.DeleteContact(0, out var removed);
        Assert.True(success);
        Assert.Equal("Alice", removed!.Name);
        Assert.Single(mgr.Contacts);
        Assert.Equal("Bob", mgr.Contacts[0].Name);
    }

    [Fact]
    public void DeleteContact_InvalidIndex_ShouldReturnFalse()
    {
        var mgr = new ContactsManager();
        mgr.AddContact("Alice", "123", "a@b.com");
        var success = mgr.DeleteContact(5, out var removed);
        Assert.False(success);
        Assert.Null(removed);
    }

    [Fact]
    public void Contacts_ShouldStartEmpty()
    {
        var mgr = new ContactsManager();
        Assert.Empty(mgr.Contacts);
    }
}
