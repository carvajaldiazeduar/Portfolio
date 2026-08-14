defmodule InboxesWeb.MessageControllerTest do
  use InboxesWeb.ConnCase, async: true

  alias Inboxes.MessagesService

  setup do
    Inboxes.Cache.delete("messages:all")
    :ok
  end

  test "GET /api/messages lists messages", %{conn: conn} do
    {:ok, _} = MessagesService.create(%{sender: "Alice", subject: "Hi", body: "Hello"})
    conn = get(conn, "/api/messages")
    assert [message] = json_response(conn, 200)
    assert message["from"] == "Alice"
    assert message["subject"] == "Hi"
    assert message["read"] == false
  end

  test "POST /api/messages creates", %{conn: conn} do
    conn =
      post(conn, "/api/messages", %{
        sender: "Alice",
        subject: "Hello",
        body: "Hi there"
      })

    assert %{"id" => id, "from" => "Alice", "subject" => "Hello"} = json_response(conn, 201)
    assert is_integer(id)
  end

  test "POST /api/messages validates", %{conn: conn} do
    conn = post(conn, "/api/messages", %{sender: "", subject: "", body: ""})
    assert json_response(conn, 400) == %{
             "errors" => %{
               "sender" => "Sender is required",
               "subject" => "Subject is required",
               "body" => "Body is required"
             }
           }
  end

  test "GET /api/messages/:id shows one and marks read", %{conn: conn} do
    {:ok, message} = MessagesService.create(%{sender: "Alice", subject: "Hi", body: "Hello"})
    conn = get(conn, "/api/messages/#{message.id}")
    assert %{"id" => id, "read" => true} = json_response(conn, 200)
    assert id == message.id
  end

  test "GET /api/messages/:id missing returns 404", %{conn: conn} do
    conn = get(conn, "/api/messages/999999")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "DELETE /api/messages/:id deletes", %{conn: conn} do
    {:ok, message} = MessagesService.create(%{sender: "Alice", subject: "Hi", body: "Hello"})
    conn = delete(conn, "/api/messages/#{message.id}")
    assert conn.status == 204
    conn = get(conn, "/api/messages/#{message.id}")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "DELETE /api/messages/:id missing returns 404", %{conn: conn} do
    conn = delete(conn, "/api/messages/999999")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "GET /swagger redirects", %{conn: conn} do
    conn = get(conn, "/swagger")
    assert redirected_to(conn, 302) == "/swagger.html"
  end
end