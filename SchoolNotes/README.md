# SchoolNotes

School gradebook (CRUD) over six entities — students, teachers, courses, periods, enrollments and grades — secured with **JWT + Cookie authentication**, **rate limiting** and the usual **database + cache** pattern. Currently implemented in C# (AspNetMinimalApi).

## Architecture

```
Browser / UI ──► RateLimitMiddleware ──► Auth (JWT Bearer + Cookie)
                     │
                     ▼
            MapEntity<T> endpoints (generic CRUD)
                     │
                     ▼
            CrudService<T> (validation)  ──►  EF Core ──► PostgreSQL
                     │
              ICacheAdapter (Redis / Local)
```

- **Generic CRUD**: a single `MapEntity<T>` extension maps the six entities (`students`, `teachers`, `courses`, `periods`, `enrollments`, `grades`), each backed by its own `CrudService<T>`.
- **Auth**: `POST /api/auth/login` validates bcrypt-hashed credentials and signs both a JWT (`Lasts 8h`) and a cookie. Every `/api` route requires authentication (`JWT Bearer` or `Cookie`). An admin user is seeded on first boot from `ADMIN_USERNAME`/`ADMIN_PASSWORD`.
- **Rate limiting**: a `RateLimitMiddleware` counts requests per client IP in the cache (`RATE_LIMIT_MAX` per `RATE_LIMIT_WINDOW`) and answers `429` when exceeded.
- **Cache**: two-level `ICacheAdapter` (`CacheComposite`: Redis primary, Local fallback). GET lists/details are cached; writes invalidate the entity prefix automatically.
- **Validation**: per-entity validators; unique indexes (`student.code`, `teacher.code`, `enrollment {student,course,period}`) and FK `Restrict` rules surface as `409 Conflict` on `DbUpdateException`.

## Patterns

- **Adapter** for cache (`ICacheAdapter` + `CacheFactory` via `CACHE_TYPE`) with Redis + Local composite fallback.
- **Generic service + validation** layer reused across all six entities.
- **Factory** for cache selection; backend-agnostic DB config via env vars.

## Implementations

| Language | Frameworks |
|---|---|
| C# | AspNetMinimalApi |

## Data model

| Entity | Fields |
|---|---|
| `Student` | `id`, `firstName`, `lastName`, `code` (unique), `email` |
| `Teacher` | `id`, `firstName`, `lastName`, `code` (unique), `email` |
| `Course` | `id`, `name`, `teacherId` (FK restrict) |
| `Period` | `id`, `name`, `startDate`, `endDate` |
| `Enrollment` | `id`, `studentId`, `courseId`, `periodId` (FK restrict; unique {student, course, period}) |
| `Grade` | `id`, `enrollmentId` (FK cascade), `label`, `score`, `maxScore` (default `100`), `observation` |
| `User` | `id`, `username` (unique), `passwordHash` (bcrypt), `role` — auth only, not exposed |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | UI |
| `POST` | `/api/auth/login` | `{ "username", "password" }` → `{ "ok": true, "token" }` + auth cookie |
| `POST` | `/api/auth/logout` | Signs out the cookie session |
| `GET` | `/api/{entity}` | Paged list (`?page=&pageSize=`, default `1`/`10`, max `100`), cached |
| `GET` | `/api/{entity}/{id}` | Detail, cached |
| `POST` | `/api/{entity}` | Create → `201 Created`; `400` validation / `409` conflict |
| `PUT` | `/api/{entity}/{id}` | Update → `200`; `404` / `400` / `409` |
| `DELETE` | `/api/{entity}/{id}` | Delete → `204`; `409` if referenced by another record |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec (Bearer security defined) |
| `GET` | `/swagger` | Swagger UI |

`entity` ∈ `students | teachers | courses | periods | enrollments | grades`. All `/api` routes require authentication.

## Env vars

```
DB_DRIVER=pgsql              # pgsql (default) | mysql | sqlserver | mongodb
DB_HOST=db
DB_PORT=5432
DB_NAME=schoolnotes
DB_USER=postgres
DB_PASSWORD=postgres

CACHE_TYPE=redis             # redis (default) | local
REDIS_HOST=redis:6379

CORS_ORIGINS=                # comma-separated allow-list (empty = allow any)
RATE_LIMIT_MAX=100           # requests per IP per window
RATE_LIMIT_WINDOW=60         # seconds
JWT_SECRET=...               # HMAC key for the JWT
ADMIN_USERNAME=admin         # seeded on first boot
ADMIN_PASSWORD=admin         # seeded on first boot
```

## Containers / Ports

Compose starts PostgreSQL (`5432`) + Redis (`6379`) + `web` on host port `5006:5000` (`.NET 10 Alpine`). The admin user is seeded automatically. Run with `podman compose up` from `DotNet/AspNetMinimalApi/`.

## Tests

- C#: xUnit (`dotnet test`) — `ValidatorsTests`, `ServiceTests`, `CacheTests`, `AuthServiceTests` (EF Core InMemory provider).

Run the suite with no host toolchain (Podman only), from the implementation folder:

```bash
# .NET
podman run --rm -v "$(pwd):/app" -w /app/src mcr.microsoft.com/dotnet/sdk:10.0-alpine dotnet test tests/<Name>.Tests.csproj -c Release
```