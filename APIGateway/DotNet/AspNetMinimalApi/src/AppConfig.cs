using System;
using System.Collections.Generic;

static class AppConfig
{
    public static string JwtSecret =>
        Environment.GetEnvironmentVariable("JWT_SECRET") ?? "dev-secret-change-in-production";

    public static int RateLimitDefault =>
        int.TryParse(Environment.GetEnvironmentVariable("RATE_LIMIT_DEFAULT"), out int d) ? d : 100;

    public static int RateLimitWindow =>
        int.TryParse(Environment.GetEnvironmentVariable("RATE_LIMIT_WINDOW"), out int w) ? w : 60;

    public static string UsersServiceUrl =>
        Environment.GetEnvironmentVariable("USERS_SERVICE_URL") ?? "http://localhost:3001";

    public static string OrdersServiceUrl =>
        Environment.GetEnvironmentVariable("ORDERS_SERVICE_URL") ?? "http://localhost:3002";

    public static string ProductsServiceUrl =>
        Environment.GetEnvironmentVariable("PRODUCTS_SERVICE_URL") ?? "http://localhost:3003";

    public static int UsersLimit => int.TryParse(Environment.GetEnvironmentVariable("USERS_LIMIT"), out int v) ? v : 50;
    public static int OrdersLimit => int.TryParse(Environment.GetEnvironmentVariable("ORDERS_LIMIT"), out int v) ? v : 30;
    public static int ProductsLimit => int.TryParse(Environment.GetEnvironmentVariable("PRODUCTS_LIMIT"), out int v) ? v : 100;
}