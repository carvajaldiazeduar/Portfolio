defmodule Inboxes.Cache.CacheAdapter do
  @callback get(String.t()) :: {:ok, term()} | :error
  @callback set(String.t(), term(), pos_integer()) :: :ok
  @callback delete(String.t()) :: :ok
end
