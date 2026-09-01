defmodule ChatAI.Providers.GoogleChatProvider do
  @moduledoc """
  Google Gemini chat provider:
  `POST {base_url}/v1beta/models/{model}:generateContent?key={key}` with
  `contents[]` format.
  """
  @behaviour ChatAI.Providers.IChatProvider
  defstruct []

  alias ChatAI.{ChatRequest, ChatResponse}

  @impl true
  def complete_chat(%ChatRequest{} = request) do
    base_url = System.get_env("GOOGLE_BASE_URL", "https://generativelanguage.googleapis.com")
    api_key = System.get_env("GOOGLE_API_KEY", "")

    model = request.model || env("CHAT_MODEL", "gpt-4o-mini")
    temperature = request.temperature || parse_float(env("CHAT_TEMPERATURE", "0.7"))
    max_tokens = request.max_tokens || parse_int(env("CHAT_MAX_TOKENS", "1024"))
    timeout = ChatAI.Providers.Util.timeout_ms()

    contents =
      Enum.map(request.messages, fn m ->
        role =
          case String.downcase(m.role) do
            "assistant" -> "model"
            _ -> "user"
          end

        %{role: role, parts: [%{text: m.content}]}
      end)

    payload = %{
      contents: contents,
      generationConfig: %{temperature: temperature, maxOutputTokens: max_tokens}
    }

    base = base_url |> String.trim_trailing("/")
    url = "#{base}/v1beta/models/#{model}:generateContent?key=#{api_key}"

    headers = [{"content-type", "application/json"}]

    case ChatAI.Providers.HttpClient.post_json(url, headers, payload, timeout) do
      {:ok, body} -> {:ok, parse_google_response(body, model)}
      {:error, msg} -> {:error, msg}
    end
  end

  defp parse_google_response(body, model) do
    case Jason.decode(body) do
      {:ok, data} ->
        text =
          data["candidates"]
          |> List.wrap()
          |> List.first()
          |> Map.get("content", %{})
          |> Map.get("parts", [])
          |> Enum.map(& &1["text"])
          |> Enum.reject(&is_nil/1)
          |> Enum.join()

        usage = data["usageMetadata"] || %{}

        %ChatResponse{
          id: data["id"] || "",
          provider: "google",
          model: model,
          choices: [%{role: "model", content: text}],
          usage: %{
            prompt_tokens: usage["promptTokenCount"] || 0,
            completion_tokens: usage["candidatesTokenCount"] || 0,
            total_tokens: usage["totalTokenCount"] || 0
          }
        }

      {:error, _} ->
        %ChatResponse{
          id: "",
          provider: "google",
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
