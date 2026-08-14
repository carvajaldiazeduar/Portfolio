defmodule SemanticSearchTest do
  use ExUnit.Case

  alias SemanticSearch
  alias SemanticSearch.VectorStore

  setup do
    VectorStore.start_link()
    System.put_env("VECTOR_COLLECTION", "documents")
    on_exit(fn -> System.delete_env("VECTOR_COLLECTION") end)
    :ok
  end

  test "vector store add and search" do
    VectorStore.add_documents(
      "documents",
      ["hello world", "second doc"],
      [List.duplicate(0.0, 4), List.duplicate(0.0, 4)],
      [%{filename: "a.txt"}, %{filename: "b.txt"}]
    )

    results = SemanticSearch.search("hello")
    assert length(results) == 2
    assert Enum.at(results, 0).document == "hello world"
    assert Enum.at(results, 1).document == "second doc"
  end

  test "search respects k limit" do
    VectorStore.add_documents(
      "documents",
      ["one", "two", "three"],
      [List.duplicate(0.0, 4), List.duplicate(0.0, 4), List.duplicate(0.0, 4)],
      [%{}, %{}, %{}]
    )

    assert length(SemanticSearch.search("q", 2)) == 2
  end

  test "list and delete collection" do
    assert SemanticSearch.list_collections() == []

    VectorStore.add_documents(
      "documents",
      ["x"],
      [List.duplicate(0.0, 4)],
      [%{}]
    )

    assert "documents" in SemanticSearch.list_collections()

    SemanticSearch.delete_collection("documents")
    assert SemanticSearch.list_collections() == []
  end

  test "search empty returns empty" do
    assert SemanticSearch.search("q") == []
  end
end