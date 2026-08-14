defmodule Inboxes do
  @moduledoc """
  Inbox core: an in-memory message store with the canonical CLI behaviour.

  Mirrors the Ruby CLI:

  - `send_message(from, subject, body)` -> message struct with id/from/subject/body/read/created_at
  - `list_messages` -> all messages
  - `read_message(id)` -> marks as read
  - `delete_message(id)` -> removes by id

  Return style: `{:ok, message}` / `{:error, :not_found}`.
  """

  defstruct [:id, :from, :subject, :body, :read, :created_at]

  @type t :: %__MODULE__{
          id: pos_integer,
          from: String.t(),
          subject: String.t(),
          body: String.t(),
          read: boolean,
          created_at: String.t()
        }

  @spec send_message([t()], String.t(), String.t(), String.t()) :: {:ok, t()}
  def send_message(messages, from, subject, body) do
    id = (Enum.map(messages, & &1.id) |> Enum.max(fn -> 0 end)) + 1

    message = %__MODULE__{
      id: id,
      from: from,
      subject: subject,
      body: body,
      read: false,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {:ok, message}
  end

  @spec list_messages([t()]) :: [t()]
  def list_messages(messages), do: messages

  @spec read_message([t()], pos_integer) :: {:ok, t()} | {:error, :not_found}
  def read_message(messages, id) do
    case Enum.find(messages, &(&1.id == id)) do
      nil -> {:error, :not_found}
      message -> {:ok, %{message | read: true}}
    end
  end

  @spec delete_message([t()], pos_integer) :: {:ok, t()} | {:error, :not_found}
  def delete_message(messages, id) do
    case Enum.find(messages, &(&1.id == id)) do
      nil -> {:error, :not_found}
      message -> {:ok, message}
    end
  end
end