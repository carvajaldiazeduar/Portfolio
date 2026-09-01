using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Linq;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

string jwtSecret = Environment.GetEnvironmentVariable("JWT_SECRET") ?? "schoolnotes-development-jwt-secret-key-0123456789abcdef";

builder.Services.AddDbContextPool<SchoolNotesDbContext>((_, options) => DatabaseConfig.Apply(options));
builder.Services.AddAuthentication()
    .AddCookie(options => options.LoginPath = "/api/auth/login")
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ValidateIssuer = false,
            ValidateAudience = false
        };
    });

builder.Services.AddAuthorization(o =>
{
    o.DefaultPolicy = new AuthorizationPolicyBuilder(
        CookieAuthenticationDefaults.AuthenticationScheme,
        JwtBearerDefaults.AuthenticationScheme)
            .RequireAuthenticatedUser()
            .Build();
});

builder.Services.AddEndpointsApiExplorer();

// Register Swagger and add JWT Bearer security definition and requirement
builder.Services.AddSwaggerGen(options =>
{
    // Try to add security definition via reflection so we don't require a compile-time
    // dependency on Microsoft.OpenApi.Models types (fixes package/assembly mismatch issues).
    try
    {
        var asm = AppDomain.CurrentDomain.GetAssemblies()
            .FirstOrDefault(a => a.GetName().Name.Equals("Microsoft.OpenApi", StringComparison.OrdinalIgnoreCase));
        if (asm != null)
        {
            var schemeType = asm.GetType("Microsoft.OpenApi.Models.OpenApiSecurityScheme");
            var referenceType = asm.GetType("Microsoft.OpenApi.Models.OpenApiReference");
            var referenceEnumType = asm.GetType("Microsoft.OpenApi.Models.ReferenceType");
            var securityRequirementType = asm.GetType("Microsoft.OpenApi.Models.OpenApiSecurityRequirement") ??
                                          asm.GetType("Microsoft.OpenApi.OpenApiSecurityRequirement");

            if (schemeType != null && referenceType != null && securityRequirementType != null)
            {
                var scheme = Activator.CreateInstance(schemeType);
                schemeType.GetProperty("Name")?.SetValue(scheme, "Authorization");

                var securitySchemeEnum = asm.GetType("Microsoft.OpenApi.Models.SecuritySchemeType");
                if (securitySchemeEnum != null)
                {
                    var httpVal = Enum.Parse(securitySchemeEnum, "Http");
                    schemeType.GetProperty("Type")?.SetValue(scheme, httpVal);
                }

                schemeType.GetProperty("Scheme")?.SetValue(scheme, "Bearer");
                schemeType.GetProperty("BearerFormat")?.SetValue(scheme, "JWT");

                var paramLocType = asm.GetType("Microsoft.OpenApi.Models.ParameterLocation");
                if (paramLocType != null)
                {
                    var headerVal = Enum.Parse(paramLocType, "Header");
                    schemeType.GetProperty("In")?.SetValue(scheme, headerVal);
                }

                schemeType.GetProperty("Description")?.SetValue(scheme, "JWT issued by POST /api/auth/login. Format: Bearer {token}");

                var addSecDef = options.GetType().GetMethod("AddSecurityDefinition", new Type[] { typeof(string), schemeType });
                addSecDef?.Invoke(options, new object[] { "Bearer", scheme });

                var reference = Activator.CreateInstance(referenceType);
                referenceType.GetProperty("Type")?.SetValue(reference, Enum.Parse(referenceEnumType, "SecurityScheme"));
                referenceType.GetProperty("Id")?.SetValue(reference, "Bearer");

                var schemeRef = Activator.CreateInstance(schemeType);
                schemeType.GetProperty("Reference")?.SetValue(schemeRef, reference);

                var secReq = Activator.CreateInstance(securityRequirementType);
                var addMethod = securityRequirementType.GetMethod("Add", new Type[] { schemeType, typeof(IEnumerable<string>) });
                if (addMethod != null)
                {
                    addMethod.Invoke(secReq, new object[] { schemeRef, new string[0] });
                    var addSecReq = options.GetType().GetMethod("AddSecurityRequirement", new Type[] { securityRequirementType });
                    addSecReq?.Invoke(options, new object[] { secReq });
                }
            }
        }
    }
    catch
    {
        // If reflection fails, skip adding security definition to avoid build/runtime errors.
    }
});
builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());

string[] corsOrigins = (Environment.GetEnvironmentVariable("CORS_ORIGINS") ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries);

builder.Services.AddCors(options =>
{
    options.AddPolicy("SchoolNotesCors", policy =>
    {
        if (corsOrigins.Length > 0)
        {
            policy.WithOrigins(corsOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
        }
        else
        {
            policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
        }
    });
});

WebApplication app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("SchoolNotesCors");
app.UseAuthentication();
app.UseAuthorization();
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseRateLimit();

app.MapAuthEndpoints();
app.MapGroup("/api").RequireAuthorization().MapSchoolNotesEndpoints();

using (IServiceScope scope = app.Services.CreateScope())
{
    bool created = false;
    SchoolNotesDbContext db = scope.ServiceProvider.GetRequiredService<SchoolNotesDbContext>();

    for (int attempt = 1; attempt <= 10 && !created; attempt++)
    {
        try
        {
            db.Database.EnsureCreated();
            created = true;
        }
        catch
        {
            Thread.Sleep(2000);
        }
    }

    if (!created)
        db.Database.EnsureCreated();

    string adminUser = Environment.GetEnvironmentVariable("ADMIN_USERNAME") ?? "admin";
    string adminPass = Environment.GetEnvironmentVariable("ADMIN_PASSWORD") ?? "admin";

    if (!db.Users.Any(u => u.Username == adminUser))
        new AuthService(db).Register(adminUser, adminPass);
}

app.Run();
