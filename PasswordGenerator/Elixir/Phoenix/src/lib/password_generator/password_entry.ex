defmodule PasswordGenerator.PasswordEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "password_entries" do
    field :password, :string
    field :length, :integer, default: 16

    timestamps()
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:password, :length])
    |> validate_required(:password, message: "Password is required")
  end

  def to_dto(%__MODULE__{} = entry) do
    %{id: entry.id, password: entry.password, length: entry.length}
  end
end
