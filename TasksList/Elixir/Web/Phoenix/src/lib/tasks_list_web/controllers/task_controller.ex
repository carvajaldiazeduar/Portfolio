defmodule TasksListWeb.TaskController do
  use TasksListWeb, :controller

  alias TasksList.TasksService

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:tasks_list, "priv/static/index.html"))
  end

  def list(conn, _params) do
    json(conn, TasksService.list_all())
  end

  def create(conn, params) do
    case TasksService.create(params) do
      {:ok, task} ->
        conn
        |> put_status(:created)
        |> json(task)

      {:error, errors} ->
        error(conn, 400, %{errors: errors})
    end
  end

  def show(conn, %{"id" => id}) do
    case TasksService.show(parse_id(id)) do
      {:ok, task} -> json(conn, task)
      :error -> error(conn, 404, %{error: "Not found"})
    end
  end

  def update(conn, %{"id" => id} = params) do
    case TasksService.update(parse_id(id), params) do
      {:ok, task} -> json(conn, task)
      {:error, :not_found} -> error(conn, 404, %{error: "Not found"})
      {:error, errors} -> error(conn, 400, %{errors: errors})
    end
  end

  def delete(conn, %{"id" => id}) do
    case TasksService.delete(parse_id(id)) do
      {:ok, _task} -> json(conn, %{result: "deleted"})
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