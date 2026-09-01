defmodule SemanticSearchWeb.DocumentControllerTest do
  use SemanticSearchWeb.ConnCase, async: false

  alias SemanticSearch.Cache.LocalCache
  alias SemanticSearch.VectorStore.InMemoryVectorStore

  setup do
    LocalCache.delete("search:results")
    InMemoryVectorStore.delete_collection(System.get_env("VECTOR_COLLECTION", "documents"))
    :ok
  end

  test "GET / returns HTML", %{conn: conn} do
    conn = get(conn, "/")
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> List.first() =~ "text/html"
  end

  test "GET /swagger redirects to swagger.html", %{conn: conn} do
    conn = get(conn, "/swagger")
    assert redirected_to(conn) == "/swagger.html"
  end

  test "GET /openapi.json is served", %{conn: conn} do
    conn = get(conn, "/openapi.json")
    assert conn.status == 200
  end

  test "GET /api/collections returns 200", %{conn: conn} do
    conn = get(conn, "/api/collections")
    assert json_response(conn, 200)["collections"] == []
  end

  test "POST /api/upload with file returns 200", %{conn: conn} do
    upload = %Plug.Upload{
      path: "/tmp/upload-test.txt",
      filename: "hello.txt"
    }

    File.write!("/tmp/upload-test.txt", "hello world")

    conn =
      post(conn, "/api/upload", %{"file" => upload})

    body = json_response(conn, 200)
    assert body["message"] == "Document indexed"
    assert body["filename"] == "hello.txt"

    File.rm("/tmp/upload-test.txt")
  end

  test "POST /api/upload without file returns 400", %{conn: conn} do
    conn = post(conn, "/api/upload", %{})
    assert json_response(conn, 400) == %{"error" => "No file provided"}
  end

  test "GET /api/search without query returns 400", %{conn: conn} do
    conn = get(conn, "/api/search")
    assert json_response(conn, 400) == %{"error" => "Query parameter 'q' is required"}
  end

  test "GET /api/search with query returns results", %{conn: conn} do
    upload = %Plug.Upload{path: "/tmp/doc.txt", filename: "doc.txt"}
    File.write!("/tmp/doc.txt", "hello world")
    post(conn, "/api/upload", %{"file" => upload})

    conn = get(conn, "/api/search", %{"q" => "hello"})
    body = json_response(conn, 200)
    assert body["query"] == "hello"
    assert is_list(body["results"])
    assert length(body["results"]) == 1
    assert body["results"] |> List.first() |> Map.get("document") == "hello world"

    File.rm("/tmp/doc.txt")
  end

  test "search caches the result", %{conn: conn} do
    upload = %Plug.Upload{path: "/tmp/doc.txt", filename: "doc.txt"}
    File.write!("/tmp/doc.txt", "hello world")
    post(conn, "/api/upload", %{"file" => upload})

    conn = get(conn, "/api/search", %{"q" => "cached-query"})
    assert conn.status == 200

    assert {:ok, _cached} = LocalCache.get("search:cached-query")

    File.rm("/tmp/doc.txt")
  end

  test "DELETE /api/collections/:name returns 200", %{conn: conn} do
    conn = delete(conn, "/api/collections/documents")
    assert json_response(conn, 200) == %{"message" => "Collection 'documents' deleted"}
  end
end
