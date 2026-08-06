# Chronometer — Spec

## Purpose
Stopwatch with time controls (start, pause, resume, reset, lap) exposed as an API and a CLI tool.

## Architecture
App with no persistence. The stopwatch state lives in memory during the session. The Cli simulates stopwatch steps; the Web offers state endpoints and operations over a single in-memory instance.

## Implementations
- **PHP**: Cli (`Cli/chronometer.php`) + Web (Plain `src/index.php`, Laravel, Symfony)
- **Python**: Cli (`Cli/chronometer.py`) + Web (Plain `app.py`, Flask, FastAPI, Django, Reflex)
- **CSharp**: Cli (`Cli/Chronometer.cs`) + Web (AspNetMinimalApi `Program.cs`, Blazor)
- **Node.js**: Cli (`Cli/chronometer.js`) + Web (Express, NextJS, React)
- **Ruby**: Cli (`Cli/chronometer.rb`) + Web (RubyOnRails)

## Adapters
None — no DB or cache.

## Env vars
None required. Web port set via compose.

## Endpoints
- `GET /` → serves `wwwroot/index.html` (UI)
- `POST /start` → starts the stopwatch → `{ "state": "running" }`
- `POST /pause` → pauses → `{ "state": "paused", "elapsed": seconds }`
- `POST /resume` → resumes → `{ "state": "running" }`
- `POST /reset` → resets to zero → `{ "elapsed": 0 }`
- `GET /status` → current state + elapsed time
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN; FastAPI redirects to `/docs`)

## Tests
| Language | Framework | Where |
|---|---|---|
| C# Cli | xUnit | `Cli/tests/` |
| C# Web | xUnit + Mvc.Testing | `Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Cli/tests/` and `Web/*/src/tests/` |
| Node | Jest | `Cli/tests/` and `Web/*/src/tests/` |
| PHP | PHPUnit | `Cli/tests/` (Plain PHP not runnable as-is) |

## Containers / Ports
Per framework: Plain/Express/Flask on `5000`, Laravel/Django/Rails on `8000`, NextJS/React/Reflex on `3000`/`5173`.
