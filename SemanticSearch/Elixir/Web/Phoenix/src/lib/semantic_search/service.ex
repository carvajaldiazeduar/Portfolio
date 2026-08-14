defmodule SemanticSearch.Service do
  @moduledoc """
  Semantic search service: wraps the vector store adapter and the cache.
  """

  alias SemanticSearch.VectorStore.{SearchResult, VectorStoreFactory}
  alias SemanticSearch.Cache

  @cache_tll 300

  def upload(content, filename) do
    dimension = String.to_integer(System.get_env("VECTOR_DIMENSION", "1536"))
    embedding = List.duplicate(0.0, dimension)
    metadata = %{filename: filename, source: "upload"}

    with {:ok, store} <- VectorStoreFactory.create() do
      result = store.add_documents([content], [embedding], [metadata])
      Cache.delete("search:results")
      result
    end
  end

  def search(query) do
    dimension = String.to_integer(System.get_env("VECTOR_DIMENSION", "1536"))
    embedding = List.duplicate(0.0, dimension)
    cache_key = "search:#{query}"

    case Cache.get(cache_key) do
      {:ok, cached} ->
        {:ok, %{query: query, results: cached}}

      :error ->
        with {:ok, store} <- VectorStoreFactory.create() do
          results = store.search(embedding, 5)
          serialized = Enum.map(results, &SearchResult.to_map/1)
          Cache.set(cache_key, serialized, @cache_tll)
          {:ok, %{query: query, results: serialized}}
        end
    end
  end

  def list_collections do
    with {:ok, store} <- VectorStoreFactory.create() do
      {:ok, store.list_collections()}
    end
  end

  def delete_collection(name) do
    with {:ok, store} <- VectorStoreFactory.create() do
      result = store.delete_collection(name)
      Cache.delete("search:results")
      result
    end
  end
end
