defmodule Inboxes.MessagesServiceTest do
  use Inboxes.DataCase, async: true

  alias Inboxes.{MessagesService, Repo}

  setup do
    Inboxes.Cache.delete("inboxes:all")
    :ok
  end

  test "creates a contact" do
    assert {:ok, contact} = MessagesService.create(%{name: "Alice Smith", phone: "+1 555 1234", email: "alice@example.com"})
    assert contact.name == "Alice Smith"
  end

  test "create validates fields" do
    assert {:error, %{name: "Name is required"}} = MessagesService.create(%{name: "", phone: "5551234", email: "a@b.com"})
  end

  test "lists all contacts" do
    {:ok, _} = MessagesService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    {:ok, _} = MessagesService.create(%{name: "Bob Jones", phone: "5555678", email: "b@b.com"})
    assert length(MessagesService.list_all()) == 2
  end

  test "list is cached" do
    {:ok, contact} = MessagesService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    id = contact.id
    assert [_] = MessagesService.list_all()
    assert {:ok, cached} = Inboxes.Cache.get("inboxes:all")
    assert [%{id: ^id}] = cached
  end

  test "shows one contact" do
    {:ok, contact} = MessagesService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    assert {:ok, found} = MessagesService.show(contact.id)
    assert found.name == "Alice Smith"
  end

  test "show missing returns error" do
    assert MessagesService.show(999_999) == :error
  end

  test "updates a contact" do
    {:ok, contact} = MessagesService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    assert {:ok, updated} = MessagesService.update(contact.id, %{name: "Alice Updated"})
    assert updated.name == "Alice Updated"
  end

  test "update missing returns not found" do
    assert MessagesService.update(999_999, %{name: "X"}) == {:error, :not_found}
  end

  test "deletes a contact" do
    {:ok, contact} = MessagesService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    assert {:ok, _} = MessagesService.delete(contact.id)
    assert Repo.get(Inboxes.Contact, contact.id) == nil
  end

  test "delete missing returns not found" do
    assert MessagesService.delete(999_999) == {:error, :not_found}
  end
end