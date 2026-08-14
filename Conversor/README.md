# Conversor

Unit converter (length, mass, temperature, simulated currency) exposed as a CLI tool and a REST API with a web UI. **No persistence and no cache** — pure, stateless conversion logic.

## Architecture

Pure conversion logic based on unit type and value. The CLI and Web share the same conversion tables (one factor table per type plus offset-based temperature rules), so the result is identical regardless of entry point.

```
POST /convert ──► Controller ──► Convert(value, from, to, type) ──► { result, unit }
```

- **CLI**: converts a value between two units of a given type.
- **Web**: `POST /convert` returns `{ "result": number, "unit": string }`; `GET /` serves the UI.

## Patterns

- No adapters (no DB, no cache).
- Shared conversion tables between CLI and Web.

## Implementations

| Language | Cli | Web |
|---|---|---|
| PHP | `Cli/conversor.php` | `Web/{Plain,Laravel,Symfony}` |
| Python | `Cli/conversor.py` | `Web/{Flask,FastAPI,Django}` |
| C# | `Cli/Conversor.cs` | `Web/AspNetMinimalApi` |
| Node.js | `Cli/conversor.js` | `Web/{Express,NextJS,React}` |
| Ruby | `Cli/conversor.rb` | `Web/RubyOnRails` |
| Java | `Cli` | `Web/SpringBoot` |
| Elixir | `Cli` (mix escript) | `Web/Phoenix` |

## Endpoints (Web)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Converter UI (`wwwroot/index.html`) |
| `POST` | `/convert` | `{ "value": number, "from": string, "to": string, "type": string }` → `{ "result": number, "unit": string }` |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

Supported types: `length`, `mass`, `temperature`, `currency`.

## Env vars

None required (no DB/cache). The web port is set via compose.

## Containers / Ports

Per framework: Express/Flask/Spring Boot on `5000`, Laravel/Django/Rails on `8000`, NextJS/React on `3000`/`5173`, C# AspNetMinimalApi on `5000`, Elixir Phoenix on `4000` (`elixir:1.17-alpine`). Run with `podman compose up` from each `Web/<Impl>/` folder.

## Tests

- C#: xUnit (`Cli/tests/`, `Web/AspNetMinimalApi/src/tests/`)
- Python: pytest (`Cli/tests/`, `Web/*/src/tests/`)
- Node.js: Jest (`Cli/tests/`, `Web/*/src/tests/`)
- PHP: assert (`Cli/tests/`, Plain Web with `php -S 127.0.0.1:8000`)
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test` from `Cli/` or `Web/Phoenix/src/`)

Full contract: [`Specs/Conversor/spec.md`](../Specs/Conversor/spec.md)
