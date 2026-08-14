defmodule SemanticSearch.CLI do
  @moduledoc """
  Interactive Semantic Search CLI (escript entry point).
  """

  alias SemanticSearch

  def main(_args) do
    SemanticSearch.VectorStore.start_link()
    loop()
  end

  defp loop do
    IO.puts("\nSemantic Search CLI")
    IO.puts("1. List collections")
    IO.puts("2. Search documents")
    IO.puts("3. Delete collection")
    IO.puts("4. Exit")

    case read_int("Choice") do
      1 ->
        list_collections()
        loop()

      2 ->
        search()
        loop()

      3 ->
        delete_collection()
        loop()

      4 ->
        IO.puts("Goodbye!")

      _ ->
        IO.puts("Invalid option.")
        loop()
    end
  end

  defp list_collections do
    case SemanticSearch.list_collections() do
      [] -> IO.puts("  (no collections)")
      collections -> Enum.each(collections, &IO.puts("  - #{&1}"))
    end
  end

  defp search do
    query = read_line("Search query")

    if query == "" do
      IO.puts("  Empty query.")
    else
      case SemanticSearch.search(query) do
        [] -> IO.puts("  (no results)")
        results -> Enum.each(results, &IO.puts("  [#{&1.distance}] #{truncate(&1.document, 100)}"))
      end
    end
  end

  defp delete_collection do
    name = read_line("Collection name")
    SemanticSearch.delete_collection(name)
    IO.puts("Collection '#{name}' deleted")
  end

  defp truncate(s, max) do
    cond do
      s == nil -> ""
      String.length(s) <= max -> s
      true -> String.slice(s, 0, max)
    end
  end

  defp read_line(prompt) do
    IO.gets("#{prompt}: ") |> String.trim()
  end

  defp read_int(prompt) do
    case Integer.parse(IO.gets("#{prompt}: ")) do
      {n, _} -> n
      :error -> -1
    end
  end
end