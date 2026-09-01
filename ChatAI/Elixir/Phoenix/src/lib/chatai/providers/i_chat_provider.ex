defmodule ChatAI.Providers.IChatProvider do
  @moduledoc """
  Behaviour contract for chat providers: `complete_chat/1`.
  """
  @callback complete_chat(ChatAI.ChatRequest.t()) ::
              {:ok, ChatAI.ChatResponse.t()} | {:error, String.t()}
end
