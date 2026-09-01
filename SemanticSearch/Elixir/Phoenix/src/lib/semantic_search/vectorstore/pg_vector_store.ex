defmodule SemanticSearch.VectorStore.PgVectorStore do
  @moduledoc """
  PostgreSQL + pgvector vector store. Uses Postgrex. Tables are named
  `vector_<collection>`.
  """

  @behaviour SemanticSearch.VectorStore.VectorStoreAdapter

  alias SemanticSearch.VectorStore.SearchResult

  @impl true
  def connect do
    {:ok, pid} =
      Postgrex.start_link(
        hostname: System.get_env("DB_HOST", "db"),
        port: String.to_integer(System.get_env("DB_PORT", "5432")),
        database: System.get_env("DB_NAME", "semantic_search"),
        username: System.get_env("DB_USER", "postgres"),
        password: System.get_env("DB_PASSWORD", "postgres")
      )

    try do
      Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
      :ok
    after
      GenServer.stop(pid)
    end
  rescue
    _ -> {:error, :cannot_connect}
  end

  @impl true
  def add_documents(documents, embeddings, metadata) do
    with {:ok, pid} <- connect() do
      try do
        table = table_name()

        Postgrex.query!(
          pid,
          "CREATE TABLE IF NOT EXISTS #{table} (id SERIAL PRIMARY KEY, document TEXT, embedding vector, metadata JSONB)",
          []
        )

        Enum.zip([documents, embeddings, metadata])
        |> Enum.each(fn {doc, emb, meta} ->
          Postgrex.query!(
            pid,
            "INSERT INTO #{table} (document, embedding, metadata) VALUES ($1, $2::vector, $3::jsonb)",
            [doc, emb |> Enum.map(&(&1 * 1.0)) |> Jason.encode!(), Jason.encode!(meta)]
          )
        end)

        :ok
      after
        GenServer.stop(pid)
      end
    end
  end

  @impl true
  def search(query_embedding, n_results) do
    with {:ok, pid} <- connect() do
      try do
        table = table_name()
        emb = query_embedding |> Enum.map(&(&1 * 1.0)) |> Jason.encode!()

        rows =
          Postgrex.query!(
            pid,
            "SELECT document, metadata, embedding <=> $1::vector AS distance FROM #{table} ORDER BY embedding <=> $1::vector LIMIT $2",
            [emb, n_results]
          ).rows

        Enum.map(rows, fn [doc, meta, dist] ->
          %SearchResult{
            document: doc,
            metadata: decode_meta(meta),
            distance: dist
          }
        end)
      after
        GenServer.stop(pid)
      end
    end
  end

  @impl true
  def delete_collection(name) do
    table = name |> String.replace("-", "_")

    with {:ok, pid} <- connect() do
      try do
        Postgrex.query!(pid, "DROP TABLE IF EXISTS vector_#{table}", [])
        :ok
      after
        GenServer.stop(pid)
      end
    end
  end

  @impl true
  def list_collections do
    with {:ok, pid} <- connect() do
      try do
        rows =
          Postgrex.query!(
            pid,
            "SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'vector_%'",
            []
          ).rows

        Enum.map(rows, fn [t] -> String.replace(t, "vector_", "") end)
      after
        GenServer.stop(pid)
      end
    end
  end

  defp table_name do
    "vector_" <> (System.get_env("VECTOR_COLLECTION", "documents") |> String.replace("-", "_"))
  end

  defp decode_meta(nil), do: %{}
  defp decode_meta(meta) when is_map(meta), do: meta

  defp decode_meta(meta) when is_binary(meta) do
    case Jason.decode(meta) do
      {:ok, m} -> m
      _ -> %{}
    end
  end

  defp decode_meta(_), do: %{}
end
