defmodule Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :phone, :email, :inserted_at, :updated_at]}
  schema "contacts" do
    field :name, :string
    field :phone, :string, default: ""
    field :email, :string, default: ""

    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :phone, :email], trim: true)
    |> validate_required([:name, :phone, :email], message: "is required", trim: true)
    |> validate_length(:name, min: 2, max: 100,
      message: "must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)")
    |> validate_format(:name, ~r/^[A-Za-zÀ-ÿ' .-]+$/,
      message: "must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)")
    |> validate_length(:phone, min: 7, max: 20,
      message: "must be 7-20 characters (digits, spaces, +, parentheses, dashes)")
    |> validate_format(:phone, ~r/^[0-9 +().-]+$/,
      message: "must be 7-20 characters (digits, spaces, +, parentheses, dashes)")
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/, message: "Invalid email format")
  end

  def error_map(changeset) do
    Enum.reduce(changeset.errors, %{}, fn {field, {message, _opts}}, acc ->
      Map.put(acc, field, error_message(field, message))
    end)
  end

  defp error_message(field, "is required") do
    "#{field |> Atom.to_string() |> String.capitalize()} is required"
  end

  defp error_message(:name, _), do: "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"
  defp error_message(:phone, _), do: "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"
  defp error_message(:email, _), do: "Invalid email format"
end
