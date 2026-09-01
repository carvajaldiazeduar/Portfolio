using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/auth/login", async (HttpContext context, SchoolNotesDbContext db) =>
        {
            LoginInput input = await context.Request.ReadFromJsonAsync<LoginInput>();
            if (input == null || string.IsNullOrWhiteSpace(input.Username) || string.IsNullOrWhiteSpace(input.Password))
                return Results.BadRequest(new { error = "Username and password are required." });
            AuthService service = new AuthService(db);
            User user;
            if (!service.Verify(input.Username, input.Password, out user))
                return Results.Unauthorized();
            List<Claim> claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Role, user.Role)
            };
            ClaimsIdentity identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(identity));

            byte[] jwtSecret = Encoding.UTF8.GetBytes(Environment.GetEnvironmentVariable("JWT_SECRET") ?? "schoolnotes-development-jwt-secret-key-0123456789abcdef");
            string token = new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(
                claims: claims,
                expires: DateTime.UtcNow.AddHours(8),
                signingCredentials: new SigningCredentials(new SymmetricSecurityKey(jwtSecret), SecurityAlgorithms.HmacSha256)));

            return Results.Ok(new { ok = true, token });
        })
        .Accepts<LoginInput>("application/json");

        app.MapPost("/api/auth/logout", async (HttpContext context) =>
        {
            await context.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return Results.Ok(new { ok = true });
        });
    }
}

public class LoginInput
{
    public string Username { get; set; }
    public string Password { get; set; }
}
