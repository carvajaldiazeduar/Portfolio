defmodule ChatAI.Providers.AnthropicChatProvider do
  @moduledoc """
  Anthropic chat provider:
  `POST {base_url}/v1/messages` with `x-api-key` + `anthropic-version` headers,
  `messages[]` + `content[0].text` format.
  """
  @behaviour ChatAI.Providers.IChatProvider
  defstruct []

  alias ChatAI.{ChatRequest, ChatResponse}

  @impl true
  def complete_chat(%ChatRequest{} = request) do
    base_url = System.get_env("ANTHROPIC_BASE_URL", "https://api.anthropic.com")
    api_key = System.get_env("ANTHROPIC_API_KEY", "")

    model = request.model || env("CHAT_MODEL", "gpt-4o-mini")
    temperature = request.temperature || parse_float(env("CHAT_TEMPERATURE", "0.7"))
    max_tokens = request.max_tokens || parse_int(env("CHAT_MAX_TOKENS", "1024"))
    timeout = ChatAI.Providers.Util.timeout_ms()

    {system, messages} =
      Enum.reduce(request.messages, {nil, []}, fn m, {sys, acc} ->
        case String.downcase(m.role) do
          "system" -> {m.content, acc}
          role -> {sys, acc ++ [%{role: role, content: m.content}]}
        end
      end)

    payload =
      %{model: model, messages: messages, max_tokens: max_tokens, temperature: temperature}
      |> maybe_put_system(system)

    base = base_url |> String.trim_trailing("/")
    url = "#{base}/v1/messages"

    headers = [
      {"content-type", "application/json"},
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"}
    ]

    case ChatAI.Providers.HttpClient.post_json(url, headers, payload, timeout) do
      {:ok, body} -> {:ok, parse_anthropic_response(body, model)}
      {:error, msg} -> {:error, msg}
    end
  end

  defp maybe_put_system(payload, nil), do: payload
  defp maybe_put_system(payload, ""), do: payload
  defp maybe_put_system(payload, system), do: Map.put(payload, :system, system)

  defp parse_anthropic_response(body, model) do
    case Jason.decode(body) do
      {:ok, data} ->
        content =
          case data["content"] do
            list when is_list(list) ->
              Enum.map(list, fn c ->
                case c["type"] do
                  "text" -> c["text"] || ""
                  _ -> ""
                end
              end)
              |> Enum.join()

            _ ->
              ""
          end

        usage = data["usage"] || %{}

        %ChatResponse{
          id: data["id"] || "",
          provider: "anthropic",
          model: model,
          choices: [%{role: "assistant", content: content}],
          usage: %{
            prompt_tokens: usage["input_tokens"] || 0,
            completion_tokens: usage["output_tokens"] || 0,
            total_tokens: (usage["input_tokens"] || 0) + (usage["output_tokens"] || 0)
          }
        }

      {:error, _} ->
        %ChatResponse{
          id: "",
          provider: "anthropic",
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
