defmodule ChatAI.Providers.HttpClient do
  @moduledoc """
  Configurable HTTP client used by chat providers.

  Dispatches to the implementation module set under `:chatai, :http_client`
  (default `ChatAI.Providers.HttpClient.HTTPC`). Tests swap in a mock.
  """

  @doc "POSTs a JSON body and returns {:ok, body} or {:error, msg} bounded by timeout."
  def post_json(url, headers, payload, timeout_ms) do
    impl = Application.get_env(:chatai, :http_client, ChatAI.Providers.HttpClient.HTTPC)
    impl.post_json(url, headers, payload, timeout_ms)
  end
end

defmodule ChatAI.Providers.HttpClient.HTTPC do
  @moduledoc """
  Real `:httpc`-backed implementation of the chat HTTP client.
  """

  def post_json(url, headers, payload, timeout_ms) do
    body = Jason.encode!(payload)
    request = {String.to_charlist(url), headers, "application/json", body}

    options = [
      timeout: timeout_ms,
      connect_timeout: timeout_ms,
      autoredirect: false,
      ssl: [{:verify, :verify_none}]
    ]

    case :httpc.request(:post, request, options, []) do
      {:ok, {{_, status, _}, _resp_headers, resp_body}} when status in 200..299 ->
        {:ok, to_string(resp_body)}

      {:ok, {{_, status, _}, _resp_headers, _resp_body}} ->
        {:error, "Provider error: HTTP #{status}"}

      {:error, reason} ->
        {:error, "Provider error: #{format_reason(reason)}"}
    end
  end

  defp format_reason(reason) when is_tuple(reason), do: inspect(reason)
  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(reason), do: to_string(reason)
end
