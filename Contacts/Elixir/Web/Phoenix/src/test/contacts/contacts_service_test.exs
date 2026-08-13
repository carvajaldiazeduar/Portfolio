defmodule Contacts.ContactsServiceTest do
  use Contacts.DataCase, async: true

  alias Contacts.{ContactsService, Repo}

  setup do
    Contacts.Cache.delete("contacts:all")
    :ok
  end

  test "creates a contact" do
    assert {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "+1 555 1234", email: "alice@example.com"})
    assert contact.name == "Alice Smith"
  end

  test "create validates fields" do
    assert {:error, %{name: "Name is required"}} = ContactsService.create(%{name: "", phone: "5551234", email: "a@b.com"})
  end

  test "lists all contacts" do
    {:ok, _} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    {:ok, _} = ContactsService.create(%{name: "Bob Jones", phone: "5555678", email: "b@b.com"})
    assert length(ContactsService.list_all()) == 2
  end

  test "list is cached" do
    {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    id = contact.id
    assert [_] = ContactsService.list_all()
    assert {:ok, cached} = Contacts.Cache.get("contacts:all")
    assert [%{id: ^id}] = cached
  end

  test "shows one contact" do
    {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    assert {:ok, found} = ContactsService.show(contact.id)
    assert found.name == "Alice Smith"
  end

  test "show missing returns error" do
    assert ContactsService.show(999_999) == :error
  end

  test "updates a contact" do
    {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    assert {:ok, updated} = ContactsService.update(contact.id, %{name: "Alice Updated"})
    assert updated.name == "Alice Updated"
  end

  test "update missing returns not found" do
    assert ContactsService.update(999_999, %{name: "X"}) == {:error, :not_found}
  end

  test "deletes a contact" do
    {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    assert {:ok, _} = ContactsService.delete(contact.id)
    assert Repo.get(Contacts.Contact, contact.id) == nil
  end

  test "delete missing returns not found" do
    assert ContactsService.delete(999_999) == {:error, :not_found}
  end
end