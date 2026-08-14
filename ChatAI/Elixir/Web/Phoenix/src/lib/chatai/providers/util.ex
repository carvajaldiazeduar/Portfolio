defmodule ChatAI.Providers.Util do
  @moduledoc """
  Shared helpers for chat providers.
  """

  @doc "CHAT_TIMEOUT_MS as integer, default 30000."
  def timeout_ms do
    case Integer.parse(System.get_env("CHAT_TIMEOUT_MS", "30000")) do
      {i, _} -> i
      :error -> 30_000
    end
  end
end
