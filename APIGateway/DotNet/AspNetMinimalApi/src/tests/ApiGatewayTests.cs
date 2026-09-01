using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Xunit;

namespace ApiGateway.Tests;

public class AuthServiceTests
{
    [Fact]
    public void Login_Admin_Returns_Token_And_One_Hour_Expiry()
    {
        dynamic result = AuthService.Login("admin", "admin");
        Assert.NotNull(result);
        Assert.False(string.IsNullOrEmpty((string)result.token));
        Assert.Equal("1h", (string)result.expiresIn);

        Dictionary<string, object> payload = JwtUtil.Verify((string)result.token, AppConfig.JwtSecret);
        Assert.NotNull(payload);
        JsonElement id = (JsonElement)payload["id"];
        Assert.Equal(1, id.GetInt32());
        Assert.Equal("admin", ((JsonElement)payload["username"]).GetString());
    }

    [Fact]
    public void Login_User_Returns_Token_With_User_Role()
    {
        dynamic result = AuthService.Login("user", "user");
        Assert.NotNull(result);
        Assert.Equal("1h", (string)result.expiresIn);

        Dictionary<string, object> payload = JwtUtil.Verify((string)result.token, AppConfig.JwtSecret);
        Assert.NotNull(payload);
        JsonElement id = (JsonElement)payload["id"];
        Assert.Equal(2, id.GetInt32());
        Assert.Equal("user", ((JsonElement)payload["username"]).GetString());
    }

    [Fact]
    public void Login_Wrong_Credentials_Returns_Null()
    {
        Assert.Null(AuthService.Login("admin", "wrong"));
        Assert.Null(AuthService.Login("ghost", "admin"));
    }

    [Fact]
    public void Login_Missing_Credentials_Returns_Null()
    {
        Assert.Null(AuthService.Login(null, "admin"));
        Assert.Null(AuthService.Login("admin", null));
        Assert.Null(AuthService.Login("", ""));
    }
}

public class JwtUtilTests
{
    private const string Secret = "test-secret-key";

    [Fact]
    public void Sign_And_Verify_Roundtrip()
    {
        Dictionary<string, object> payload = new()
        {
            ["username"] = "admin",
            ["exp"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds() + 3600
        };

        string token = JwtUtil.Sign(payload, Secret);
        Dictionary<string, object> verified = JwtUtil.Verify(token, Secret);

        Assert.NotNull(verified);
        Assert.Equal("admin", ((JsonElement)verified["username"]).GetString());
    }

    [Fact]
    public void Verify_Expired_Token_Returns_Null()
    {
        Dictionary<string, object> payload = new()
        {
            ["username"] = "admin",
            ["exp"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds() - 100
        };

        string token = JwtUtil.Sign(payload, Secret);
        Assert.Null(JwtUtil.Verify(token, Secret));
    }

    [Fact]
    public void Verify_Wrong_Secret_Returns_Null()
    {
        Dictionary<string, object> payload = new() { ["username"] = "admin" };
        string token = JwtUtil.Sign(payload, "other-secret");
        Assert.Null(JwtUtil.Verify(token, Secret));
    }

    [Fact]
    public void Verify_Garbage_Returns_Null()
    {
        Assert.Null(JwtUtil.Verify("not-a-jwt", Secret));
        Assert.Null(JwtUtil.Verify("a.b", Secret));
        Assert.Null(JwtUtil.Verify("", Secret));
    }

    [Fact]
    public void Token_Has_Three_Parts()
    {
        Dictionary<string, object> payload = new() { ["username"] = "admin" };
        string token = JwtUtil.Sign(payload, Secret);
        Assert.Equal(3, token.Split('.').Length);
    }
}

public class LocalCacheTests
{
    [Fact]
    public async Task Set_And_Get_Returns_Value()
    {
        LocalCache cache = new();
        await cache.SetAsync("key:1", "value", 60);
        Assert.Equal("value", await cache.GetAsync("key:1"));
    }

    [Fact]
    public async Task Get_Missing_Returns_Null()
    {
        LocalCache cache = new();
        Assert.Null(await cache.GetAsync("missing"));
    }

    [Fact]
    public async Task Increment_Counts_Up()
    {
        LocalCache cache = new();
        Assert.Equal(1, await cache.IncrementAsync("rl:ip", 60));
        Assert.Equal(2, await cache.IncrementAsync("rl:ip", 60));
        Assert.Equal(3, await cache.IncrementAsync("rl:ip", 60));
    }

    [Fact]
    public async Task Remove_Deletes_Entry()
    {
        LocalCache cache = new();
        await cache.SetAsync("key:1", "value", 60);
        await cache.RemoveAsync("key:1");
        Assert.Null(await cache.GetAsync("key:1"));
    }

    [Fact]
    public async Task Clear_Empties_Store()
    {
        LocalCache cache = new();
        await cache.SetAsync("a", "1", 60);
        await cache.SetAsync("b", "2", 60);
        await cache.ClearAsync();
        Assert.Null(await cache.GetAsync("a"));
        Assert.Null(await cache.GetAsync("b"));
    }

    [Fact]
    public async Task Expired_Entry_Returns_Null()
    {
        LocalCache cache = new();
        await cache.SetAsync("key:1", "value", -1);
        Assert.Null(await cache.GetAsync("key:1"));
    }
}
