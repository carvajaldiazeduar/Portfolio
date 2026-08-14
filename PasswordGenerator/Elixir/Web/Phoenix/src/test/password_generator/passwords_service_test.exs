defmodule PasswordGenerator.PasswordsServiceTest do
  use PasswordGenerator.DataCase, async: true

  alias PasswordGenerator.{PasswordEntry, PasswordsService, Repo}

  setup do
    PasswordGenerator.Cache.delete("passwords:all")
    :ok
  end

  test "creates a stored password" do
    assert {:ok, entry} = PasswordsService.create(%{password: "Abcd1234!"})
    assert entry.password == "Abcd1234!"
  end

  test "create validates password" do
    assert {:error, %{password: "Password is required"}} = PasswordsService.create(%{password: ""})
  end

  test "lists all stored passwords" do
    {:ok, _} = PasswordsService.create(%{password: "Abcd1234!"})
    {:ok, _} = PasswordsService.create(%{password: "Xyzw9876#"})
    assert length(PasswordsService.list_all()) == 2
  end

  test "list is cached" do
    {:ok, _entry} = PasswordsService.create(%{password: "Abcd1234!"})
    assert [_] = PasswordsService.list_all()
    assert {:ok, cached} = PasswordGenerator.Cache.get("passwords:all")
    assert is_list(cached)
    assert length(cached) == 1
  end

  test "deletes a stored password" do
    {:ok, entry} = PasswordsService.create(%{password: "Abcd1234!"})
    assert {:ok, _} = PasswordsService.delete(entry.id)
    assert Repo.get(PasswordEntry, entry.id) == nil
  end

  test "delete missing returns not found" do
    assert PasswordsService.delete(999_999) == {:error, :not_found}
  end
end