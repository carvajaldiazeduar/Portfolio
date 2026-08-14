defmodule PasswordGenerator.Repo.Migrations.CreatePasswordEntries do
  use Ecto.Migration

  def change do
    create table(:password_entries) do
      add :password, :string, null: false
      add :length, :integer, default: 16

      timestamps()
    end
  end
end