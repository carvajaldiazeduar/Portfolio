defmodule Inboxes.MessagesServiceTest do
  use Inboxes.DataCase, async: true

  alias Inboxes.{Message, MessagesService, Repo}

  setup do
    Inboxes.Cache.delete("messages:all")
    :ok
  end

  test "creates a message" do
    assert {:ok, message} = MessagesService.create(%{sender: "Alice", subject: "Hello", body: "Hi there"})
    assert message.sender == "Alice"
    assert message.subject == "Hello"
  end

  test "create validates fields" do
    assert {:error, %{sender: "Sender is required"}} =
             MessagesService.create(%{sender: "", subject: "Hello", body: "Hi"})
  end

  test "lists all messages" do
    {:ok, _} = MessagesService.create(%{sender: "Alice", subject: "Hello", body: "Hi"})
    {:ok, _} = MessagesService.create(%{sender: "Bob", subject: "World", body: "Hey"})
    assert length(MessagesService.list_all()) == 2
  end

  test "list is cached" do
    {:ok, _message} = MessagesService.create(%{sender: "Alice", subject: "Hello", body: "Hi"})
    assert [_] = MessagesService.list_all()
    assert {:ok, cached} = Inboxes.Cache.get("messages:all")
    assert is_list(cached)
    assert length(cached) == 1
  end

  test "shows one message and marks it read" do
    {:ok, message} = MessagesService.create(%{sender: "Alice", subject: "Hello", body: "Hi"})
    assert {:ok, found} = MessagesService.show(message.id)
    assert found.sender == "Alice"
    assert found.read == true
  end

  test "show caches single message" do
    {:ok, message} = MessagesService.create(%{sender: "Alice", subject: "Hello", body: "Hi"})
    assert {:ok, _} = MessagesService.show(message.id)
    assert {:ok, cached} = Inboxes.Cache.get("message:#{message.id}")
    assert cached.from == "Alice"
  end

  test "show missing returns error" do
    assert MessagesService.show(999_999) == :error
  end

  test "deletes a message" do
    {:ok, message} = MessagesService.create(%{sender: "Alice", subject: "Hello", body: "Hi"})
    assert {:ok, _} = MessagesService.delete(message.id)
    assert Repo.get(Message, message.id) == nil
  end

  test "delete missing returns not found" do
    assert MessagesService.delete(999_999) == {:error, :not_found}
  end
end