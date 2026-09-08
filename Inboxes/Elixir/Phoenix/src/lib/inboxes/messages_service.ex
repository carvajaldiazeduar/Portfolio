defmodule Inboxes.MessagesService do
  import Ecto.Query

  alias Inboxes.{Cache, Message, Repo}

  def list_all do
    case Cache.get("messages:all") do
      nil ->
        messages = Repo.all(from message in Message, order_by: [desc: message.inserted_at])
        Cache.put("messages:all", messages)

      {:ok, messages} ->
        messages
    end
  end

  def create(attrs) do
    changeset = Message.changeset(%Message{}, attrs)

    case Repo.insert(changeset) do
      {:ok, message} ->
        Cache.delete("messages:all")
        {:ok, message}

      {:error, changeset} ->
        {:error, Message.error_map(changeset)}
    end
  end

  def show(id) do
    case Repo.get(Message, id) do
      nil ->
        :error

      %Message{read: false} = message ->
        {:ok, message} = message |> Message.changeset(%{read: true}) |> Repo.update()
        Cache.delete("messages:all")
        Cache.put("message:#{id}", Message.to_dto(message))
        {:ok, message}

      message ->
        Cache.put("message:#{id}", Message.to_dto(message))
        {:ok, message}
    end
  end

  def delete(id) do
    case Repo.get(Message, id) do
      nil ->
        {:error, :not_found}

      message ->
        case Repo.delete(message) do
          {:ok, deleted} ->
            Cache.delete("messages:all")
            {:ok, deleted}

          error ->
            error
        end
    end
  end
end