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
