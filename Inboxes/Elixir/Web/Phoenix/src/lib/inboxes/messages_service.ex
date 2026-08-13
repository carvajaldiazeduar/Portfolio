defmodule Inboxes.MessagesService do
  @moduledoc """
  Service layer for inboxes: cache-first reads with DB fallback.
  Writes invalidate the relevant cache keys.

  Cache keys: `messages:all` (list) and `message:{id}` (single).
  """

  alias Inboxes.{Cache, Message, Repo}
  import Ecto.Query

  def list_all(ttl \\ default_ttl()) do
    case Cache.get("messages:all") do
      {:ok, messages} -> messages
      :error ->
        messages = Repo.all(from m in Message, order_by: m.id)
        Cache.set("messages:all", Enum.map(messages, &Message.to_dto/1), ttl)
        messages
    end
  end

  def show(id) do
    case Repo.get(Message, id) do
      nil ->
        :error

      message ->
        message
        |> Ecto.Changeset.change(read: true)
        |> Repo.update!()

        Cache.set("message:#{id}", Message.to_dto(message), default_ttl())
        invalidate_list()
        {:ok, message}
    end
  end

  def create(attrs) do
    changeset = Message.changeset(%Message{}, attrs)

    if changeset.valid? do
      case Repo.insert(changeset) do
        {:ok, message} ->
          invalidate_list()
          {:ok, message}

        {:error, changeset} ->
          {:error, Message.error_map(changeset)}
      end
    else
      {:error, Message.error_map(changeset)}
    end
  end

  def delete(id) do
    case Repo.get(Message, id) do
      nil ->
        {:error, :not_found}

      message ->
        Repo.delete(message)
        invalidate_list()
        Cache.delete("message:#{id}")
        {:ok, message}
    end
  end

  defp invalidate_list do
    Cache.delete("messages:all")
  end

  defp default_ttl do
    Application.get_env(:inboxes, :cache_ttl, 300)
  end
end