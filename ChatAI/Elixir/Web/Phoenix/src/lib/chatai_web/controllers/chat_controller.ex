defmodule ChatAIWeb.ChatController do
  use ChatAIWeb, :controller

  alias ChatAI.{ChatRequest, ChatResponse}
  alias ChatAI.Providers.ChatProviderFactory

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, Application.app_dir(:chatai, "priv/static/index.html"))
  end

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end

  def chat(conn, params) do
    request = ChatRequest.from_map(params)

    if request == nil or request.messages == [] do
      error(conn, 400, %{error: "Messages must not be empty"})
    else
      request = ChatProviderFactory.apply_rag(request)
      provider = ChatProviderFactory.resolve(request.provider)

      try do
        provider = ChatProviderFactory.create(provider)
        timeout = ChatAI.Providers.Util.timeout_ms()

        task =
          Task.async(fn ->
            provider.__struct__.complete_chat(request)
          end)

        case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
          {:ok, {:ok, response}} ->
            json(
              conn,
              ChatResponse.to_map(%{
                response
                | provider: provider_name(request, response.provider)
              })
            )

          {:ok, {:error, _msg}} ->
            fallback(conn, request)

          {:exit, _} ->
            fallback(conn, request)

          nil ->
            fallback(conn, request)
        end
      rescue
        e in ArgumentError -> error(conn, 400, %{error: e.message})
      end
    end
  end

  def swagger(conn, _params) do
    redirect(conn, to: "/swagger.html")
  end

  defp provider_name(request, provider) do
    ChatProviderFactory.resolve(request.provider || provider)
  end

  defp fallback(conn, request) do
    case ChatProviderFactory.fallback_provider() do
      nil ->
        error(conn, 502, %{error: "Provider failed"})

      fallback ->
        key = ChatProviderFactory.key_for(fallback)

        if key == nil or key == "" do
          error(conn, 502, %{error: "Provider failed"})
        else
          try do
            fb_provider = ChatProviderFactory.create(fallback)
            timeout = ChatAI.Providers.Util.timeout_ms()

            task = Task.async(fn -> fb_provider.__struct__.complete_chat(request) end)

            case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
              {:ok, {:ok, response}} ->
                json(conn, ChatResponse.to_map(%{response | provider: fallback}))

              _ ->
                error(conn, 502, %{error: "Provider failed"})
            end
          rescue
            ArgumentError -> error(conn, 502, %{error: "Provider failed"})
          end
        end
    end
  end

  defp error(conn, status, payload) do
    conn
    |> put_status(status)
    |> json(payload)
  end
end
