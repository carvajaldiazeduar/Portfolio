# Calculator — Spec

## Purpose
Basic arithmetic calculator (add, subtract, multiply, divide) exposed as an API and a CLI tool.

## Architecture
App with no persistence. A single `calculate` operation that receives two numbers and an operator. Implemented identically across languages (pure logic in the Cli; HTTP endpoint in the Web).

## Implementations
- **PHP**: Cli (`Cli/calculator.php`) + Web (Plain `src/index.php`, Laravel, Symfony)
- **Python**: Cli (`Cli/calculator.py`) + Web (Plain `app.py`, Flask, FastAPI, Django, Reflex)
- **CSharp**: Cli (`Cli/Calculator.cs`) + Web (AspNetMinimalApi `Program.cs`, Blazor)
- **Node.js**: Cli (`Cli/calculator.js`) + Web (Express, NextJS, React)
- **Ruby**: Cli (`Cli/calculator.rb`) + Web (RubyOnRails)

## Adapters
None — no DB or cache.

## Env vars
None required (no DB/cache). Web port set via compose.

## Endpoints
- `GET /` → serves `wwwroot/index.html` (UI)
- `POST /calculate` → body `{ "a": number, "b": number, "operator": string }` → `{ "result": number }`

## Tests
| Language | Framework | Where |
|---|---|---|
| C# Cli | xUnit | `Cli/tests/` |
| C# Web | xUnit + Mvc.Testing | `Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Cli/tests/` and `Web/*/src/tests/` |
| Node | Jest | `Cli/tests/` and `Web/*/src/tests/` |
| PHP | PHPUnit | `Cli/tests/` (Plain PHP not runnable as-is) |

## Containers / Ports
Per framework: Plain/Express/Flask on `5000`, Laravel/Django/Rails on `8000`, NextJS/React/Reflex on `3000`/`5173`. C# web uses `mcr.microsoft.com/dotnet/{sdk,aspnet}:9.0-alpine` images.
