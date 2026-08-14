defmodule PasswordGeneratorWeb.PasswordControllerTest do
  use PasswordGeneratorWeb.ConnCase, async: true

  alias PasswordGenerator.PasswordsService

  setup do
    PasswordGenerator.Cache.delete("passwords:all")
    :ok
  end

  test "GET /api/generate returns a password", %{conn: conn} do
    conn = get(conn, "/api/generate", %{length: "16"})
    assert %{"password" => pw} = json_response(conn, 200)
    assert String.length(pw) == 16
  end

  test "GET /api/generate respects flags", %{conn: conn} do
    conn = get(conn, "/api/generate", %{length: "8", symbols: "true"})
    assert %{"password" => pw} = json_response(conn, 200)
    assert String.length(pw) == 8
  end

  test "GET /api/generate validates length", %{conn: conn} do
    conn = get(conn, "/api/generate", %{length: "0"})
    assert json_response(conn, 400) == %{"errors" => %{"length" => "Password length must be at least 1"}}
  end

  test "GET /api/passwords lists stored", %{conn: conn} do
    {:ok, _} = PasswordsService.create(%{password: "Abcd1234!"})
    conn = get(conn, "/api/passwords")
    assert [%{"password" => "Abcd1234!"}] = json_response(conn, 200)
  end

  test "POST /api/passwords stores a password", %{conn: conn} do
    conn = post(conn, "/api/passwords", %{password: "Abcd1234!"})
    assert %{"id" => id, "password" => "Abcd1234!"} = json_response(conn, 201)
    assert is_integer(id)
  end

  test "POST /api/passwords validates", %{conn: conn} do
    conn = post(conn, "/api/passwords", %{password: ""})
    assert json_response(conn, 400) == %{"errors" => %{"password" => "Password is required"}}
  end

  test "DELETE /api/passwords/:id deletes", %{conn: conn} do
    {:ok, entry} = PasswordsService.create(%{password: "Abcd1234!"})
    conn = delete(conn, "/api/passwords/#{entry.id}")
    assert json_response(conn, 200) == %{"result" => "deleted"}
  end

  test "DELETE /api/passwords/:id missing returns 404", %{conn: conn} do
    conn = delete(conn, "/api/passwords/999999")
    assert json_response(conn, 404) == %{"error" => "Not found"}
  end

  test "GET /swagger redirects", %{conn: conn} do
    conn = get(conn, "/swagger")
    assert redirected_to(conn, 302) == "/swagger.html"
  end
end