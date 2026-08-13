defmodule Inboxes.Message do
  @moduledoc """
  Inbox message: sender, subject, body and read/unread state.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :sender, :string
    field :subject, :string
    field :body, :string, default: ""
    field :read, :boolean, default: false

    timestamps()
  end

  @doc "Serializes a message using the canonical API shape (sender exposed as `from`)."
  def to_dto(%__MODULE__{} = m) do
    %{
      id: m.id,
      from: m.sender,
      subject: m.subject,
      body: m.body,
      read: m.read,
      created_at: format_ts(m.inserted_at)
    }
  end

  defp format_ts(nil), do: nil

  defp format_ts(ts) do
    ts
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender, :subject, :body, :read], trim: true)
    |> validate_required([:sender, :subject, :body], message: "is required", trim: true)
    |> validate_length(:sender, min: 1, max: 255, message: "must be 1-255 characters")
    |> validate_length(:subject, min: 1, max: 300, message: "must be 1-300 characters")
    |> validate_length(:body, min: 1, max: 1000, message: "must be 1-1000 characters")
  end

  def error_map(changeset) do
    Enum.reduce(changeset.errors, %{}, fn {field, {message, _opts}}, acc ->
      Map.put(acc, field, error_message(field, message))
    end)
  end

  defp error_message(field, "is required") do
    "#{field |> Atom.to_string() |> String.capitalize()} is required"
  end

  defp error_message(:sender, _), do: "From must be 1-255 characters"
  defp error_message(:subject, _), do: "Subject must be 1-300 characters"
  defp error_message(:body, _), do: "Body must be 1-1000 characters"
end