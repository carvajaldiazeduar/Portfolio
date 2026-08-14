import Config

port_for = fn
  "sqlite" -> "0"
  "mongodb" -> "27017"
  "mysql" -> "3306"
  "sqlserver" -> "1433"
  _ -> "5432"
end

driver = System.get_env("DB_DRIVER", "pgsql")
host = System.get_env("DB_HOST", "db")
port = System.get_env("DB_PORT", port_for.(driver))
name = System.get_env("DB_NAME", "contacts")
user = System.get_env("DB_USER", "postgres")
password = System.get_env("DB_PASSWORD", "postgres")
file = System.get_env("DB_FILE", "db.sqlite3")
pool_size = System.get_env("POOL_SIZE") || "10"

repo_opts =
  case driver do
    "sqlite" ->
      [adapter: Ecto.Adapters.SQLite3, database: file]

    "mysql" ->
      [
        adapter: Ecto.Adapters.MyXQL,
        hostname: host,
        port: String.to_integer(port),
        username: user,
        password: password,
        database: name
      ]

    "mongodb" ->
      [
        adapter: Mongo.Ecto,
        url: "mongodb://#{user}:#{password}@#{host}:#{port}/#{name}"
      ]

    "sqlserver" ->
      [
        adapter: Ecto.Adapters.Tds,
        hostname: host,
        port: String.to_integer(port),
        username: user,
        password: password,
        database: name
      ]

    _ ->
      [
        adapter: Ecto.Adapters.Postgres,
        hostname: host,
        port: String.to_integer(port),
        username: user,
        password: password,
        database: name
      ]
  end

config :contacts, Contacts.Repo, Keyword.put(repo_opts, :pool_size, String.to_integer(pool_size))

if System.get_env("PHX_SERVER") do
  config :contacts, ContactsWeb.Endpoint, server: true
end

config :contacts, ContactsWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :contacts, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :contacts, ContactsWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base
end