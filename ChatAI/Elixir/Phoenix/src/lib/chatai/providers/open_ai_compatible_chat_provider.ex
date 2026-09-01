defmodule ChatAI.Providers.OpenAiCompatibleChatProvider do
  @moduledoc """
  OpenAI-compatible chat provider: `POST {base_url}/chat/completions` with
  `Authorization: Bearer {key}`.
  """
  @behaviour ChatAI.Providers.IChatProvider
  defstruct []

  alias ChatAI.{ChatRequest, ChatResponse}

  @impl true
  def complete_chat(%ChatRequest{} = request) do
    base_url = env("OPENAI_BASE_URL", "https://api.openai.com/v1")
    api_key = env("OPENAI_API_KEY", "")

    model = request.model || env("CHAT_MODEL", "gpt-4o-mini")
    temperature = request.temperature || parse_float(env("CHAT_TEMPERATURE", "0.7"))
    max_tokens = request.max_tokens || parse_int(env("CHAT_MAX_TOKENS", "1024"))
    timeout = ChatAI.Providers.Util.timeout_ms()

    url = base_url |> String.trim_trailing("/") |> Kernel.<>("/chat/completions")

    payload = %{
      model: model,
      messages: Enum.map(request.messages, &%{role: &1.role, content: &1.content}),
      temperature: temperature,
      max_tokens: max_tokens
    }

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer " <> api_key}
    ]

    case ChatAI.Providers.HttpClient.post_json(url, headers, payload, timeout) do
      {:ok, body} -> {:ok, parse_response(body, model)}
      {:error, msg} -> {:error, msg}
    end
  end

  defp parse_response(body, model) do
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
          provider: "openai",
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
          provider: "openai",
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
