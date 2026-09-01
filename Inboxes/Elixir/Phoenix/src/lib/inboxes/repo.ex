defmodule Inboxes.Repo do
  adapter =
    case System.get_env("DB_DRIVER", "sqlite") do
      "mysql" -> Ecto.Adapters.MyXQL
      "sqlserver" -> Ecto.Adapters.Tds
      "mongodb" -> Mongo.Ecto
      "pgsql" -> Ecto.Adapters.Postgres
      _ -> Ecto.Adapters.SQLite3
    end

  use Ecto.Repo, otp_app: :inboxes, adapter: adapter
end
