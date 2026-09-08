defmodule Inboxes.Cache do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key) do
    case Agent.get(__MODULE__, &Map.get(&1, key)) do
      nil -> nil
      value -> {:ok, value}
    end
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
    value
  end

  def delete(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
    :ok
  end
end