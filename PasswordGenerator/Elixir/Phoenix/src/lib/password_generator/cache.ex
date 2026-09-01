defmodule PasswordGenerator.Cache do
  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def get(key), do: Agent.get(__MODULE__, &Map.get(&1, key))

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
    value
  end

  def delete(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
    :ok
  end
end
