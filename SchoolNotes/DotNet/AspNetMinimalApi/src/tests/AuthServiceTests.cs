using Microsoft.EntityFrameworkCore;
using Xunit;

namespace SchoolNotes.Tests;

public class AuthServiceTests
{
    static SchoolNotesDbContext NewDb()
    {
        var options = new DbContextOptionsBuilder()
            .UseInMemoryDatabase(System.Guid.NewGuid().ToString())
            .Options;
        return new SchoolNotesDbContext(options);
    }

    [Fact]
    public void Register_Creates_User_With_Hashed_Password()
    {
        using SchoolNotesDbContext db = NewDb();
        AuthService svc = new AuthService(db);
        bool ok = svc.Register("admin", "password123");

        Assert.True(ok);
        User user = db.Users.First(u => u.Username == "admin");
        Assert.NotEqual("password123", user.PasswordHash);
        Assert.Equal("admin", user.Role);
    }

    [Fact]
    public void Register_Duplicate_Username_Returns_False()
    {
        using SchoolNotesDbContext db = NewDb();
        AuthService svc = new AuthService(db);
        svc.Register("admin", "password123");

        bool ok = svc.Register("admin", "otherpass");

        Assert.False(ok);
    }

    [Fact]
    public void Verify_Correct_Password_Returns_True_And_User()
    {
        using SchoolNotesDbContext db = NewDb();
        AuthService svc = new AuthService(db);
        svc.Register("admin", "password123");

        bool ok = svc.Verify("admin", "password123", out User user);

        Assert.True(ok);
        Assert.NotNull(user);
        Assert.Equal("admin", user.Username);
    }

    [Fact]
    public void Verify_Wrong_Password_Returns_False_But_User_Not_Null()
    {
        using SchoolNotesDbContext db = NewDb();
        AuthService svc = new AuthService(db);
        svc.Register("admin", "password123");

        bool ok = svc.Verify("admin", "wrongpass", out User user);

        Assert.False(ok);
        Assert.NotNull(user); // User is returned for logging, but bool indicates failure
        Assert.Equal("admin", user.Username);
    }

    [Fact]
    public void Verify_NonExistent_User_Returns_False()
    {
        using SchoolNotesDbContext db = NewDb();
        AuthService svc = new AuthService(db);

        bool ok = svc.Verify("ghost", "anypass", out User user);

        Assert.False(ok);
        Assert.Null(user);
    }

    [Fact]
    public void Verify_Case_Sensitive_Username()
    {
        using SchoolNotesDbContext db = NewDb();
        AuthService svc = new AuthService(db);
        svc.Register("Admin", "password123");

        bool ok = svc.Verify("admin", "password123", out User user);

        Assert.False(ok);
        Assert.Null(user);
    }
}
