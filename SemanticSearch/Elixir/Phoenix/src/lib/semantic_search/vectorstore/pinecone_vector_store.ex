defmodule SemanticSearch.VectorStore.PineconeVectorStore do
  @moduledoc """
  Pinecone vector store over its HTTP API. Uses `:req`. When Pinecone is
  unreachable the factory falls back to InMemoryVectorStore.
  """

  @behaviour SemanticSearch.VectorStore.VectorStoreAdapter

  alias SemanticSearch.VectorStore.SearchResult

  @impl true
  def connect do
    case api_key() do
      "" -> {:error, :missing_api_key}
      _ -> {:ok, :connected}
    end
  end

  @impl true
  def add_documents(documents, embeddings, metadata) do
    vectors =
      Enum.with_index(documents)
      |> Enum.map(fn {doc, i} ->
        %{
          id: "doc_#{i}",
          values: embeddings |> Enum.at(i) |> Enum.map(&(&1 * 1.0)),
          metadata: Map.put(metadata |> Enum.at(i) || %{}, "text", doc)
        }
      end)

    payload = %{vectors: vectors}

    case post("/vectors/upsert", payload) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :upsert_failed}
    end
  end

  @impl true
  def search(query_embedding, n_results) do
    payload = %{
      vector: query_embedding |> Enum.map(&(&1 * 1.0)),
      topK: n_results,
      includeMetadata: true
    }

    case post("/query", payload) do
      {:ok, body} ->
        Enum.map(body["matches"] || [], fn match ->
          meta = match["metadata"] || %{}
          text = meta["text"] || ""

          %SearchResult{
            document: text,
            metadata: Map.delete(meta, "text"),
            distance: match["score"] || 0.0
          }
        end)

      {:error, _} ->
        []
    end
  end

  @impl true
  def delete_collection(_name), do: :ok

  @impl true
  def list_collections, do: []

  defp api_key, do: System.get_env("PINECONE_API_KEY", "")

  defp index_url do
    index = System.get_env("PINECONE_INDEX", "documents")
    host = System.get_env("PINECONE_HOST", index)
    "https://#{host}"
  end

  defp post(path, payload) do
    headers = [
      {"api-key", api_key()},
      {"content-type", "application/json"}
    ]

    url = index_url() <> path

    response = Req.post!(url, json: payload, headers: headers, receive_timeout: 5000)

    case response.status do
      s when s in 200..299 -> {:ok, response.body}
      _ -> {:error, response.status}
    end
  rescue
    _ -> {:error, :connection_error}
  end
end
