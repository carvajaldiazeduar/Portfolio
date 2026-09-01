defmodule ChatAI.Providers.ChatProviderFactory do
  @moduledoc """
  Resolves a provider name to a concrete chat provider, checking that the
  provider's API key is configured. Supports `CHAT_FALLBACK_PROVIDER` for
  one retry after a primary failure.
  """

  alias ChatAI.Providers.{
    AnthropicChatProvider,
    AzureChatProvider,
    GoogleChatProvider,
    OpenAiCompatibleChatProvider
  }

  @providers %{
    "openai" => :openai,
    "openai-compatible" => :openai,
    "azure" => :azure,
    "google" => :google,
    "anthropic" => :anthropic
  }

  @doc "Resolves the provider name: request wins, then CHAT_PROVIDER, then openai."
  def resolve(nil), do: resolve("")
  def resolve(""), do: System.get_env("CHAT_PROVIDER", "openai")
  def resolve(provider), do: provider

  @doc "Returns the CHAT_FALLBACK_PROVIDER env or nil."
  def fallback_provider do
    case System.get_env("CHAT_FALLBACK_PROVIDER", "") do
      "" -> nil
      fb -> fb
    end
  end

  @doc "RAG_ENABLED? (accepts 1/true/yes)."
  def rag_enabled do
    case System.get_env("RAG_ENABLED", "") do
      "" -> false
      v -> v in ["1", "true", "TRUE", "yes"]
    end
  end

  @doc "RAG_SEARCH_URL with default."
  def rag_search_url do
    System.get_env("RAG_SEARCH_URL", "http://semantic-search:5000/api/search")
  end

  @doc "RAG_TOP_K as integer, default 3."
  def rag_top_k do
    case Integer.parse(System.get_env("RAG_TOP_K", "3")) do
      {i, _} -> i
      :error -> 3
    end
  end

  @doc "Retrieves documents for a query. Fail-soft: returns [] on any error."
  def retrieve_context(query) do
    url =
      rag_search_url() <>
        "?q=" <> URI.encode_www_form(query) <> "&k=" <> Integer.to_string(rag_top_k())

    timeout = ChatAI.Providers.Util.timeout_ms()

    case ChatAI.Providers.HttpClient.get_json(url, timeout) do
      {:ok, %{"results" => results}} when is_list(results) ->
        Enum.flat_map(results, fn
          %{"document" => doc} when is_binary(doc) and doc != "" -> [doc]
          _ -> []
        end)

      _ ->
        []
    end
  end

  @doc "Prepends RAG context as a system message when enabled and documents are found."
  def apply_rag(%ChatAI.ChatRequest{} = request) do
    if rag_enabled() do
      last_user =
        request.messages
        |> Enum.reverse()
        |> Enum.find(fn m -> m.role == "user" end)

      case last_user do
        nil ->
          request

        last ->
          documents = retrieve_context(last.content || "")

          if documents == [] do
            request
          else
            context =
              "Use the following context to answer the user's question:\n\n" <>
                Enum.map_join(documents, "\n", fn doc -> "- " <> doc end)

            %{request | messages: [%ChatAI.Message{role: "system", content: context} | request.messages]}
          end
      end
    else
      request
    end
  end

  @doc "Returns the API key env name for a provider, or nil if unsupported."
  def key_env("openai"), do: "OPENAI_API_KEY"
  def key_env("openai-compatible"), do: "OPENAI_API_KEY"
  def key_env("azure"), do: "AZURE_OPENAI_API_KEY"
  def key_env("google"), do: "GOOGLE_API_KEY"
  def key_env("anthropic"), do: "ANTHROPIC_API_KEY"
  def key_env(_), do: nil

  @doc "Returns the API key for a provider (nil if unconfigured)."
  def key_for(provider) do
    case key_env(provider) do
      nil -> nil
      env -> System.get_env(env)
    end
  end

  @doc "Creates a provider struct. Raises for unsupported/unconfigured providers."
  def create(provider) do
    provider = resolve(provider)

    case Map.get(@providers, provider) do
      nil ->
        raise ArgumentError, "Unsupported provider: #{provider}"

      kind ->
        key = key_for(provider)

        if key == nil or key == "" do
          raise ArgumentError,
                "Provider '#{provider}' is not configured (missing API key)"
        end

        case kind do
          :openai ->
            %OpenAiCompatibleChatProvider{}

          :azure ->
            %AzureChatProvider{}

          :google ->
            %GoogleChatProvider{}

          :anthropic ->
            %AnthropicChatProvider{}
        end
    end
  end

  @doc "Completes a chat against the primary provider, retrying once on the fallback."
  def complete_chat(%ChatAI.ChatRequest{} = request, provider) do
    primary = create(provider)

    case primary.complete_chat(request) do
      {:ok, response} ->
        {:ok, %{response | provider: provider}}

      {:error, _msg} ->
        try_fallback(request)
    end
  end

  defp try_fallback(%ChatAI.ChatRequest{} = request) do
    case fallback_provider() do
      nil ->
        {:error, "Provider failed"}

      fallback ->
        key = key_for(fallback)

        if key == nil or key == "" do
          {:error, "Provider failed"}
        else
          fb_provider = create(fallback)

          case fb_provider.complete_chat(request) do
            {:ok, response} -> {:ok, %{response | provider: fallback}}
            {:error, _} -> {:error, "Provider failed"}
          end
        end
    end
  end
end
