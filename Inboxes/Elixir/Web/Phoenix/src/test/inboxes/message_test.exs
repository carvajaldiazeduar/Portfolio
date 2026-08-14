defmodule Inboxes.MessageTest do
  use Inboxes.DataCase, async: true

  alias Inboxes.Message

  test "valid message is saved" do
    changeset = Message.changeset(%Message{}, %{sender: "Alice", subject: "Hello", body: "Hi there"})
    assert changeset.valid?
  end

  test "sender is required" do
    changeset = Message.changeset(%Message{}, %{sender: "", subject: "Hello", body: "Hi there"})
    refute changeset.valid?
    assert Message.error_map(changeset) == %{sender: "Sender is required"}
  end

  test "subject is required" do
    changeset = Message.changeset(%Message{}, %{sender: "Alice", subject: "", body: "Hi there"})
    refute changeset.valid?
    assert Message.error_map(changeset) == %{subject: "Subject is required"}
  end

  test "body is required" do
    changeset = Message.changeset(%Message{}, %{sender: "Alice", subject: "Hello", body: ""})
    refute changeset.valid?
    assert Message.error_map(changeset) == %{body: "Body is required"}
  end

  test "sender too long" do
    long = String.duplicate("x", 256)
    changeset = Message.changeset(%Message{}, %{sender: long, subject: "Hello", body: "Hi"})
    refute changeset.valid?
    assert Message.error_map(changeset) == %{sender: "From must be 1-255 characters"}
  end

  test "subject too long" do
    long = String.duplicate("x", 301)
    changeset = Message.changeset(%Message{}, %{sender: "Alice", subject: long, body: "Hi"})
    refute changeset.valid?
    assert Message.error_map(changeset) == %{subject: "Subject must be 1-300 characters"}
  end

  test "body too long" do
    long = String.duplicate("x", 1001)
    changeset = Message.changeset(%Message{}, %{sender: "Alice", subject: "Hello", body: long})
    refute changeset.valid?
    assert Message.error_map(changeset) == %{body: "Body must be 1-1000 characters"}
  end

  test "whitespace treated as missing" do
    changeset = Message.changeset(%Message{}, %{sender: "   ", subject: "Hello", body: "Hi"})
    refute changeset.valid?
    assert Message.error_map(changeset) == %{sender: "Sender is required"}
  end

  test "to_dto exposes sender as from" do
    {:ok, message} =
      Inboxes.Repo.insert(
        Message.changeset(%Message{}, %{sender: "Alice", subject: "Hello", body: "Hi there"})
      )

    dto = Message.to_dto(message)
    assert dto.from == "Alice"
    assert dto.subject == "Hello"
    assert dto.read == false
    assert dto.created_at != nil
  end
end