defmodule InboxesTest do
  use ExUnit.Case, async: true

  alias Inboxes

  test "send_message creates an unread message" do
    assert {:ok, m} = Inboxes.send_message([], "Alice", "Hello", "Hi there")
    assert m.id == 1
    assert m.from == "Alice"
    assert m.subject == "Hello"
    assert m.body == "Hi there"
    assert m.read == false
    assert m.created_at != nil
  end

  test "send_message increments ids" do
    {:ok, m1} = Inboxes.send_message([], "Alice", "Hello", "Hi")
    {:ok, m2} = Inboxes.send_message([m1], "Bob", "World", "Hey")
    assert m1.id == 1
    assert m2.id == 2
  end

  test "list_messages returns all" do
    {:ok, m1} = Inboxes.send_message([], "Alice", "Hello", "Hi")
    {:ok, m2} = Inboxes.send_message([m1], "Bob", "World", "Hey")
    assert Inboxes.list_messages([m1, m2]) == [m1, m2]
  end

  test "read_message marks as read" do
    {:ok, m} = Inboxes.send_message([], "Alice", "Hello", "Hi")
    assert {:ok, read} = Inboxes.read_message([m], 1)
    assert read.read == true
  end

  test "read_message missing returns not_found" do
    assert Inboxes.read_message([], 99) == {:error, :not_found}
  end

  test "delete_message removes by id" do
    {:ok, m} = Inboxes.send_message([], "Alice", "Hello", "Hi")
    assert {:ok, ^m} = Inboxes.delete_message([m], 1)
  end

  test "delete_message missing returns not_found" do
    assert Inboxes.delete_message([], 99) == {:error, :not_found}
  end
end