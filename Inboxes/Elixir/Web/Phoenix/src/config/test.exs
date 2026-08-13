import Config

# Test config selects the adapter via DB_DRIVER (compile-time for the Repo).
# Defaults to SQLite with a test file so tests run without a server.
db_driver = System.get_env("DB_DRIVER", "sqlite")

repo_conf =
  case db_driver do
    "mysql" ->
      [hostname: System.get_env("DB_HOST", "localhost"), port: String.to_integer(System.get_env("DB_PORT", "3306")), username: System.get_env("DB_USER", "root"), password: System.get_env("DB_PASSWORD", ""), database: System.get_env("DB_NAME", "contacts_test")]

    "sqlserver" ->
      [hostname: System.get_env("DB_HOST", "localhost"), port: String.to_integer(System.get_env("DB_PORT", "1433")), username: System.get_env("DB_USER", "sa"), password: System.get_env("DB_PASSWORD", ""), database: System.get_env("DB_NAME", "contacts_test")]

    "mongodb" ->
      [url: System.get_env("DATABASE_URL", "mongodb://localhost:27017/contacts_test")]

    "pgsql" ->
      [hostname: System.get_env("DB_HOST", "localhost"), port: String.to_integer(System.get_env("DB_PORT", "5432")), username: System.get_env("DB_USER", "postgres"), password: System.get_env("DB_PASSWORD", "postgres"), database: System.get_env("DB_NAME", "contacts_test")]

    _ ->
      [database: System.get_env("DB_FILE", "test.db")]
  end

config :inboxes, Contacts.Repo,
  Keyword.merge(repo_conf, pool: Ecto.Adapters.SQL.Sandbox, pool_size: 10)

config :inboxes, :cache_type, System.get_env("CACHE_TYPE", "local")
config :inboxes, :redis_host, System.get_env("REDIS_HOST", "localhost:6379")
config :inboxes, :cache_ttl, String.to_integer(System.get_env("CACHE_TTL", "300"))

config :inboxes, InboxesWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "mCIqQX8G9t8SCCCSctpw4/WNucDi8t36MeOsDU8VVsyCw4uu419nTNYQSxCVcVM+",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
config :phoenix, sort_verified_routes_query_params: true