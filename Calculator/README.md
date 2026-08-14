# Calculator

Basic arithmetic calculator (add, subtract, multiply, divide) exposed as a CLI tool and a REST API with a web UI. **No persistence and no cache** — every request is stateless.

## Architecture

A single pure `calculate` operation that receives two numbers and an operator and returns the result. The same domain logic is implemented identically across all languages: the CLI and the Web share the exact same behavior, so the CLI is the reference for the pure logic and the Web adds an HTTP + UI layer on top.

```
POST /calculate ──► Controller ──► Calculator.calculate(a, b, operator) ──► { result }
```

- **CLI**: reads two numbers and an operator, prints the result.
- **Web**: `POST /calculate` returns `{ "result": number }`; `GET /` serves the UI.

## Patterns

- No adapters (no DB, no cache, no factory).
- Same domain behavior across languages/frameworks; frameworks only change the transport.

## Implementations

| Language | Cli | Web |
|---|---|---|
| PHP | `Cli/calculator.php` | `Web/{Plain,Laravel,Symfony}` |
| Python | `Cli/calculator.py` | `Web/{Flask,FastAPI,Django}` |
| C# | `Cli/Calculator.cs` | `Web/{AspNetMinimalApi,Blazor}` |
| Node.js | `Cli/calculator.js` | `Web/{Express,NextJS,React}` |
| Ruby | `Cli/calculator.rb` | `Web/RubyOnRails` |
| Java | `Cli` | `Web/SpringBoot` |
| Elixir | `Cli` (mix escript) | `Web/Phoenix` |

## Endpoints (Web)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Calculator UI (`wwwroot/index.html`) |
| `POST` | `/calculate` | `{ "a": number, "b": number, "operator": string }` → `{ "result": number }` |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Env vars

None required (no DB/cache). The web port is set via compose.

## Containers / Ports

Per framework: Express/Flask/Spring Boot on `5000`, Laravel/Django/Rails on `8000`, NextJS/React on `3000`/`5173`, C# web on `5000` (`net9.0` Alpine images), Elixir Phoenix on `4000` (`elixir:1.17-alpine`). Run with `podman compose up` from each `Web/<Impl>/` folder.

## Tests

- C#: xUnit (`Cli/tests/`, `Web/AspNetMinimalApi/src/tests/`)
- Python: pytest (`Cli/tests/`, `Web/*/src/tests/`)
- Node.js: Jest (`Cli/tests/`, `Web/*/src/tests/`)
- PHP: assert (`Cli/tests/`, Plain Web with `php -S 127.0.0.1:8000`)
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test` from `Cli/` or `Web/Phoenix/src/`)

Full contract: [`Specs/Calculator/spec.md`](../Specs/Calculator/spec.md)
