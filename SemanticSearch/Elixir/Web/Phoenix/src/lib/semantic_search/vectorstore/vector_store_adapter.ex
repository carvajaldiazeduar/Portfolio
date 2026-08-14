defmodule SemanticSearch.VectorStore.VectorStoreAdapter do
  @moduledoc """
  Behaviour for vector store adapters (ChromaDB, PgVector, Pinecone, InMemory).
  """

  @callback connect() :: :ok | {:error, term()}
  @callback add_documents([String.t()], [list(number())], [map()]) :: :ok | {:error, term()}
  @callback search(list(number()), pos_integer()) :: [SemanticSearch.VectorStore.SearchResult.t()]
  @callback delete_collection(String.t()) :: :ok | {:error, term()}
  @callback list_collections() :: [String.t()]
end
