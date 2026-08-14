defmodule PasswordGenerator.PasswordEntryTest do
  use PasswordGenerator.DataCase, async: true

  alias PasswordGenerator.PasswordEntry

  test "valid entry is saved" do
    changeset = PasswordEntry.changeset(%PasswordEntry{}, %{password: "Abcd1234!", length: 9})
    assert changeset.valid?
  end

  test "password is required" do
    changeset = PasswordEntry.changeset(%PasswordEntry{}, %{password: "", length: 16})
    refute changeset.valid?
    assert PasswordEntry.error_map(changeset) == %{password: "Password is required"}
  end

  test "default length is 16" do
    {:ok, entry} =
      PasswordGenerator.Repo.insert(PasswordEntry.changeset(%PasswordEntry{}, %{password: "x"}))

    assert entry.length == 16
  end

  test "whitespace treated as missing" do
    changeset = PasswordEntry.changeset(%PasswordEntry{}, %{password: "   "})
    refute changeset.valid?
    assert PasswordEntry.error_map(changeset) == %{password: "Password is required"}
  end
end