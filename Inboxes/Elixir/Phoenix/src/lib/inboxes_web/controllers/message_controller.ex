defmodule InboxesWeb.MessageController do
  use InboxesWeb, :controller

  alias Inboxes.{Message, MessagesService}

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:inboxes, "priv/static/index.html"))
  end

  def list(conn, _params) do
    json(conn, Enum.map(MessagesService.list_all(), &Message.to_dto/1))
  end

  def create(conn, params) do
    case MessagesService.create(params) do
      {:ok, message} ->
        conn
        |> put_status(:created)
        |> json(Message.to_dto(message))

      {:error, errors} ->
        error(conn, 400, %{errors: errors})
    end
  end

  def show(conn, %{"id" => id}) do
    case MessagesService.show(parse_id(id)) do
      {:ok, message} -> json(conn, Message.to_dto(message))
      :error -> error(conn, 404, %{error: "Not found"})
    end
  end

  def delete(conn, %{"id" => id}) do
    case MessagesService.delete(parse_id(id)) do
      {:ok, _message} -> error(conn, 204, nil)
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

  defp error(conn, status, payload) do
    conn
    |> put_status(status)
    |> json(payload)
  end
end