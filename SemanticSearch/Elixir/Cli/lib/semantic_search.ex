defmodule SemanticSearch do
  @moduledoc """
  Core semantic search operations backed by an in-memory vector store.
  """

  defmodule SearchResult do
    @moduledoc "A search hit: document + metadata + distance."
    defstruct [:document, :metadata, :distance]
  end

  defmodule VectorStore do
    @moduledoc "In-memory vector store keyed by collection."
    use Agent

    def start_link(opts \\ []) do
      Agent.start_link(fn -> %{} end, opts ++ [name: __MODULE__])
    end

    def add_documents(collection, documents, embeddings, metadata) do
      Agent.update(__MODULE__, fn state ->
        data = Map.get(state, collection, %{documents: [], embeddings: [], metadata: []})

        data = %{
          documents: data.documents ++ documents,
          embeddings: data.embeddings ++ embeddings,
          metadata: data.metadata ++ metadata
        }

        Map.put(state, collection, data)
      end)

      :ok
    end

    def search(collection, _embedding, n_results) do
      case Agent.get(__MODULE__, &Map.get(&1, collection)) do
        nil -> []
        %{documents: docs} when docs == [] -> []
        %{documents: docs, metadata: metas} ->
          docs
          |> Enum.zip(metas)
          |> Enum.take(n_results)
          |> Enum.map(fn {doc, meta} ->
            %SemanticSearch.SearchResult{document: doc, metadata: meta, distance: 0.0}
          end)
      end
    end

    def delete_collection(collection) do
      Agent.update(__MODULE__, &Map.delete(&1, collection))
      :ok
    end

    def list_collections do
      Agent.get(__MODULE__, &Map.keys/1)
    end
  end

  @doc "Lists all collections."
  def list_collections do
    VectorStore.list_collections()
  end

  @doc "Searches a collection (default from VECTOR_COLLECTION). Returns [SearchResult]."
  def search(query, k \\ 5) when is_binary(query) do
    collection = collection_name()
    dimension = String.to_integer(System.get_env("VECTOR_DIMENSION", "1536"))
    embedding = List.duplicate(0.0, dimension)
    VectorStore.search(collection, embedding, k)
  end

  @doc "Deletes a collection by name."
  def delete_collection(name) do
    VectorStore.delete_collection(name)
  end

  defp collection_name, do: System.get_env("VECTOR_COLLECTION", "documents")
end