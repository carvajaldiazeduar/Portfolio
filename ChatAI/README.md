# ChatAI

AI chat API: receives a message history, routes it to a configured LLM provider (OpenAI-compatible, Azure, Google, Anthropic) and returns the assistant response. Designed as an **abstraction layer over multiple providers**, each with its own credentials sourced from environment variables. **Stateless — no DB or cache.**

## Architecture

HTTP API that translates chat requests to an external LLM provider and returns the assistant response in a normalized shape. The provider is resolved per request through a `ChatProviderFactory`:

```
POST /api/chat ──► ChatController ──► ChatProviderFactory ──► IChatProvider
                                          │ openai      ──► OpenAiCompatibleChatProvider
                                          │ openai-compatible ─► OpenAiCompatibleChatProvider  (custom base url)
                                          │ azure       ──► AzureChatProvider
                                          │ google      ──► GoogleChatProvider
                                          │ anthropic   ──► AnthropicChatProvider
```

Provider resolution per request:

1. `provider` field in the request body (if present) wins;
2. otherwise the `CHAT_PROVIDER` environment variable;
3. otherwise the default `openai`.

Each provider adapter knows its own endpoint, auth header and request/response format, and normalizes the provider's native reply into a shared `choices[].role` / `choices[].content` + `usage` shape. In Elixir (Phoenix) provider HTTP calls are bounded with `Task.async`/`Task.yield(timeout)` for `CHAT_TIMEOUT_MS`.

## Patterns

- **Strategy/Adapter**: one class/function per provider implementing the `IChatProvider` contract (`completeChat(request) -> response`).
- **Factory**: `ChatProviderFactory` maps a provider name → concrete provider.
- Public API contract (endpoints, request/response schema, status codes) is identical across all implementations — only the provider family is switchable.

## Implementations

| Language | Web |
|---|---|
| C# | `Web/AspNetMinimalApi` (reference contract) |
| Python | `Web/Plain` (`app.py`) |
| Node.js | `Web/Plain` (`server.js`) |
| PHP | `Web/Plain` (`index.php`) |
| Ruby | `Web/Plain` (`server.rb`, WEBrick) |
| Java | `Web/SpringBoot` (`ChatProviderConfig`) |
| Elixir | `Web/Phoenix` (`ChatProviderFactory` + `lib/<app>/providers/`) |

Each Plain implementation exposes the same endpoints, request/response contract and env vars as the C# one.

### Per-provider adapters

| Provider | Endpoint | Auth |
|---|---|---|
| `openai` / `openai-compatible` | `POST {base_url}/v1/chat/completions` | `Authorization: Bearer {key}` |
| `azure` | `POST {endpoint}/openai/deployments/{deployment}/chat/completions?api-version=...` | `api-key` header |
| `google` | `POST {base_url}/v1beta/models/{model}:generateContent?key={key}` | `key` query param |
| `anthropic` | `POST {base_url}/v1/messages` | `x-api-key` + `anthropic-version: 2023-06-01` |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Chat UI (HTML) |
| `GET` | `/health` | Liveness → `{"status": "ok"}` |
| `POST` | `/api/chat` | Chat completion (see below) |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

`POST /api/chat` request:

```json
{
  "messages": [{ "role": "user", "content": "Hello" }],
  "provider": "openai",       // optional; overrides CHAT_PROVIDER
  "model": "gpt-4o-mini",     // optional; overrides CHAT_MODEL
  "temperature": 0.7,         // optional
  "max_tokens": 1024          // optional
}
```

Response (`200 OK`):

```json
{
  "id": "chatcmpl-...",
  "provider": "openai",
  "model": "gpt-4o-mini",
  "choices": [{ "role": "assistant", "content": "Hello! How can I help you?" }],
  "usage": { "prompt_tokens": 5, "completion_tokens": 12, "total_tokens": 17 }
}
```

## Error handling

- `400` if `messages` is empty/invalid, or the requested provider has no API key configured (`{"error": "Provider '<name>' is not configured (missing API key)"}`).
- `502` if the upstream provider fails or does not respond within `CHAT_TIMEOUT_MS`.
- `CHAT_FALLBACK_PROVIDER` (if set and its key is configured) is retried once after a provider failure before returning `502`.

## Env vars

| Variable | Default | Purpose |
|---|---|---|
| `CHAT_PROVIDER` | `openai` | Active provider family: `openai`, `openai-compatible`, `azure`, `google`, `anthropic` |
| `OPENAI_API_KEY` / `OPENAI_BASE_URL` | `https://api.openai.com/v1` | OpenAI / OpenAI-compatible credentials |
| `AZURE_OPENAI_API_KEY` / `AZURE_OPENAI_ENDPOINT` / `AZURE_OPENAI_DEPLOYMENT` | — | Azure OpenAI credentials |
| `GOOGLE_API_KEY` / `GOOGLE_BASE_URL` | `https://generativelanguage.googleapis.com` | Google Gemini credentials |
| `ANTHROPIC_API_KEY` / `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` | Anthropic credentials |
| `CHAT_MODEL` | `gpt-4o-mini` | Default model |
| `CHAT_TEMPERATURE` | `0.7` | Default temperature |
| `CHAT_MAX_TOKENS` | `1024` | Default max tokens |
| `CHAT_TIMEOUT_MS` | `30000` | Per-provider HTTP timeout |
| `CHAT_FALLBACK_PROVIDER` | _(disabled)_ | Fallback provider retried once on failure |

Each provider reads only its own env vars; a compose file that only sets `OPENAI_API_KEY` works out of the box, while the other provider keys are read from the environment when set.

## Containers / Ports

| Language | Image | Port |
|---|---|---|
| C# | `mcr.microsoft.com/dotnet/{sdk,aspnet}:9.0-alpine` | `3000:8080` |
| PHP | `php:8.2-cli` | `8000:8000` |
| Python | `python:3.11-slim` | `5000:5000` |
| Node.js | `node:20-alpine` | `3000:3000` |
| Ruby | `ruby:3.2-alpine` | `3000:3000` |
| Java | `maven:3.9-eclipse-temurin-21` build / `eclipse-temurin:21-jre-alpine` runtime | `5000:5000` |
| Elixir | `elixir:1.17-alpine` | `4000:4000` |

Run with `podman compose up` from each `Web/<Impl>/` folder.

## Tests

Tests do not require a real API key: the provider is tested against a mock/stub (or a mocked factory at the controller level). They cover:

1. `POST /api/chat` with a valid message returns the assistant response (against a mock provider) and echoes the resolved `provider`.
2. `POST /api/chat` with empty `messages` returns `400`.
3. Request `provider` overrides `CHAT_PROVIDER`; `provider` with no key → `400`.
4. Provider failure or `CHAT_TIMEOUT_MS` expiry → `502`.
5. With `CHAT_FALLBACK_PROVIDER` set+keyed, a primary failure is retried once against the fallback (→ `200`); without a fallback key, the `502` is returned as-is.

| Language | Framework | Where |
|---|---|---|
| C# | xUnit | `CSharp/Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Python/Web/Plain/src/tests/` |
| Node.js | Jest | `Node.js/Web/Plain/src/tests/` |
| PHP | asserts | `PHP/Web/Plain/src/tests/` |
| Ruby | minitest | `Ruby/Web/Plain/src/tests/` |
| Java | JUnit + Spring MockMvc | `Java/Web/SpringBoot` (`mvn test`) |
| Elixir | ExUnit + Phoenix.ConnTest | `Elixir/Web/Phoenix/src` (`mix test`) |

Full contract: [`Specs/ChatAI/spec.md`](../Specs/ChatAI/spec.md)
