defmodule SemanticSearch.Cache.LocalCache do
  use Agent

  @behaviour SemanticSearch.Cache.CacheAdapter

  def start_link(opts \\ []) do
    Agent.start_link(fn -> %{} end, opts ++ [name: __MODULE__])
  end

  def get(key) do
    now = System.monotonic_time(:millisecond)

    case Agent.get(__MODULE__, &Map.get(&1, key)) do
      {value, expires_at} when expires_at > now -> {:ok, value}
      _ -> :error
    end
  end

  def set(key, value, ttl) do
    expires_at = System.monotonic_time(:millisecond) + ttl * 1000
    Agent.update(__MODULE__, &Map.put(&1, key, {value, expires_at}))
    :ok
  end

  def delete(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
    :ok
  end
end
