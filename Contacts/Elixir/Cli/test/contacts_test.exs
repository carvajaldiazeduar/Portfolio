defmodule ContactsTest do
  use ExUnit.Case, async: true

  import Contacts

  describe "validate/3" do
    test "accepts valid contacts" do
      assert validate("Alice Smith", "+1 555-1234", "alice@example.com") == []
    end

    test "name is required" do
      assert validate("", "+1 555-1234", "alice@example.com") == ["Name is required"]
    end

    test "name must be 2-100 chars letters" do
      assert validate("A", "+1 555-1234", "alice@example.com") == [
               "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"
             ]
    end

    test "name rejects digits" do
      assert validate("Alice 123", "+1 555-1234", "alice@example.com") == [
               "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"
             ]
    end

    test "phone is required" do
      assert validate("Alice Smith", "", "alice@example.com") == ["Phone is required"]
    end

    test "phone too short" do
      assert validate("Alice Smith", "1234", "alice@example.com") == [
               "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"
             ]
    end

    test "email is required" do
      assert validate("Alice Smith", "+1 555-1234", "") == ["Email is required"]
    end

    test "invalid email format" do
      assert validate("Alice Smith", "+1 555-1234", "not-an-email") == [
               "Invalid email format"
             ]
    end
  end

  describe "create/4" do
    test "creates a contact with incremental ids" do
      assert {:ok, c1} = create([], "Alice", "+1 555-1234", "alice@example.com")
      assert {:ok, c2} = create([c1], "Bob", "+1 555-5678", "bob@example.com")
      assert c1.id == 1
      assert c2.id == 2
    end

    test "returns errors for invalid input" do
      assert {:error, ["Name is required"]} = create([], "", "+1 555-1234", "a@b.com")
    end
  end

  describe "search/2" do
    test "finds contacts by case-insensitive substring" do
      {:ok, c1} = create([], "Alice Smith", "+1 555-1234", "alice@example.com")
      assert search([c1], "ALICE") == [c1]
      assert search([c1], "zzz") == []
    end
  end

  describe "update/5" do
    test "updates an existing contact" do
      {:ok, c1} = create([], "Alice", "+1 555-1234", "alice@example.com")
      assert {:ok, updated} = update([c1], 1, "Alice Smith", "+1 555-0000", "alice@example.com")
      assert updated.id == 1
      assert updated.phone == "+1 555-0000"
    end

    test "returns not_found for unknown id" do
      assert {:error, :not_found} = update([], 99, "A", "B", "c@d.com")
    end
  end

  describe "delete/2" do
    test "deletes an existing contact" do
      {:ok, c1} = create([], "Alice", "+1 555-1234", "alice@example.com")
      assert {:ok, ^c1} = delete([c1], 1)
    end

    test "returns not_found for unknown id" do
      assert {:error, :not_found} = delete([], 99)
    end
  end
end