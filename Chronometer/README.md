# Chronometer

Digital stopwatch with time controls (start, pause, resume, reset, lap) exposed as a CLI tool and a REST API with a web UI. **No persistence and no cache** — the stopwatch state lives in memory for the duration of the session.

## Architecture

The stopwatch state is a single in-memory instance. The CLI simulates stopwatch steps; the Web exposes state endpoints and operations over that same instance.

```
POST /start ──► Controller ──► Stopwatch (in-memory state) ──► { state, elapsed }
```

- **CLI**: interactive or scripted stopwatch steps (start/pause/resume/reset).
- **Web**: stateless HTTP endpoints that mutate one shared in-memory stopwatch instance.
- **Elixir (Phoenix)**: the stopwatch state is held in a supervised `GenServer`, which survives restarts under the application supervisor.

## Patterns

- No adapters (no DB, no cache).
- **Actor model (Elixir only)**: state owned by a supervised `GenServer`.

## Implementations

| Language | Cli | Web |
|---|---|---|
| PHP | — | `Web/{Laravel,Symfony}` |
| Python | `Cli/chronometer.py` | `Web/{Flask,FastAPI,Django}` |
| C# | — | — |
| Node.js | — | `Web/{NextJS,React}` |
| Ruby | — | `Web/RubyOnRails` |
| Java | `Cli` | `Web/SpringBoot` |
| Elixir | `Cli` (mix escript) | `Web/Phoenix` |

## Endpoints (Web)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Stopwatch UI (`wwwroot/index.html`) |
| `POST` | `/start` | Starts the stopwatch → `{ "state": "running" }` |
| `POST` | `/pause` | Pauses → `{ "state": "paused", "elapsed": seconds }` |
| `POST` | `/resume` | Resumes → `{ "state": "running" }` |
| `POST` | `/reset` | Resets to zero → `{ "elapsed": 0 }` |
| `GET` | `/status` | Current state + elapsed time |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Env vars

None required (no DB/cache). The web port is set via compose.

## Containers / Ports

Per framework: Flask/Spring Boot on `5000`, Laravel/Django/Rails on `8000`, NextJS/React on `3000`/`5173`, Elixir Phoenix on `4000` (`elixir:1.17-alpine`). Run with `podman compose up` from each `Web/<Impl>/` folder.

## Tests

- Python: pytest (`Cli/tests/`, `Web/*/src/tests/`)
- Node.js: Jest (`Web/*/src/tests/`)
- PHP: assert (frameworks use PHPUnit)
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test` from `Cli/` or `Web/Phoenix/src/`)

Full contract: [`Specs/Chronometer/spec.md`](../Specs/Chronometer/spec.md)
