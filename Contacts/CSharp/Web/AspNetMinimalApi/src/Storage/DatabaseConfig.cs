using Microsoft.EntityFrameworkCore;
using Pomelo.EntityFrameworkCore.MySql.Infrastructure;

public static class DatabaseConfig
{
    public static string ConnectionString(string driver, string dbName)
    {
        var host = Env("DB_HOST", "db");
        var port = Env("DB_PORT", "5432");
        var user = Env("DB_USER", "postgres");
        var pass = Env("DB_PASSWORD", "postgres");
        var file = Env("DB_FILE", $"{dbName}.db");
        return driver switch
        {
            "postgresql" or "postgres" or "pgsql" => $"Host={host};Port={port};Database={dbName};Username={user};Password={pass}",
            "mysql" => $"Server={host};Port={port};Database={dbName};User={user};Password={pass}",
            "sqlite" => $"Data Source={file}",
            "sqlserver" or "mssql" => $"Server={host},{port};Database={dbName};User Id={user};Password={pass};TrustServerCertificate=True",
            "mongodb" => $"mongodb://{user}:{pass}@{host}:{port}",
            _ => throw new NotSupportedException($"Database driver '{driver}' is not supported")
        };
    }

    public static void Configure(DbContextOptionsBuilder options, string driver, string dbName)
    {
        var conn = ConnectionString(driver, dbName);
        switch (driver)
        {
            case "postgresql" or "postgres" or "pgsql":
                options.UseNpgsql(conn);
                break;
            case "mysql":
                options.UseMySql(conn, ServerVersion.Create(new Version(8, 0, 36), ServerType.MySql));
                break;
            case "sqlite":
                options.UseSqlite(conn);
                break;
            case "sqlserver" or "mssql":
                options.UseSqlServer(conn);
                break;
            case "mongodb":
                options.UseMongoDB(conn, dbName);
                break;
            default:
                throw new NotSupportedException($"Database driver '{driver}' is not supported");
        }
    }

    private static string Env(string key, string fallback) =>
        Environment.GetEnvironmentVariable(key) ?? fallback;
}
