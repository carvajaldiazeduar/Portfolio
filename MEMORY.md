# MEMORY — Conocimiento y aprendizajes del proyecto

Conocimiento operativo persistente entre sesiones que no pertenece a
`AGENTS.md` (reglas/convenciones) ni a `Specs/*/spec.md` (contratos).
Léelo al inicio de cada sesión y actualízalo según las reglas de la sección
"Memory" de `AGENTS.md`.

Leyenda: `[ACTIVE]` · `[KNOWN-BROKEN]` · `[WIP]` · `[RESOLVED]`

## Discrepancias spec vs código

- `[ACTIVE]` Las specs (`Specs/*/spec.md`) describen rutas `/contacts`,
  `/tasks`, etc., pero el código real usa el prefijo `/api/...`
  (verificado en PHP/Python/Node/C#/Java/Elixir). Rails no usa `/api`.
- `[ACTIVE]` Contacts: la búsqueda (`GET /api/contacts/search`) falta en
  Laravel y Django; PHP Plain no expone GET-by-id ni PUT.
- `[ACTIVE]` Inboxes: el recurso real es `/api/messages` (no `/api/inboxes`).
  Body de create varía: `{sender,subject,body}` (PHP Plain/Laravel/Python
  Plain/Django/Node Plain/Elixir) vs `{from,subject,body}` (Flask/C#/Express/Java).
  `GET /api/messages/{id}` marca el mensaje como leído.
- `[ACTIVE]` TasksList: el update es `PUT /api/tasks/{id}/complete` (10 impls)
  pero `PUT /api/tasks/{id}` (Java SpringBoot, Elixir Phoenix).
- `[ACTIVE]` PasswordGenerator: `generate` es `POST /api/generate` con body
  snake_case (9 impls), `GET /api/generate` con query camelCase (Java/Elixir) y
  `POST /generate` (Rails). El historial `GET /api/passwords` no está ruteado
  en Laravel ni Django; Rails lo renderiza solo en HTML.
- `[ACTIVE]` Rails no expone lista JSON en ningún proyecto DB (solo `root`
  HTML); los POSTs crean con body anidado (`{contact:...}`, `{message:...}`,
  `{task:...}`).

## Builds rotos / gotchas de env

- `[KNOWN-BROKEN]` Symfony Web (`Contacts/PHP/Web/Symfony`): el Dockerfile
  referencia `php bin/schema.php` que no existe → no bootea. Además `ORM.php`
  lee `DATABASE_URL`, que el compose no inyecta.
- `[KNOWN-BROKEN]` Blazor Web: no hay Dockerfile (solo compose).
- `[KNOWN-BROKEN]` NextJS/React Web: el compose monta `.:/app` y oculta el
  `package.json` del contexto → `npm run dev` crashea.
- `[KNOWN-BROKEN]` Python Plain/Flask: `app.run(debug=True)` bindea
  `127.0.0.1`, inalcanzable desde fuera del contenedor. El benchmark
  (`scripts/bench.sh`) lo sobreescribe con `host='0.0.0.0'`.
- `[ACTIVE]` Elixir Phoenix en `MIX_ENV=prod` crashea sin `SECRET_KEY_BASE`;
  el compose no la define. El benchmark la genera.
- `[ACTIVE]` Java Temurin 21.0.11: el JIT C1 crashea (SIGSEGV) en
  `ConcurrentHashMap::putVal` → forzar `-XX:-TieredCompilation` (ya en CI).
- `[ACTIVE]` mssql 2022: conexiones cifradas por defecto; `sqlcmd` requiere `-C`
  (trust server certificate).

## Decisiones registradas

- `[WIP]` Benchmark HTTP (`scripts/bench.sh` + `scripts/bench/crud.js`):
  alcance = 4 proyectos CRUD con DB (contacts, inboxes, passwords, tasks) × 12
  implementaciones Web (excluye Symfony/Blazor/NextJS/React). k6 en contenedor
  sobre red `bench-net`, Postgres 16 + Redis 7 compartidos, escenario
  data-driven por implementación. Resultados en `bench-results/` (gitignored).
  `--tag=NAME` aisla red/contenedores/resultados (`bench-results/run-NAME`)
  para correr varias instancias en paralelo.

## Log de resueltos

| Fecha | Item | Resuelto por |
|---|---|---|
| 2026-08-14 | Node.js Express + Prisma (Contacts/Inboxes/TasksList): `server.js` sin `app.listen()` → `node server.js` no abría puerto (solo tests). Añadido guard `require.main === module`. | Benchmark |