defmodule Contacts.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :name, :string, null: false
      add :phone, :string, default: ""
      add :email, :string, default: ""

      timestamps()
    end
  end
end
