# ChatAI — Spec

## Purpose
AI chat API: receives a message history, sends it to an LLM provider (OpenAI-compatible) and returns the assistant response. Designed as an abstraction layer for different providers and models.

## Architecture
HTTP API that translates chat requests to an external OpenAI-compatible LLM provider (`/v1/chat/completions`). Communication with the provider is encapsulated in a concrete adapter so providers can be swapped without changing the API contract. No DB or cache.

## Implementations
- **PHP**: Web (Plain `src/index.php`)
- **Python**: Web (Plain `src/app.py`, Flask)
- **CSharp**: Web (AspNetMinimalApi `src/Program.cs`)
- **Node.js**: Web (Plain `src/server.js`, Express)
- **Ruby**: Web (Plain `src/server.rb`, WEBrick)

Each Plain implementation exposes the same endpoints, request/response contract and env vars as the C# one.

## Adapters
- **LLM**: a provider function/method that POSTs to `/v1/chat/completions`:
  - C#: `IChatProvider` interface + `OpenAiCompatibleChatProvider` (HttpClient)
  - Python: `complete_chat()` in `app.py` (urllib)
  - Node.js: `completeChat()` in `server.js` (fetch)
  - PHP: `completeChat()` in `index.php` (stream context)
  - Ruby: `complete_chat()` in `server.rb` (Net::HTTP)
- Selected via env var: `CHAT_PROVIDER` (default `openai`).

## Env vars
- `CHAT_PROVIDER` (default `openai`) — active LLM provider
- `OPENAI_API_KEY` — provider API key
- `OPENAI_BASE_URL` (default `https://api.openai.com/v1`) — OpenAI-compatible base URL
- `CHAT_MODEL` (default `gpt-4o-mini`) — default model
- `CHAT_TEMPERATURE` (default `0.7`) — generation temperature
- `CHAT_MAX_TOKENS` (default `1024`) — response token limit

## Endpoints
- `GET /` → serves the chat UI (HTML)
- `GET /health` → service status → `{ "status": "ok" }`
- `POST /api/chat` → body:
  ```json
  {
    "messages": [{ "role": "user", "content": "Hello" }],
    "model": "gpt-4o-mini",
    "temperature": 0.7,
    "max_tokens": 1024
  }
  ```
  → `200 OK`:
  ```json
  {
    "id": "chatcmpl-...",
    "model": "gpt-4o-mini",
    "choices": [{ "role": "assistant", "content": "Hello! How can I help you?" }],
    "usage": { "prompt_tokens": 5, "completion_tokens": 12, "total_tokens": 17 }
  }
  ```
  → `400` if `messages` is empty or invalid; `502` if the external provider fails.

## Behavior
- Model/params sent by the client override the server defaults.
- If `messages` is empty or null → `400 Bad Request`.
- If the external provider returns an error or does not respond → `502 Bad Gateway` with an error message.
- The web UI calls `POST /api/chat` and displays the assistant response.

## Tests
| Language | Framework | Where |
|---|---|---|
| C# | xUnit | `CSharp/Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Python/Web/Plain/src/tests/` |
| Node.js | Jest | `Node.js/Web/Plain/src/tests/` |
| PHP | asserts | `PHP/Web/Plain/src/tests/` (not runnable as-is) |
| Ruby | minitest | `Ruby/Web/Plain/src/tests/` |

Tests do not require a real API key: the HTTP provider is tested against a mock/stub. They cover:
1. `POST /api/chat` with a valid message returns the assistant response (against a mock provider).
2. `POST /api/chat` with empty `messages` returns `400`.
3. External provider failure → `502`.

## Containers / Ports
| Language | Image | Port |
|---|---|---|
| C# | `mcr.microsoft.com/dotnet/{sdk,aspnet}:9.0-alpine` | `3000:8080` |
| PHP | `php:8.2-cli` | `8000:8000` |
| Python | `python:3.11-slim` | `5000:5000` |
| Node.js | `node:20-alpine` | `3000:3000` |
| Ruby | `ruby:3.2-alpine` | `3000:3000` |

Run with Podman: `podman compose up` from each `Web/<Impl>/` folder.

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
│       │   └── OpenAiCompatibleChatProvider.cs
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
│       ├── public/index.html
│       └── tests/
├── PHP/Web/Plain/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── src/
│       ├── index.php
│       ├── template.html
│       └── tests/
└── Ruby/Web/Plain/
    ├── Dockerfile
    ├── docker-compose.yml
    └── src/
        ├── server.rb
        ├── Gemfile
        ├── template.html
        └── tests/
```
