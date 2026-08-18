defmodule ChatAIWeb.ChatControllerTest do
  use ChatAIWeb.ConnCase, async: false

  alias ChatAI.Test.MockHttp

  @openai_ok Jason.encode!(%{
               id: "chatcmpl-test",
               model: "gpt-4o-mini",
               choices: [%{message: %{role: "assistant", content: "Hello!"}}],
               usage: %{prompt_tokens: 5, completion_tokens: 3, total_tokens: 8}
             })

  @google_ok Jason.encode!(%{
               candidates: [%{content: %{role: "model", parts: [%{text: "Hi from google"}]}}],
               usageMetadata: %{promptTokenCount: 5, candidatesTokenCount: 3, totalTokenCount: 8}
             })

  @anthropic_ok Jason.encode!(%{
                  content: [%{type: "text", text: "Hi from anthropic"}],
                  usage: %{input_tokens: 5, output_tokens: 3}
                })

  setup tags do
    Application.put_env(:chatai, :http_client, MockHttp)
    MockHttp.clear()

    on_exit(fn ->
      Application.delete_env(:chatai, :http_client)
      System.delete_env("OPENAI_API_KEY")
      System.delete_env("AZURE_OPENAI_API_KEY")
      System.delete_env("GOOGLE_API_KEY")
      System.delete_env("ANTHROPIC_API_KEY")
      System.delete_env("CHAT_PROVIDER")
      System.delete_env("CHAT_FALLBACK_PROVIDER")
      System.delete_env("CHAT_TIMEOUT_MS")
      System.delete_env("RAG_ENABLED")
      System.delete_env("RAG_SEARCH_URL")
      System.delete_env("RAG_TOP_K")
    end)

    if tags[:database] == :sandbox do
      :ok
    else
      MockHttp.clear()
      :ok
    end
  end

  test "GET / returns HTML", %{conn: conn} do
    conn = get(conn, "/")
    assert conn.status == 200
  end

  test "GET /health returns ok", %{conn: conn} do
    conn = get(conn, "/health")
    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "POST /api/chat with empty messages returns 400", %{conn: conn} do
    conn = post(conn, "/api/chat", %{messages: []})
    assert json_response(conn, 400) == %{"error" => "Messages must not be empty"}
  end

  test "POST /api/chat returns assistant response with resolved provider", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    MockHttp.set_responses([{:ok, @openai_ok}])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})

    body = json_response(conn, 200)
    assert body["choices"] |> List.first() |> Map.get("role") == "assistant"
    assert body["choices"] |> List.first() |> Map.get("content") == "Hello!"
    assert body["id"] == "chatcmpl-test"
    assert body["provider"] == "openai"
    assert body["usage"]["total_tokens"] == 8
  end

  test "client overrides model/temperature/max_tokens", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    MockHttp.set_responses([{:ok, @openai_ok}])

    conn =
      post(conn, "/api/chat", %{
        messages: [%{role: "user", content: "Hi"}],
        model: "gpt-4-turbo",
        temperature: 0.2,
        max_tokens: 500
      })

    assert json_response(conn, 200)["provider"] == "openai"
    {_url, payload} = MockHttp.last_request()
    assert payload.model == "gpt-4-turbo"
    assert payload.temperature == 0.2
    assert payload.max_tokens == 500
  end

  test "openai sends correct payload", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    MockHttp.set_responses([{:ok, @openai_ok}])

    post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})

    {url, payload} = MockHttp.last_request()
    assert url == "https://api.openai.com/v1/chat/completions"
    assert payload.messages == [%{role: "user", content: "Hi"}]
  end

  test "POST /api/chat provider failure returns 502", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    MockHttp.set_responses([{:error, "Provider error: HTTP 500"}])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})
    assert conn.status == 502
  end

  test "request provider overrides CHAT_PROVIDER", %{conn: conn} do
    System.put_env("CHAT_PROVIDER", "openai")
    System.put_env("AZURE_OPENAI_API_KEY", "az-key")
    MockHttp.set_responses([{:ok, @openai_ok}])

    conn =
      post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}], provider: "azure"})

    assert json_response(conn, 200)["provider"] == "azure"
  end

  test "requested provider without API key returns 400", %{conn: conn} do
    conn =
      post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}], provider: "azure"})

    assert json_response(conn, 400) ==
             %{"error" => "Provider 'azure' is not configured (missing API key)"}
  end

  test "unsupported provider returns 400", %{conn: conn} do
    conn =
      post(conn, "/api/chat", %{
        messages: [%{role: "user", content: "Hi"}],
        provider: "not-a-provider"
      })

    assert json_response(conn, 400) == %{"error" => "Unsupported provider: not-a-provider"}
  end

  test "fallback provider is used on primary failure and returns 200", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "pk")
    System.put_env("CHAT_FALLBACK_PROVIDER", "azure")
    System.put_env("AZURE_OPENAI_API_KEY", "az")
    MockHttp.set_responses([{:error, "Provider error: HTTP 503"}, {:ok, @openai_ok}])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})
    assert json_response(conn, 200)["provider"] == "azure"
  end

  test "fallback without API key returns 502", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "pk")
    System.put_env("CHAT_FALLBACK_PROVIDER", "azure")
    MockHttp.set_responses([{:error, "Provider error: HTTP 503"}])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})
    assert conn.status == 502
  end

  test "CHAT_TIMEOUT_MS expiry returns 502", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    System.put_env("CHAT_TIMEOUT_MS", "100")

    # mock never returns -> Task.yield hits the timeout, then fallback is nil -> 502
    MockHttp.set_responses([:hang])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})
    assert conn.status == 502
  end

  test "google provider builds contents payload and normalizes response", %{conn: conn} do
    System.put_env("GOOGLE_API_KEY", "g-key")
    MockHttp.set_responses([{:ok, @google_ok}])

    conn =
      post(conn, "/api/chat", %{
        messages: [%{role: "user", content: "Hi"}],
        provider: "google"
      })

    body = json_response(conn, 200)
    assert body["provider"] == "google"
    assert body["choices"] |> List.first() |> Map.get("content") == "Hi from google"

    {url, payload} = MockHttp.last_request()
    assert url =~ "/v1beta/models/gpt-4o-mini:generateContent?key=g-key"
    assert payload.contents |> List.first() |> Map.get(:role) == "user"
  end

  test "anthropic provider sends x-api-key and normalizes response", %{conn: conn} do
    System.put_env("ANTHROPIC_API_KEY", "a-key")
    MockHttp.set_responses([{:ok, @anthropic_ok}])

    conn =
      post(conn, "/api/chat", %{
        messages: [%{role: "user", content: "Hi"}],
        provider: "anthropic"
      })

    body = json_response(conn, 200)
    assert body["provider"] == "anthropic"
    assert body["choices"] |> List.first() |> Map.get("content") == "Hi from anthropic"
    assert body["usage"]["total_tokens"] == 8
  end

  test "RAG injects context as a system message", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    System.put_env("RAG_ENABLED", "true")

    search_ok =
      Jason.encode!(%{
        results: [%{document: "Doc about X"}, %{document: "Doc about Y"}]
      })

    MockHttp.set_responses([{:ok, search_ok}, {:ok, @openai_ok}])

    conn =
      post(conn, "/api/chat", %{messages: [%{role: "user", content: "What is X?"}]})

    assert json_response(conn, 200)["choices"] |> List.first() |> Map.get("content") == "Hello!"
    {url, payload} = MockHttp.last_request()
    assert payload.messages |> List.first() |> Map.get(:role) == "system"
    assert payload.messages |> List.first() |> Map.get(:content) =~ "Doc about X"
    assert payload.messages |> List.first() |> Map.get(:content) =~ "Doc about Y"
    assert payload.messages |> List.last() |> Map.get(:content) == "What is X?"
    assert url == "https://api.openai.com/v1/chat/completions"
  end

  test "RAG disabled does not call the search service", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    MockHttp.set_responses([{:ok, @openai_ok}])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})

    assert json_response(conn, 200)["id"] == "chatcmpl-test"
    {_url, payload} = MockHttp.last_request()
    assert payload.messages == [%{role: "user", content: "Hi"}]
  end

  test "RAG search failure is fail-soft", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    System.put_env("RAG_ENABLED", "true")
    MockHttp.set_responses([{:error, "Provider error: HTTP 503"}, {:ok, @openai_ok}])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})

    assert json_response(conn, 200)["id"] == "chatcmpl-test"
    {_url, payload} = MockHttp.last_request()
    assert payload.messages == [%{role: "user", content: "Hi"}]
  end

  test "RAG no documents does not prepend a system message", %{conn: conn} do
    System.put_env("OPENAI_API_KEY", "test-key")
    System.put_env("RAG_ENABLED", "true")
    MockHttp.set_responses([{:ok, Jason.encode!(%{results: []})}, {:ok, @openai_ok}])

    conn = post(conn, "/api/chat", %{messages: [%{role: "user", content: "Hi"}]})

    assert json_response(conn, 200)["id"] == "chatcmpl-test"
    {_url, payload} = MockHttp.last_request()
    assert payload.messages == [%{role: "user", content: "Hi"}]
  end
end
