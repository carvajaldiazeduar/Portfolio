defmodule ChatAI.Providers.AzureChatProvider do
  @moduledoc """
  Azure OpenAI chat provider:
  `POST {endpoint}/openai/deployments/{deployment}/chat/completions?api-version=...`
  with `api-key` header.
  """
  @behaviour ChatAI.Providers.IChatProvider
  defstruct []

  alias ChatAI.{ChatRequest, ChatResponse}

  @impl true
  def complete_chat(%ChatRequest{} = request) do
    endpoint = System.get_env("AZURE_OPENAI_ENDPOINT", "https://api.openai.com/v1")
    api_key = System.get_env("AZURE_OPENAI_API_KEY", "")
    deployment = System.get_env("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini")
    api_version = System.get_env("AZURE_OPENAI_API_VERSION", "2024-06-01-preview")

    model = request.model || env("CHAT_MODEL", "gpt-4o-mini")
    temperature = request.temperature || parse_float(env("CHAT_TEMPERATURE", "0.7"))
    max_tokens = request.max_tokens || parse_int(env("CHAT_MAX_TOKENS", "1024"))
    timeout = ChatAI.Providers.Util.timeout_ms()

    base = endpoint |> String.trim_trailing("/")
    url = "#{base}/openai/deployments/#{deployment}/chat/completions?api-version=#{api_version}"

    payload = %{
      model: model,
      messages: Enum.map(request.messages, &%{role: &1.role, content: &1.content}),
      temperature: temperature,
      max_tokens: max_tokens
    }

    headers = [
      {"content-type", "application/json"},
      {"api-key", api_key}
    ]

    case ChatAI.Providers.HttpClient.post_json(url, headers, payload, timeout) do
      {:ok, body} -> {:ok, parse_openai_response(body, model)}
      {:error, msg} -> {:error, msg}
    end
  end

  defp parse_openai_response(body, model) do
    case Jason.decode(body) do
      {:ok, data} ->
        choices =
          case data["choices"] do
            list when is_list(list) ->
              Enum.map(list, fn c ->
                msg = c["message"] || %{}
                %{role: msg["role"] || "assistant", content: msg["content"] || ""}
              end)

            _ ->
              [ChatResponse.empty_choice()]
          end

        usage = data["usage"] || %{}

        %ChatResponse{
          id: data["id"] || "",
          provider: "azure",
          model: model,
          choices: choices,
          usage: %{
            prompt_tokens: usage["prompt_tokens"] || 0,
            completion_tokens: usage["completion_tokens"] || 0,
            total_tokens: usage["total_tokens"] || 0
          }
        }

      {:error, _} ->
        %ChatResponse{
          id: "",
          provider: "azure",
          model: model,
          choices: [ChatResponse.empty_choice()],
          usage: %{}
        }
    end
  end

  defp env(key, default), do: System.get_env(key, default)

  defp parse_float(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> 0.7
    end
  end

  defp parse_int(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> 1024
    end
  end
end
