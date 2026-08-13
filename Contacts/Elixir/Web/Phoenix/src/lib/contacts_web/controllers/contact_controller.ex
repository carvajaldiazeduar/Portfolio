defmodule ContactsWeb.ContactController do
  use ContactsWeb, :controller

  alias Contacts.ContactsService

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:contacts, "priv/static/index.html"))
  end

  def list(conn, _params) do
    json(conn, ContactsService.list_all())
  end

  def create(conn, params) do
    case ContactsService.create(params) do
      {:ok, contact} ->
        conn
        |> put_status(:created)
        |> json(contact_json(contact))

      {:error, errors} ->
        error(conn, 400, %{errors: errors})
    end
  end

  def search(conn, %{"q" => q}) do
    json(conn, ContactsService.search(q))
  end

  def search(conn, _params) do
    json(conn, ContactsService.search(""))
  end

  def show(conn, %{"id" => id}) do
    case ContactsService.show(id) do
      {:ok, contact} -> json(conn, contact_json(contact))
      :error -> error(conn, 404, %{error: "Not found"})
    end
  end

  def update(conn, %{"id" => id} = params) do
    case ContactsService.update(parse_id(id), params) do
      {:ok, contact} -> json(conn, contact_json(contact))
      {:error, :not_found} -> error(conn, 404, %{error: "Not found"})
      {:error, errors} -> error(conn, 400, %{errors: errors})
    end
  end

  def delete(conn, %{"id" => id}) do
    case ContactsService.delete(parse_id(id)) do
      {:ok, _contact} -> json(conn, %{result: "deleted"})
      {:error, :not_found} -> error(conn, 404, %{error: "Not found"})
    end
  end

  def swagger(conn, _params) do
    redirect(conn, to: "/swagger.html")
  end

  defp parse_id(id) do
    case Integer.parse(to_string(id)) do
      {int, _} -> int
      :error -> id
    end
  end

  defp contact_json(contact) do
    %{id: contact.id, name: contact.name, phone: contact.phone, email: contact.email}
  end

  defp error(conn, status, payload) do
    conn
    |> put_status(status)
    |> json(payload)
  end
end