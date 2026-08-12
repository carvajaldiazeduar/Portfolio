# Conversor — Spec

## Purpose
Unit converter (length, mass, temperature, simulated currency) exposed as an API and a CLI tool.

## Architecture
App with no persistence. Pure conversion logic based on unit type and value. Stateless between calls; the Cli and Web share the same conversion tables.

## Implementations
- **PHP**: Cli (`Cli/conversor.php`) + Web (Plain `src/index.php`, Laravel, Symfony)
- **Python**: Cli (`Cli/conversor.py`) + Web (Plain `app.py`, Flask, FastAPI, Django, Reflex)
- **CSharp**: Cli (`Cli/Conversor.cs`) + Web (AspNetMinimalApi `Program.cs`, Blazor)
- **Node.js**: Cli (`Cli/conversor.js`) + Web (Express, NextJS, React)
- **Ruby**: Cli (`Cli/conversor.rb`) + Web (RubyOnRails)
- **Java**: Cli (plain Java + JUnit 5) + Web (Spring Boot 3.3.4, Java 21)

## Adapters
None — no DB or cache.

## Env vars
None required. Web port set via compose.

## Endpoints
- `GET /` → serves `wwwroot/index.html` (UI)
- `POST /convert` → body `{ "value": number, "from": string, "to": string, "type": string }` → `{ "result": number, "unit": string }`
- Supported types: `length`, `mass`, `temperature`, `currency`
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN; FastAPI redirects to `/docs`)

## Tests
| Language | Framework | Where |
|---|---|---|
| C# Cli | xUnit | `Cli/tests/` |
| C# Web | xUnit + Mvc.Testing | `Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Cli/tests/` and `Web/*/src/tests/` |
| Node | Jest | `Cli/tests/` and `Web/*/src/tests/` |
| PHP | assert | `Cli/tests/` via `php -d zend.assertions=1 -d assert.exception=1`; Plain Web via assert + `php -S 127.0.0.1:8000 index.php` |
| Java Cli | JUnit 5 (Maven) | `Java/Cli` via `mvn test` |
| Java Web | JUnit + Spring MockMvc (Maven) | `Java/Web/SpringBoot` via `mvn test` |

## Containers / Ports
Per framework: Plain/Express/Flask on `5000`, Laravel/Django/Rails on `8000`, NextJS/React/Reflex on `3000`/`5173`.
