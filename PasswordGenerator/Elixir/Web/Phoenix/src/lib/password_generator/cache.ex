defmodule PasswordGenerator.Cache do
  @moduledoc """
  Cache façade that dispatches to the adapter selected by `CACHE_TYPE`.
  The LocalCache Agent and RedisCache Redix connection are both started
  under the supervisor; only the configured one is used.
  """

  def get(key) do
    adapter().get(key)
  end

  def set(key, value, ttl) do
    adapter().set(key, value, ttl)
  end

  def delete(key) do
    adapter().delete(key)
  end

  defp adapter do
    case Application.get_env(:password_generator, :cache_type, "local") do
      "redis" -> PasswordGenerator.Cache.RedisCache
      _ -> PasswordGenerator.Cache.LocalCache
    end
  end
end