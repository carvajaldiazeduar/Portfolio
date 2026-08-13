defmodule ContactsWeb.ContactControllerTest do
  use ContactsWeb.ConnCase, async: true

  alias Contacts.ContactsService

  setup do
    Contacts.Cache.delete("contacts:all")
    :ok
  end

  test "GET /api/contacts lists contacts", %{conn: conn} do
    {:ok, _} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    conn = get(conn, "/api/contacts")
    assert [contact] = json_response(conn, 200)
    assert contact["name"] == "Alice Smith"
  end

  test "POST /api/contacts creates", %{conn: conn} do
    conn =
      post(conn, "/api/contacts", %{
        name: "Alice Smith",
        phone: "+1 555 1234",
        email: "alice@example.com"
      })

    assert %{"id" => id, "name" => "Alice Smith"} = json_response(conn, 201)
    assert is_integer(id)
  end

  test "POST /api/contacts validates", %{conn: conn} do
    conn = post(conn, "/api/contacts", %{name: "", phone: "5551234", email: "a@b.com"})
    assert json_response(conn, 400) == %{"errors" => %{"name" => "Name is required"}}
  end

  test "GET /api/contacts/:id shows one", %{conn: conn} do
    {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    id = contact.id
    conn = get(conn, "/api/contacts/#{id}")
    assert %{"id" => ^id} = json_response(conn, 200)
  end

  test "GET /api/contacts/:id missing returns 404", %{conn: conn} do
    conn = get(conn, "/api/contacts/999999")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "PUT /api/contacts/:id updates", %{conn: conn} do
    {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    conn = put(conn, "/api/contacts/#{contact.id}", %{name: "Alice Updated"})
    assert %{"name" => "Alice Updated"} = json_response(conn, 200)
  end

  test "DELETE /api/contacts/:id deletes", %{conn: conn} do
    {:ok, contact} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    conn = delete(conn, "/api/contacts/#{contact.id}")
    assert json_response(conn, 200) == %{"result" => "deleted"}
  end

  test "DELETE /api/contacts/:id missing returns 404", %{conn: conn} do
    conn = delete(conn, "/api/contacts/999999")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "GET /api/contacts/search filters by name", %{conn: conn} do
    {:ok, _} = ContactsService.create(%{name: "Alice Smith", phone: "5551234", email: "a@b.com"})
    {:ok, _} = ContactsService.create(%{name: "Bob Jones", phone: "5555678", email: "b@b.com"})
    conn = get(conn, "/api/contacts/search?q=alice")
    assert [%{"name" => "Alice Smith"}] = json_response(conn, 200)
  end

  test "GET /swagger redirects", %{conn: conn} do
    conn = get(conn, "/swagger")
    assert redirected_to(conn, 302) == "/swagger.html"
  end
end