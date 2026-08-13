# ChatAI — Spec

## Purpose

AI chat API: receives a message history, routes it to a configured LLM provider
(OpenAI-compatible or a native adapter), and returns the assistant response.
Designed as an **abstraction layer over multiple providers, each with its own
credentials sourced from environment variables**. No DB or cache.

## Architecture

HTTP API that translates chat requests to an external LLM provider and returns
the assistant response. The provider is resolved per-request through a
`ChatProviderFactory`:

1. `provider` field in the request body (if present) wins;
2. otherwise the `CHAT_PROVIDER` environment variable;
3. otherwise the default `openai`.

Each provider has a dedicated adapter that knows its endpoint, auth header and
request/response shape. Only the provider family is switchable; the public API
contract (`POST /api/chat`, request/response schema, status codes) is identical
across all implementations. A provider that is asked for but has no API key
configured responds with `400 Bad Request`; an upstream failure responds with
`502 Bad Gateway`.

```
POST /api/chat ──► ChatController ──► ChatProviderFactory ──► IChatProvider
                                          │ openai      ──► OpenAiCompatibleChatProvider
                                          │ openai-compatible ─► OpenAiCompatibleChatProvider  (custom base url)
                                          │ azure       ──► AzureChatProvider
                                          │ google      ──► GoogleChatProvider
                                          │ anthropic   ──► AnthropicChatProvider
```

## Implementations

- **PHP**: Web (Plain `src/index.php`)
- **Python**: Web (Plain `src/app.py`, Flask)
- **CSharp**: Web (AspNetMinimalApi `src/Program.cs`)
- **Node.js**: Web (Plain `src/server.js`, Express)
- **Ruby**: Web (Plain `src/server.rb`, WEBrick)
- **Java**: Web (Spring Boot 3.3.4, Java 21; stateless, no DB/cache)

Each Plain implementation exposes the same endpoints, request/response contract
and env vars as the C# one. The C# implementation is the reference contract.

## Adapters

- **ChatProviderFactory**: maps a provider name → a concrete `IChatProvider`
  (built from per-provider env vars). Present in C# (`Program.cs`), Node
  (`server.js`), Python (`app.py`), PHP (`index.php`), Ruby (`server.rb`) and
  Java (`ChatProviderConfig`).
- **IChatProvider** contract: `completeChat(request) -> response` (each
  language names it accordingly, e.g. `CompleteAsync` in C#,
  `complete_chat` in Python/Ruby, `completeChat` in Node/PHP,
  `completeChat` in Java).

Per-provider adapters (one class/function per provider):
  - **openai / openai-compatible** → `OpenAiCompatibleChatProvider`
    (`POST {base_url}/v1/chat/completions`, `Authorization: Bearer {key}`,
    OpenAI message/choice format).
  - **azure** → `AzureChatProvider`
    (`POST {endpoint}/openai/deployments/{deployment}/chat/completions?api-version=...`,
    `api-key` header).
  - **google** → `GoogleChatProvider`
    (`POST {base_url}/v1beta/models/{model}:generateContent?key={key}`,
    `contents[]` format).
  - **anthropic** → `AnthropicChatProvider`
    (`POST {base_url}/v1/messages`, `x-api-key` + `anthropic-version:
    2023-06-01` headers, `messages[]` + `content[0].text` format).
- Selected via the per-request `provider` field, falling back to
  `CHAT_PROVIDER`.

## Env vars

Provider selection:
- `CHAT_PROVIDER` (default `openai`) — active provider family:
  `openai`, `openai-compatible`, `azure`, `google`, `anthropic`.

Per-provider credentials (each provider reads only its own vars):
- `OPENAI_API_KEY` (+ `OPENAI_BASE_URL`, default `https://api.openai.com/v1`)
- `AZURE_OPENAI_API_KEY` (+ `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENT`)
- `GOOGLE_API_KEY` (+ `GOOGLE_BASE_URL`, default `https://generativelanguage.googleapis.com`)
- `ANTHROPIC_API_KEY` (+ `ANTHROPIC_BASE_URL`, default `https://api.anthropic.com`)

Generation defaults (apply when the client omits the field):
- `CHAT_MODEL` (default `gpt-4o-mini`)
- `CHAT_TEMPERATURE` (default `0.7`)
- `CHAT_MAX_TOKENS` (default `1024`)

Resilience and failover:
- `CHAT_TIMEOUT_MS` (default `30000`) — per-provider HTTP timeout. A provider
  that does not respond in time is cut short and the request fails with `502`
  instead of hanging the worker and other users.
- `CHAT_FALLBACK_PROVIDER` (default empty = disabled) — when the selected
  provider fails (`502`/timeout/non-2xx) and this is set with an API key
  configured, the request is retried once against it; if it also fails, `502`
  is returned as-is.

## Endpoints

