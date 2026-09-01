using Microsoft.EntityFrameworkCore;

static class DatabaseConfig
{
    public static void Apply(DbContextOptionsBuilder builder)
    {
        string driver = Environment.GetEnvironmentVariable("DB_DRIVER") ?? "pgsql";
        string connection = ConnectionString(driver);

        switch (driver)
        {
            case "pgsql":
                builder.UseNpgsql(connection);
                break;
            case "mysql":
                // Use ServerVersion.AutoDetect to let Pomelo detect the server version at runtime
                // and avoid hardcoding a specific MySQL version.
                builder.UseMySql(connection, ServerVersion.AutoDetect(connection));
                break;
            case "sqlserver":
                builder.UseSqlServer(connection);
                break;
            case "sqlite":
                builder.UseSqlite(connection);
                break;
            case "mongodb":
                builder.UseMongoDB(
                    Environment.GetEnvironmentVariable("DB_HOST") ?? "mongodb://localhost:27017",
                    Environment.GetEnvironmentVariable("DB_NAME") ?? "schoolnotes");
                break;
            default:
                builder.UseNpgsql(connection);
                break;
        }
    }

    static string ConnectionString(string driver)
    {
        string host = Environment.GetEnvironmentVariable("DB_HOST") ?? "localhost";
        string port = Environment.GetEnvironmentVariable("DB_PORT");
        string name = Environment.GetEnvironmentVariable("DB_NAME") ?? "schoolnotes";
        string user = Environment.GetEnvironmentVariable("DB_USER");
        string pass = Environment.GetEnvironmentVariable("DB_PASSWORD");
        string file = Environment.GetEnvironmentVariable("DB_FILE");

        switch (driver)
        {
            case "pgsql":
                port = port ?? "5432";
                return $"Host={host};Port={port};Database={name};Username={user};Password={pass}";
            case "mysql":
                port = port ?? "3306";
                return $"server={host};port={port};database={name};user={user};password={pass}";
            case "sqlserver":
                port = port ?? "1433";
                return $"Server={host},{port};Database={name};User Id={user};Password={pass};TrustServerCertificate=True";
            case "sqlite":
                return $"Data Source={file ?? "schoolnotes.db"}";
            default:
                return "";
        }
    }
}
