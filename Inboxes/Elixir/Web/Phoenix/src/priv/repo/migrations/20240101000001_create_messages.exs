defmodule Inboxes.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :sender, :string, null: false
      add :subject, :string, null: false
      add :body, :text, default: ""
      add :read, :boolean, default: false, null: false

      timestamps()
    end
  end
end