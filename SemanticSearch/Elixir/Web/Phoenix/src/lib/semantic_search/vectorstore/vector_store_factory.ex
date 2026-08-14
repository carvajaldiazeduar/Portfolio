defmodule SemanticSearch.VectorStore.VectorStoreFactory do
  @moduledoc """
  Builds a vector store adapter from `VECTOR_DRIVER` (chromadb/pinecone/pgvector),
  defaulting to chromadb. Falls back to InMemoryVectorStore when the chosen
  store cannot connect.
  """

  alias SemanticSearch.VectorStore.{
    ChromaDBVectorStore,
    InMemoryVectorStore,
    PgVectorStore,
    PineconeVectorStore
  }

  def create do
    driver = driver()

    case driver do
      "in-memory" ->
        ensure_started()
        {:ok, InMemoryVectorStore}

      "pinecone" ->
        store = PineconeVectorStore
        ensure_started(store)

      "pgvector" ->
        store = PgVectorStore
        ensure_started(store)

      "chromadb" ->
        store = ChromaDBVectorStore
        ensure_started(store)

      _ ->
        store = ChromaDBVectorStore
        ensure_started(store)
    end
  end

  defp driver do
    case Application.get_env(:semantic_search, :vector_driver) do
      nil -> System.get_env("VECTOR_DRIVER", "chromadb")
      driver -> driver
    end
  end

  defp ensure_started do
    if Process.whereis(InMemoryVectorStore) == nil do
      {:ok, _} = InMemoryVectorStore.start_link()
    end

    {:ok, InMemoryVectorStore}
  end

  defp ensure_started(store) do
    case store.connect() do
      :ok -> {:ok, store}
      {:error, _} -> ensure_started()
    end
  end
end
