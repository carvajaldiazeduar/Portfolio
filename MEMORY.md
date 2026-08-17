# MEMORY — Project knowledge and learnings

Operational knowledge that persists across sessions and does not belong in
`AGENTS.md` (rules/conventions) nor in `Specs/*/spec.md` (behavior contracts).
Read it at the start of every session and update it according to the "Memory"
section of `AGENTS.md`.

Legend: `[ACTIVE]` · `[KNOWN-BROKEN]` · `[WIP]` · `[RESOLVED]`

## Spec vs code discrepancies

- `[ACTIVE]` The specs (`Specs/*/spec.md`) describe `/contacts`, `/tasks`,
  etc., but the real code uses the `/api/...` prefix (verified in
  PHP/Python/Node/C#/Java/Elixir). Rails does not use `/api`.
- `[ACTIVE]` Contacts: search (`GET /api/contacts/search`) is missing in
  Laravel and Django; PHP Plain does not expose GET-by-id nor PUT.
- `[ACTIVE]` Inboxes: the real resource is `/api/messages` (not `/api/inboxes`).
  Create body varies: `{sender,subject,body}` (PHP Plain/Laravel/Python
  Plain/Django/Node Plain/Elixir) vs `{from,subject,body}` (Flask/C#/Express/Java).
  `GET /api/messages/{id}` marks the message as read.
- `[ACTIVE]` TasksList: update is `PUT /api/tasks/{id}/complete` (10 impls)
  but `PUT /api/tasks/{id}` (Java SpringBoot, Elixir Phoenix).
- `[ACTIVE]` PasswordGenerator: `generate` is `POST /api/generate` with
  snake_case body (9 impls), `GET /api/generate` with camelCase query
  (Java/Elixir) and `POST /generate` (Rails). The history `GET /api/passwords`
  is not routed in Laravel nor Django; Rails renders it HTML-only.
- `[ACTIVE]` Rails does not expose a JSON list in any DB project (only `root`
  HTML); POSTs create with nested body (`{contact:...}`, `{message:...}`,
  `{task:...}`).

## Broken builds / env gotchas

- `[KNOWN-BROKEN]` Symfony Web (`Contacts/PHP/Web/Symfony`): the Dockerfile
  references `php bin/schema.php` which does not exist → does not boot. Also
  `ORM.php` reads `DATABASE_URL`, which the compose does not inject.
- `[KNOWN-BROKEN]` Blazor Web: no Dockerfile (compose only).
- `[KNOWN-BROKEN]` NextJS/React Web: the compose mounts `.:/app`, hiding the
  `package.json` from the build context → `npm run dev` crashes.
- `[KNOWN-BROKEN]` Python Plain/Flask: `app.run(debug=True)` binds
  `127.0.0.1`, unreachable from outside the container. The benchmark
  (`scripts/bench.sh`) overrides it with `host='0.0.0.0'`.
- `[ACTIVE]` Elixir Phoenix in `MIX_ENV=prod` crashes without
  `SECRET_KEY_BASE`; the compose does not define it. The benchmark generates it.
- `[ACTIVE]` Java Temurin 21.0.11: the C1 JIT crashes (SIGSEGV) in
  `ConcurrentHashMap::putVal` → force `-XX:-TieredCompilation` (already in CI).
- `[ACTIVE]` mssql 2022: encrypted connections by default; `sqlcmd` requires `-C`
  (trust server certificate).
- `[ACTIVE]` SemanticSearch Python (chromadb): the adapter caches the
  collection per process instance; after a web restart `/api/search` returns
  `[]` until at least one document is uploaded in that instance (preexisting
  quirk, not a RAG failure).

## Recorded decisions

- `[WIP]` HTTP benchmark (`scripts/bench.sh` + `scripts/bench/crud.js`):
  scope = 4 CRUD projects with DB (contacts, inboxes, passwords, tasks) × 12
  Web implementations (excludes Symfony/Blazor/NextJS/React). k6 in a container
  on the `bench-net` network, shared Postgres 16 + Redis 7, data-driven
  scenario per implementation. Results in `bench-results/` (gitignored).
  `--tag=NAME` isolates network/containers/results (`bench-results/run-NAME`)
  to run several instances in parallel.
- `[ACTIVE]` ChatAI RAG: retrieval over HTTP to SemanticSearch
  (`RAG_ENABLED`/`RAG_SEARCH_URL`/`RAG_TOP_K`), injects docs as a `system`
  message and is fail-soft. Reference = Python (Web/Plain). Ported to all
  languages (Node/PHP/Ruby/C#/Java/Elixir). Limitation: SemanticSearch
  embeddings are dummy (`[0.0]*VECTOR_DIMENSION`) → search relevance is a
  placeholder.

## Resolved log

| Date | Item | Resolved by |
|---|---|---|
| 2026-08-17 | SemanticSearch Python: the Dockerfile copied `src/requirements.txt` (path does not exist; file is at repo root) → compose build failed. Fixed to `COPY requirements.txt`. | ChatAI RAG e2e |
| 2026-08-17 | SemanticSearch Python: `/api/search` cached the bare `results` list instead of `{query, results}` → inconsistent response shape that broke ChatAI RAG `retrieve_context`. Fixed to cache the full payload (matches spec). | ChatAI RAG e2e |
| 2026-08-14 | Node.js Express + Prisma (Contacts/Inboxes/TasksList): `server.js` without `app.listen()` → `node server.js` did not open a port (tests only). Added `require.main === module` guard. | Benchmark |
