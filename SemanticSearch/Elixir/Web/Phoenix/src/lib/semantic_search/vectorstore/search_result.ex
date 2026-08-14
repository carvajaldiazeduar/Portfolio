defmodule SemanticSearch.VectorStore.SearchResult do
  @moduledoc """
  A single search hit: document text + metadata + distance.
  """
  defstruct [:document, :metadata, :distance]

  @type t :: %__MODULE__{
          document: String.t(),
          metadata: map(),
          distance: number()
        }

  def to_map(%__MODULE__{} = r) do
    %{
      document: r.document,
      metadata: r.metadata,
      distance: r.distance
    }
  end
end
