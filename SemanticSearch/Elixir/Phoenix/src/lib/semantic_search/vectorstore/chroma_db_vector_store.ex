defmodule SemanticSearch.VectorStore.ChromaDBVectorStore do
  @moduledoc """
  ChromaDB vector store over its HTTP API (v2). Uses `:req` for HTTP calls.
  """

  @behaviour SemanticSearch.VectorStore.VectorStoreAdapter

  alias SemanticSearch.VectorStore.SearchResult

  @impl true
  def connect do
    url = chroma_url()

    case Req.get!(url <> "/api/v2/collections", receive_timeout: 2000) do
      %Req.Response{status: s} when s in 200..299 ->
        {:ok, :connected}

      %Req.Response{} ->
        {:error, :cannot_connect}
    end
  rescue
    _ -> {:error, :cannot_connect}
  end

  @impl true
  def add_documents(documents, embeddings, metadata) do
    collection_id = get_or_create_collection()

    payload = %{
      ids: Enum.with_index(documents) |> Enum.map(fn {_, i} -> "doc_#{i}" end),
      documents: documents,
      embeddings: embeddings,
      metadatas: metadata
    }

    url = chroma_url() <> "/api/v2/collections/#{collection_id}/add"

    case Req.post!(url, json: payload, receive_timeout: 5000) do
      %Req.Response{status: s} when s in 200..299 -> :ok
      %Req.Response{} -> {:error, :add_failed}
    end
  rescue
    _ -> {:error, :add_failed}
  end

  @impl true
  def search(query_embedding, n_results) do
    collection_id = get_or_create_collection()

    payload = %{
      query_embeddings: [query_embedding],
      n_results: n_results,
      include: ["documents", "metadatas", "distances"]
    }

    url = chroma_url() <> "/api/v2/collections/#{collection_id}/query"

    case Req.post!(url, json: payload, receive_timeout: 5000) do
      %Req.Response{status: s, body: body} when s in 200..299 ->
        docs = List.wrap(get_in(body, ["documents", Access.at(0)]) || [])
        metas = List.wrap(get_in(body, ["metadatas", Access.at(0)]) || [])
        dists = List.wrap(get_in(body, ["distances", Access.at(0)]) || [])

        docs
        |> Enum.zip([metas, dists] |> Enum.map(&List.wrap/1))
        |> Enum.map(fn {doc, {meta, dist}} ->
          %SearchResult{
            document: to_string(doc),
            metadata: if(is_map(meta), do: meta, else: %{}),
            distance: if(is_number(dist), do: dist, else: 0.0)
          }
        end)

      %Req.Response{} ->
        []
    end
  rescue
    _ -> []
  end

  @impl true
  def delete_collection(name) do
    url = chroma_url() <> "/api/v2/collections/#{name}"

    try do
      Req.delete!(url, receive_timeout: 5000)
      :ok
    rescue
      _ -> {:error, :delete_failed}
    end
  end

  @impl true
  def list_collections do
    url = chroma_url() <> "/api/v2/collections"

    case Req.get!(url, receive_timeout: 5000) do
      %Req.Response{status: s, body: body} when s in 200..299 ->
        Enum.map(List.wrap(body), & &1["name"])

      %Req.Response{} ->
        []
    end
  rescue
    _ -> []
  end

  defp get_or_create_collection do
    collection = System.get_env("VECTOR_COLLECTION", "documents")
    existing = find_collection(collection)
    if existing, do: existing, else: create_collection(collection)
  end

  defp find_collection(name) do
    url = chroma_url() <> "/api/v2/collections"

    case Req.get!(url, receive_timeout: 5000) do
      %Req.Response{status: s, body: body} when s in 200..299 ->
        Enum.find_value(List.wrap(body), fn c ->
          if c["name"] == name, do: c["id"], else: nil
        end)

      %Req.Response{} ->
        nil
    end
  rescue
    _ -> nil
  end

  defp create_collection(name) do
    payload = %{
      name: name,
      metadata: %{"hnsw:space" => "cosine"},
      get_or_create: true
    }

    url = chroma_url() <> "/api/v2/collections"

    case Req.post!(url, json: payload, receive_timeout: 5000) do
      %Req.Response{status: s, body: body} when s in 200..299 ->
        body["id"] || body["name"] || name

      %Req.Response{} ->
        name
    end
  rescue
    _ -> name
  end

  defp chroma_url do
    case System.get_env("CHROMA_URL", "") do
      "" ->
        host = System.get_env("CHROMA_HOST", "localhost")
        port = System.get_env("CHROMA_PORT", "8000")
        "http://#{host}:#{port}"

      url ->
        url |> String.trim_trailing("/")
    end
  end
end
