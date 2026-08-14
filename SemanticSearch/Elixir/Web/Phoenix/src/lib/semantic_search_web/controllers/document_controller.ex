defmodule SemanticSearchWeb.DocumentController do
  use SemanticSearchWeb, :controller

  alias SemanticSearch.Service

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:semantic_search, "priv/static/index.html"))
  end

  def upload(conn, params) do
    case params["file"] do
      nil ->
        error(conn, 400, %{error: "No file provided"})

      %Plug.Upload{path: path, filename: filename} ->
        content = File.read!(path)

        case Service.upload(content, filename) do
          :ok ->
            json(conn, %{message: "Document indexed", filename: filename})

          {:error, _} ->
            error(conn, 500, %{error: "Could not index document"})
        end

      _ ->
        error(conn, 400, %{error: "No file provided"})
    end
  end

  def search(conn, params) do
    query = params["q"] || ""

    if query == "" do
      error(conn, 400, %{error: "Query parameter 'q' is required"})
    else
      case Service.search(query) do
        {:ok, body} -> json(conn, body)
        {:error, _} -> error(conn, 500, %{error: "Search failed"})
      end
    end
  end

  def collections(conn, _params) do
    case Service.list_collections() do
      {:ok, collections} -> json(conn, %{collections: collections})
      {:error, _} -> error(conn, 500, %{error: "Could not list collections"})
    end
  end

  def delete_collection(conn, %{"name" => name}) do
    case Service.delete_collection(name) do
      :ok -> json(conn, %{message: "Collection '#{name}' deleted"})
      {:error, _} -> error(conn, 500, %{error: "Could not delete collection"})
    end
  end

  def openapi(conn, _params) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_file(200, Application.app_dir(:semantic_search, "priv/static/openapi.json"))
  end

  def swagger(conn, _params) do
    redirect(conn, to: "/swagger.html")
  end

  defp error(conn, status, payload) do
    conn
    |> put_status(status)
    |> json(payload)
  end
end