- `GET /` → serves the chat UI (HTML)
- `GET /health` → `{ "status": "ok" }`
- `POST /api/chat` → body:
  ```json
  {
    "messages": [{ "role": "user", "content": "Hello" }],
    "provider": "openai",          // optional; overrides CHAT_PROVIDER
    "model": "gpt-4o-mini",        // optional; overrides CHAT_MODEL
    "temperature": 0.7,            // optional
    "max_tokens": 1024             // optional
  }
  ```
  → `200 OK`:
  ```json
  {
    "id": "chatcmpl-...",
    "provider": "openai",
    "model": "gpt-4o-mini",
    "choices": [{ "role": "assistant", "content": "Hello! How can I help you?" }],
    "usage": { "prompt_tokens": 5, "completion_tokens": 12, "total_tokens": 17 }
  }
  ```
  → `400` if `messages` is empty/invalid, **or** if the requested provider has
  no API key configured; `502` if the external provider fails.
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN)

## Behavior

- Request `provider` overrides `CHAT_PROVIDER`; `model`/`temperature`/`max_tokens`
  override the server defaults.
- If `messages` is empty or null → `400 Bad Request`.
- If the selected provider has no API key configured → `400 Bad Request`
  `{"error": "Provider '<name>' is not configured (missing API key)"}`.
- If the external provider returns an error or does not respond → `502 Bad
  Gateway` with an error message; the request is bounded by `CHAT_TIMEOUT_MS`
  (default 30 s) so a slow provider does not block other users.
- `CHAT_FALLBACK_PROVIDER` (if set and its key is configured) is attempted once
  after a provider failure before returning `502`.
- Each provider adapter normalizes its native response into the shared
  `choices[].role` / `choices[].content` + `usage` shape.
- The web UI calls `POST /api/chat` and displays the assistant response.

## Tests

| Language | Framework | Where |
|---|---|---|
| C# | xUnit | `CSharp/Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Python/Web/Plain/src/tests/` |
| Node.js | Jest | `Node.js/Web/Plain/src/tests/` |
| PHP | asserts | `PHP/Web/Plain/src/tests/` (not runnable as-is) |
| Ruby | minitest | `Ruby/Web/Plain/src/tests/` |
| Java | JUnit + Spring MockMvc (Maven) | `Java/Web/SpringBoot` via `mvn test` |

Tests do not require a real API key: the provider is tested against a mock/stub
(or a mocked factory at the controller level). They cover:

1. `POST /api/chat` with a valid message returns the assistant response
   (against a mock provider) and echoes the resolved `provider`.
2. `POST /api/chat` with empty `messages` returns `400`.
3. Request `provider` overrides `CHAT_PROVIDER`; `provider` with no key →
   `400`.
4. Provider failure or `CHAT_TIMEOUT_MS` expiry → `502`.
5. With `CHAT_FALLBACK_PROVIDER` set+keyed, a primary failure is retried once
   against the fallback (→ `200`); without a fallback key, the `502` is
   returned as-is.

## Containers / Ports

| Language | Image | Port |
|---|---|---|
| C# | `mcr.microsoft.com/dotnet/{sdk,aspnet}:9.0-alpine` | `3000:8080` |
| PHP | `php:8.2-cli` | `8000:8000` |
| Python | `python:3.11-slim` | `5000:5000` |
| Node.js | `node:20-alpine` | `3000:3000` |
| Ruby | `ruby:3.2-alpine` | `3000:3000` |
| Java | `maven:3.9-eclipse-temurin-21` build / `eclipse-temurin:21-jre-alpine` runtime | `5000:5000` |

Run with Podman: `podman compose up` from each `Web/<Impl>/` folder. Each
compose file exposes `CHAT_PROVIDER` and the OpenAI family
(`OPENAI_API_KEY`/`OPENAI_BASE_URL`) by default; the remaining provider keys
are read from the environment at runtime when set.

## Folder structure

```
ChatAI/
├── CSharp/Web/AspNetMinimalApi/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
│       ├── Program.cs
│       ├── ChatAI.csproj
│       ├── wwwroot/index.html
│       ├── Providers/
│       │   ├── IChatProvider.cs
│       │   ├── ChatProviderFactory.cs
│       │   ├── OpenAiCompatibleChatProvider.cs
│       │   ├── AzureChatProvider.cs
│       │   ├── GoogleChatProvider.cs
│       │   └── AnthropicChatProvider.cs
│       └── tests/
├── Python/Web/Plain/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
│       ├── app.py
│       ├── requirements.txt
│       ├── templates/index.html
│       └── tests/
├── Node.js/Web/Plain/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
│       ├── server.js
│       ├── package.json
│       ├── package-lock.json
│       ├── public/index.html
│       └── tests/
├── PHP/Web/Plain/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
│       ├── index.php
│       ├── template.html
│       └── tests/
├── Ruby/Web/Plain/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
│       ├── server.rb
│       ├── Gemfile
│       ├── template.html
│       └── tests/
└── Java/Web/SpringBoot/ (Dockerfile, docker-compose.yml + Spring Boot app:
    WebController/ChatController, provider/IChatProvider + ChatProviderFactory +
    OpenAi/Azure/Google/Anthropic adapters, model/{ChatRequest,Message,ChatResponse,ChatChoice,ChatUsage})
```
