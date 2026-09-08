defmodule Inboxes.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :sender, :string
    field :subject, :string
    field :body, :string
    field :read, :boolean, default: false

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender, :subject, :body, :read])
    |> trim_fields()
    |> validate_required(:sender, message: "Sender is required")
    |> validate_required(:subject, message: "Subject is required")
    |> validate_required(:body, message: "Body is required")
    |> validate_bounds(:sender, 255, "From must be 1-255 characters")
    |> validate_bounds(:subject, 300, "Subject must be 1-300 characters")
    |> validate_bounds(:body, 1000, "Body must be 1-1000 characters")
  end

  def error_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
    |> Map.new(fn {field, [message | _]} -> {field, message} end)
  end

  def to_dto(%__MODULE__{} = message) do
    %{
      id: message.id,
      sender: message.sender,
      from: message.sender,
      subject: message.subject,
      body: message.body,
      read: message.read,
      created_at: message.inserted_at
    }
  end

  defp trim_fields(changeset) do
    Enum.reduce([:sender, :subject, :body], changeset, fn field, cs ->
      case get_change(cs, field) do
        nil -> cs
        value when is_binary(value) -> put_change(cs, field, String.trim(value))
        _ -> cs
      end
    end)
  end

  defp validate_bounds(changeset, field, max, message) do
    case get_change(changeset, field) do
      value when is_binary(value) and value != "" ->
        validate_length(changeset, field, min: 1, max: max, message: message)

      _ ->
        changeset
    end
  end
end