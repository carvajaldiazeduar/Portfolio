defmodule TasksList.RepoAdapter do
  @moduledoc """
  Resolves the Ecto adapter module from the `DB_DRIVER` env var.
  Ecto requires the adapter at compile time, so this must be a
  plain function call, not read from runtime config.
  """

  def resolve do
    default = if Mix.env() == :test, do: "sqlite", else: "pgsql"

    case System.get_env("DB_DRIVER", default) do
      "sqlite" -> Ecto.Adapters.SQLite3
      "mysql" -> Ecto.Adapters.MyXQL
      "mongodb" -> Mongo.Ecto
      "sqlserver" -> Ecto.Adapters.Tds
      _ -> Ecto.Adapters.Postgres
    end
  end
end
