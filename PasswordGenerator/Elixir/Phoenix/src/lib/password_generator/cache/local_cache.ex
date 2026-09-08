defmodule PasswordGenerator.Cache.LocalCache do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set(key, value, ttl_seconds) do
    expires_at = System.monotonic_time(:millisecond) + ttl_seconds * 1000
    Agent.update(__MODULE__, &Map.put(&1, key, {expires_at, value}))
    :ok
  end

  def get(key) do
    now = System.monotonic_time(:millisecond)

    case Agent.get(__MODULE__, &Map.get(&1, key)) do
      nil ->
        :error

      {expires_at, value} when expires_at > now ->
        {:ok, value}

      {_expires_at, _value} ->
        delete(key)
        :error
    end
  end

  def delete(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
    :ok
  end
end