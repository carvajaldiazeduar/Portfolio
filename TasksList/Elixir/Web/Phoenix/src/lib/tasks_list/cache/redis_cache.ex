defmodule TasksList.Cache.RedisCache do
  @moduledoc """
  Redis-backed CacheAdapter using Redix. Falls back to no-cache (always :error)
  when Redis is unreachable so the app still serves from the DB.
  """

  @behaviour TasksList.Cache.CacheAdapter

  def start_link(opts \\ []) do
    host = Keyword.get(opts, :host, "localhost:6379")
    Redix.start_link(host, name: __MODULE__)
  end

  def get(key) do
    case Redix.command(__MODULE__, ["GET", key]) do
      {:ok, nil} -> :error
      {:ok, value} -> {:ok, decode(value)}
      {:error, _} -> :error
    end
  end

  def set(key, value, ttl) do
    case Redix.command(__MODULE__, ["SET", key, encode(value), "EX", ttl]) do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  end

  def delete(key) do
    case Redix.command(__MODULE__, ["DEL", key]) do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  end

  defp encode(value), do: Jason.encode!(value)
  defp decode(value), do: Jason.decode!(value)
end