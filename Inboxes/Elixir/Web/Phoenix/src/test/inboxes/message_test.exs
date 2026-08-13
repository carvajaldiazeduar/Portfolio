defmodule Inboxes.ContactTest do
  use Inboxes.DataCase, async: true

  alias Inboxes.Contact

  test "valid contact is saved" do
    changeset = Contact.changeset(%Contact{}, %{name: "Alice Smith", phone: "+1 555 1234", email: "alice@example.com"})
    assert changeset.valid?
  end

  test "name is required" do
    changeset = Contact.changeset(%Contact{}, %{name: "", phone: "5551234", email: "a@b.com"})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{name: "Name is required"}
  end

  test "name too short" do
    changeset = Contact.changeset(%Contact{}, %{name: "A", phone: "5551234", email: "a@b.com"})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{name: "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"}
  end

  test "name with invalid characters" do
    changeset = Contact.changeset(%Contact{}, %{name: "Alice123", phone: "5551234", email: "a@b.com"})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{name: "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"}
  end

  test "phone is required" do
    changeset = Contact.changeset(%Contact{}, %{name: "Alice", phone: "   ", email: "a@b.com"})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{phone: "Phone is required"}
  end

  test "phone invalid format" do
    changeset = Contact.changeset(%Contact{}, %{name: "Alice", phone: "abc", email: "a@b.com"})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{phone: "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"}
  end

  test "email is required" do
    changeset = Contact.changeset(%Contact{}, %{name: "Alice", phone: "5551234", email: ""})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{email: "Email is required"}
  end

  test "email invalid format" do
    changeset = Contact.changeset(%Contact{}, %{name: "Alice", phone: "5551234", email: "not-an-email"})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{email: "Invalid email format"}
  end

  test "whitespace treated as missing" do
    changeset = Contact.changeset(%Contact{}, %{name: "   ", phone: "5551234", email: "a@b.com"})
    refute changeset.valid?
    assert Contact.error_map(changeset) == %{name: "Name is required"}
  end
end