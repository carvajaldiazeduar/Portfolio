defmodule SemanticSearch.VectorStore.InMemoryVectorStore do
  @moduledoc """
  In-memory vector store: stores docs/embeddings/metadata per collection in an
  Agent. Used as the default/fallback store and in tests.
  """
  use Agent

  @behaviour SemanticSearch.VectorStore.VectorStoreAdapter

  alias SemanticSearch.VectorStore.SearchResult

  def start_link(opts \\ []) do
    Agent.start_link(fn -> %{} end, opts ++ [name: __MODULE__])
  end

  @impl true
  def connect, do: :ok

  @impl true
  def add_documents(documents, embeddings, metadata) do
    collection = collection_name()

    Agent.update(__MODULE__, fn state ->
      data =
        Map.get(state, collection, %{documents: [], embeddings: [], metadata: []})

      data = %{
        documents: data.documents ++ documents,
        embeddings: data.embeddings ++ embeddings,
        metadata: data.metadata ++ metadata
      }

      Map.put(state, collection, data)
    end)

    :ok
  end

  @impl true
  def search(_query_embedding, n_results) do
    collection = collection_name()

    data = Agent.get(__MODULE__, &Map.get(&1, collection))

    case data do
      nil ->
        []

      %{documents: docs, metadata: _metas} when docs == [] ->
        []

      %{documents: docs, metadata: metas} ->
        docs
        |> Enum.zip(metas)
        |> Enum.take(n_results)
        |> Enum.map(fn {doc, meta} ->
          %SearchResult{document: doc, metadata: meta, distance: 0.0}
        end)
    end
  end

  @impl true
  def delete_collection(name) do
    Agent.update(__MODULE__, &Map.delete(&1, name))
    :ok
  end

  @impl true
  def list_collections do
    Agent.get(__MODULE__, &Map.keys/1)
  end

  defp collection_name, do: System.get_env("VECTOR_COLLECTION", "documents")
end
