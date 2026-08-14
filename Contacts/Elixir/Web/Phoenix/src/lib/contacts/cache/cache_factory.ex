defmodule Contacts.Cache.CacheFactory do
  @moduledoc """
  Builds the cache adapter from `CACHE_TYPE` (redis/local).
  """

  def create_cache("local"), do: :local
  def create_cache(_), do: :redis
end