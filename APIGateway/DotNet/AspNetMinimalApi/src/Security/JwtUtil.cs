using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

static class JwtUtil
{
    public static string Sign(Dictionary<string, object> payload, string secret)
    {
        Dictionary<string, object> header = new() { ["alg"] = "HS256", ["typ"] = "JWT" };
        string signingInput = Base64UrlEncode(JsonSerializer.Serialize(header))
            + "." + Base64UrlEncode(JsonSerializer.Serialize(payload));
        return signingInput + "." + Hmac(signingInput, secret);
    }

    public static Dictionary<string, object> Verify(string token, string secret)
    {
        string[] parts = token.Split('.');
        if (parts.Length != 3)
            return null;
        string signingInput = parts[0] + "." + parts[1];
        string expected = Hmac(signingInput, secret);
        if (!ConstantTimeEquals(expected, parts[2]))
            return null;

        try
        {
            string json = Encoding.UTF8.GetString(Base64UrlDecode(parts[1]));
            Dictionary<string, object> payload = JsonSerializer.Deserialize<Dictionary<string, object>>(json);
            if (payload != null && payload.TryGetValue("exp", out object exp) && exp is JsonElement el)
            {
                long expSec = el.ValueKind == JsonValueKind.Number
                    ? el.GetInt64()
                    : long.TryParse(el.ToString(), out long parsed) ? parsed : 0;
                if (expSec > 0 && DateTimeOffset.UtcNow.ToUnixTimeSeconds() > expSec)
                    return null;
            }
            return payload;
        }
        catch
        {
            return null;
        }
    }

    private static string Base64UrlEncode(string data) =>
        Base64UrlEncode(Encoding.UTF8.GetBytes(data));

    private static string Base64UrlEncode(byte[] bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    private static byte[] Base64UrlDecode(string data)
    {
        string padded = data.Replace('-', '+').Replace('_', '/');
        padded += new string('=', (4 - padded.Length % 4) % 4);
        return Convert.FromBase64String(padded);
    }

    private static string Hmac(string data, string secret)
    {
        using HMACSHA256 mac = new(Encoding.UTF8.GetBytes(secret));
        return Base64UrlEncode(mac.ComputeHash(Encoding.UTF8.GetBytes(data)));
    }

    private static bool ConstantTimeEquals(string a, string b)
    {
        if (a.Length != b.Length)
            return false;
        int result = 0;
        for (int i = 0; i < a.Length; i++)
            result |= a[i] ^ b[i];
        return result == 0;
    }
}