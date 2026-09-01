ExUnit.start()

# Run pending migrations before tests
Ecto.Migrator.with_repo(Inboxes.Repo, fn repo ->
  Ecto.Migrator.run(repo, Ecto.Migrator.migrations_path(repo), :up, all: true)
end)

Ecto.Adapters.SQL.Sandbox.mode(Inboxes.Repo, :manual)
