defmodule PasswordGenerator.PasswordEntry do
  @moduledoc """
  Stored password entry: the generated password and its length.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :password, :length]}

  schema "password_entries" do
    field :password, :string
    field :length, :integer, default: 16

    timestamps()
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:password, :length], trim: true)
    |> validate_required([:password], message: "is required", trim: true)
  end

  def error_map(changeset) do
    Enum.reduce(changeset.errors, %{}, fn {field, {message, _opts}}, acc ->
      Map.put(acc, field, error_message(field, message))
    end)
  end

  defp error_message(_field, "is required"), do: "Password is required"
end