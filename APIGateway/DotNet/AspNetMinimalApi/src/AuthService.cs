using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;

static class AuthService
{
    private sealed record UserInfo(int Id, string Username, string[] Roles, string Password);

    private static readonly Dictionary<string, UserInfo> Users = new(StringComparer.Ordinal)
    {
        ["admin"] = new UserInfo(1, "admin", new[] { "admin" }, "admin"),
        ["user"] = new UserInfo(2, "user", new[] { "user" }, "user"),
    };

    public static object Login(string username, string password)
    {
        if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            return null;
        if (Users.TryGetValue(username, out UserInfo u) && u.Password == password)
        {
            return new
            {
                token = IssueToken(u),
                expiresIn = "1h"
            };
        }
        return null;
    }

    private static string IssueToken(UserInfo u)
    {
        long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        Dictionary<string, object> payload = new()
        {
            ["id"] = u.Id,
            ["username"] = u.Username,
            ["roles"] = u.Roles,
            ["exp"] = now + 3600
        };
        return JwtUtil.Sign(payload, AppConfig.JwtSecret);
    }
}