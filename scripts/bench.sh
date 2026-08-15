#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCH_DIR="$ROOT/scripts/bench"
RESULTS_BASE="$ROOT/bench-results"
K6_IMAGE="docker.io/grafana/k6"
BUSYBOX_IMAGE="docker.io/library/busybox:latest"

TAG=""
CT_PREFIX="bench"
NET="bench-net"
RESULTS_DIR="$RESULTS_BASE"
PG_CT="bench-db"
REDIS_CT="bench-redis"

VUS="${BENCH_VUS:-20}"
DURATION="${BENCH_DURATION:-30s}"
SEED="${BENCH_SEED:-100}"
PROJECTS_FILTER="all"
IMPLS_FILTER="all"
SKIP_BUILD=0
REBUILD=0
LIST_ONLY=0

ALL_PROJECTS="contacts inboxes passwords tasks"
ALL_SLUGS="php-plain php-laravel py-plain py-flask py-fastapi py-django cs-minapi node-express node-plain ruby-rails java-spring elixir-phoenix"

usage() {
  cat <<EOF
Usage: $0 [options]

HTTP benchmark (k6 + Podman) for the database-backed CRUD projects
(contacts, inboxes, passwords, tasks) across their Web implementations.

Options:
  --projects=a,b     projects to run (default: all)
  --impls=a,b        implementations to run (default: all)
  --vu=N             k6 virtual users (default: 20, env BENCH_VUS)
  --duration=STR     k6 duration (default: 30s, env BENCH_DURATION)
  --seed=N           records created before the load (default: 100)
  --skip-build       reuse existing bench images (no podman build)
  --rebuild          force image rebuild
  --tag=NAME         isolate this run (own network, containers, results dir);
                     allows running bench.sh several times in parallel
  --list             list available project/impl combos and exit
  -h, --help         show this help

Project -> database/table:
  contacts -> contacts, inboxes -> inboxes/messages,
  passwords -> passwords/password_entries, tasks -> tasks/tasks
EOF
}

parse_args() {
  for a in "$@"; do
    case "$a" in
      --projects=*) PROJECTS_FILTER="${a#*=}" ;;
      --impls=*)    IMPLS_FILTER="${a#*=}" ;;
      --vu=*)       VUS="${a#*=}" ;;
      --duration=*) DURATION="${a#*=}" ;;
      --seed=*)     SEED="${a#*=}" ;;
      --skip-build) SKIP_BUILD=1 ;;
      --rebuild)    REBUILD=1 ;;
      --tag=*)      TAG="${a#*=}" ;;
      --list)       LIST_ONLY=1 ;;
      -h|--help)    usage; exit 0 ;;
      *) echo "Unknown option: $a"; usage; exit 1 ;;
    esac
  done
}

contains() {
  local list="$1" item="$2" w
  for w in $list; do
    [ "$w" = "$item" ] && return 0
  done
  return 1
}

expand_filter() {
  local filter="$1" all="$2" out=""
  if [ "$filter" = "all" ]; then echo "$all"; return; fi
  for x in $(echo "$filter" | tr ',' ' '); do
    if ! contains "$all" "$x"; then echo "WARN: unknown item '$x' (valid: $all)" >&2; continue; fi
    out="$out $x"
  done
  echo "${out# }"
}

ensure_image() { podman image exists "$1" || podman pull "$1"; }

proj_db() {
  case "$1" in
    contacts) echo contacts ;;
    inboxes)  echo inboxes ;;
    passwords) echo passwords ;;
    tasks)    echo tasks ;;
    *) echo "" ;;
  esac
}

proj_dir() {
  case "$1" in
    contacts) echo Contacts ;;
    inboxes)  echo Inboxes ;;
    passwords) echo PasswordGenerator ;;
    tasks)    echo TasksList ;;
    *) echo "" ;;
  esac
}

proj_table() {
  case "$1" in
    contacts) echo contacts ;;
    inboxes)  echo messages ;;
    passwords) echo password_entries ;;
    tasks)    echo tasks ;;
    *) echo "" ;;
  esac
}

# app_info <slug> -> sets APP_LANG APP_FW APP_PORT APP_SERVER
app_info() {
  local slug="$1"
  case "$slug" in
    php-plain)      APP_LANG=PHP;   APP_FW="Web/Plain";         APP_PORT=8000; APP_SERVER="php -S (dev)" ;;
    php-laravel)    APP_LANG=PHP;   APP_FW="Web/Laravel";       APP_PORT=8000; APP_SERVER="artisan (dev)" ;;
    py-plain)       APP_LANG=Python; APP_FW="Web/Plain";        APP_PORT=5000; APP_SERVER="Flask (dev)" ;;
    py-flask)       APP_LANG=Python; APP_FW="Web/Flask";        APP_PORT=5000; APP_SERVER="Flask (dev)" ;;
    py-fastapi)     APP_LANG=Python; APP_FW="Web/FastAPI";      APP_PORT=8000; APP_SERVER="Uvicorn (prod)" ;;
    py-django)      APP_LANG=Python; APP_FW="Web/Django";       APP_PORT=8000; APP_SERVER="runserver (dev)" ;;
    cs-minapi)      APP_LANG=CSharp; APP_FW="Web/AspNetMinimalApi"; APP_PORT=5000; APP_SERVER="Kestrel (prod)" ;;
    node-express)   APP_LANG=Node.js; APP_FW="Web/Express";     APP_PORT=3000; APP_SERVER="Express (prod)" ;;
    node-plain)     APP_LANG=Node.js; APP_FW="Web/Plain";       APP_PORT=3000; APP_SERVER="Express (prod)" ;;
    ruby-rails)     APP_LANG=Ruby;   APP_FW="Web/RubyOnRails";  APP_PORT=3000; APP_SERVER="Puma (prod)" ;;
    java-spring)    APP_LANG=Java;   APP_FW="Web/SpringBoot";   APP_PORT=5000; APP_SERVER="Tomcat (prod)" ;;
    elixir-phoenix) APP_LANG=Elixir; APP_FW="Web/Phoenix";      APP_PORT=4000; APP_SERVER="Bandit (prod)" ;;
    *) return 1 ;;
  esac
}

app_env() {
  local proj="$1" slug="$2"
  local db; db="$(proj_db "$proj")"
  local base="DB_DRIVER=pgsql DB_HOST=$PG_CT DB_PORT=5432 DB_NAME=$db DB_USER=postgres DB_PASSWORD=postgres"
  base="$base CACHE_TYPE=redis REDIS_HOST=$REDIS_CT:6379 REDIS_PORT=6379 REDIS_URL=redis://$REDIS_CT:6379"
  case "$slug" in
    php-laravel)  base="$base APP_KEY=base64:$(openssl rand -base64 32) APP_ENV=local APP_DEBUG=true" ;;
    node-express) base="$base DATABASE_URL=postgresql://postgres:postgres@$PG_CT:5432/$db" ;;
    elixir-phoenix) base="$base SECRET_KEY_BASE=$(openssl rand -hex 32) PORT=$APP_PORT" ;;
  esac
  echo "$base"
}

# project_ops <proj> <slug> -> JSON ops array
project_ops() {
  local proj="$1" slug="$2"
  case "$proj" in
    contacts)
      case "$slug" in
        php-laravel|py-django)
          printf '%s' '[{"name":"create","method":"POST","path":"/api/contacts","weight":45,"body":"{\"name\":\"{{name}}\",\"phone\":\"{{phone}}\",\"email\":\"{{email}}\"}"},{"name":"list","method":"GET","path":"/api/contacts","weight":30},{"name":"delete","method":"DELETE","path":"/api/contacts/{id}","weight":25,"usesId":true}]'
          ;;
        ruby-rails)
          printf '%s' '[{"name":"create","method":"POST","path":"/contacts","weight":55,"body":"{\"contact\":{\"name\":\"{{name}}\",\"phone\":\"{{phone}}\",\"email\":\"{{email}}\"}}"},{"name":"delete","method":"DELETE","path":"/contacts/{id}","weight":45,"usesId":true}]'
          ;;
        *)
          printf '%s' '[{"name":"create","method":"POST","path":"/api/contacts","weight":40,"body":"{\"name\":\"{{name}}\",\"phone\":\"{{phone}}\",\"email\":\"{{email}}\"}"},{"name":"list","method":"GET","path":"/api/contacts","weight":25},{"name":"search","method":"GET","path":"/api/contacts/search","weight":15,"query":"q={{q}}"},{"name":"delete","method":"DELETE","path":"/api/contacts/{id}","weight":20,"usesId":true}]'
          ;;
      esac
      ;;
    inboxes)
      case "$slug" in
        py-flask|cs-minapi|node-express|java-spring)
          printf '%s' '[{"name":"create","method":"POST","path":"/api/messages","weight":40,"body":"{\"from\":\"{{from}}\",\"subject\":\"{{subject}}\",\"body\":\"{{body}}\"}"},{"name":"getbyid","method":"GET","path":"/api/messages/{id}","weight":25,"usesId":true},{"name":"list","method":"GET","path":"/api/messages","weight":15},{"name":"delete","method":"DELETE","path":"/api/messages/{id}","weight":20,"usesId":true}]'
          ;;
        ruby-rails)
          printf '%s' '[{"name":"create","method":"POST","path":"/messages","weight":45,"body":"{\"message\":{\"sender\":\"{{sender}}\",\"subject\":\"{{subject}}\",\"body\":\"{{body}}\"}}"},{"name":"getbyid","method":"GET","path":"/messages/{id}","weight":30,"usesId":true},{"name":"delete","method":"DELETE","path":"/messages/{id}","weight":25,"usesId":true}]'
          ;;
        *)
          printf '%s' '[{"name":"create","method":"POST","path":"/api/messages","weight":40,"body":"{\"sender\":\"{{sender}}\",\"subject\":\"{{subject}}\",\"body\":\"{{body}}\"}"},{"name":"getbyid","method":"GET","path":"/api/messages/{id}","weight":25,"usesId":true},{"name":"list","method":"GET","path":"/api/messages","weight":15},{"name":"delete","method":"DELETE","path":"/api/messages/{id}","weight":20,"usesId":true}]'
          ;;
      esac
      ;;
    tasks)
      case "$slug" in
        java-spring|elixir-phoenix)
          printf '%s' '[{"name":"create","method":"POST","path":"/api/tasks","weight":40,"body":"{\"title\":\"{{title}}\"}"},{"name":"list","method":"GET","path":"/api/tasks","weight":15},{"name":"update","method":"PUT","path":"/api/tasks/{id}","weight":25,"usesId":true,"body":"{\"completed\":true}"},{"name":"delete","method":"DELETE","path":"/api/tasks/{id}","weight":20,"usesId":true}]'
          ;;
        ruby-rails)
          printf '%s' '[{"name":"create","method":"POST","path":"/tasks","weight":45,"body":"{\"task\":{\"title\":\"{{title}}\"}}"},{"name":"update","method":"PUT","path":"/tasks/{id}/complete","weight":30,"usesId":true},{"name":"delete","method":"DELETE","path":"/tasks/{id}","weight":25,"usesId":true}]'
          ;;
        *)
          printf '%s' '[{"name":"create","method":"POST","path":"/api/tasks","weight":40,"body":"{\"title\":\"{{title}}\"}"},{"name":"list","method":"GET","path":"/api/tasks","weight":15},{"name":"update","method":"PUT","path":"/api/tasks/{id}/complete","weight":25,"usesId":true},{"name":"delete","method":"DELETE","path":"/api/tasks/{id}","weight":20,"usesId":true}]'
          ;;
      esac
      ;;
    passwords)
      case "$slug" in
        ruby-rails)
          printf '%s' '[{"name":"generate","method":"POST","path":"/generate","weight":100,"form":true,"body":"{\"length\":\"{{length}}\",\"use_upper\":\"1\",\"use_lower\":\"1\",\"use_digits\":\"1\",\"use_symbols\":\"{{flag}}\"}"}]'
          ;;
        java-spring|elixir-phoenix)
          printf '%s' '[{"name":"generate","method":"GET","path":"/api/generate","weight":60,"query":"length={{length}}&uppercase=true&lowercase=true&numbers=true&symbols={{symbols}}"},{"name":"history","method":"GET","path":"/api/passwords","weight":25},{"name":"delete","method":"DELETE","path":"/api/passwords/{id}","weight":15,"usesId":true}]'
          ;;
        php-laravel|py-django)
          printf '%s' '[{"name":"generate","method":"POST","path":"/api/generate","weight":100,"body":"{\"length\":{{length}},\"use_upper\":true,\"use_lower\":true,\"use_digits\":true,\"use_symbols\":{{use_symbols}}}"}]'
          ;;
        *)
          printf '%s' '[{"name":"generate","method":"POST","path":"/api/generate","weight":60,"body":"{\"length\":{{length}},\"use_upper\":true,\"use_lower\":true,\"use_digits\":true,\"use_symbols\":{{use_symbols}}}"},{"name":"history","method":"GET","path":"/api/passwords","weight":25}]'
          ;;
      esac
      ;;
    *)
      echo "[]"
      ;;
  esac
}

impl_config() {
  local proj="$1" slug="$2"
  local ops
  ops="$(project_ops "$proj" "$slug" | jq -c .)"
  jq -n --arg project "$proj" --arg impl "$slug" --arg server "$APP_SERVER" \
    --arg host "$CT_PREFIX-$proj-$slug" --argjson port "$APP_PORT" --argjson seed "$SEED" \
    --argjson ops "$ops" \
    '{project:$project,impl:$impl,server:$server,host:$host,port:$port,seed:$seed,ops:$ops}'
}

infra_up() {
  echo ">>> Infra: Postgres 16 + Redis 7 + k6 on $NET"
  for c in $(podman ps -aq --filter name="^$CT_PREFIX-" 2>/dev/null); do
    podman rm -f "$c" >/dev/null 2>&1 || true
  done
  podman network rm "$NET" >/dev/null 2>&1 || true
  podman network create "$NET" >/dev/null 2>&1 || true

  ensure_image docker.io/library/postgres:16
  podman run -d --name "$PG_CT" --network "$NET" \
    -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres \
    docker.io/library/postgres:16 >/dev/null
  ready=0
  for _ in $(seq 1 90); do
    podman exec "$PG_CT" pg_isready -U postgres >/dev/null 2>&1 && { ready=1; break; }
    sleep 1
  done
  [ "$ready" = 1 ] || { echo "ERROR: Postgres did not become ready"; exit 1; }
  for db in $ALL_PROJECTS; do
    podman exec "$PG_CT" psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1 \
      || podman exec "$PG_CT" psql -U postgres -c "CREATE DATABASE $db" >/dev/null
  done

  ensure_image docker.io/library/redis:7-alpine
  podman run -d --name "$REDIS_CT" --network "$NET" docker.io/library/redis:7-alpine >/dev/null
  ready=0
  for _ in $(seq 1 30); do
    podman exec "$REDIS_CT" redis-cli ping 2>/dev/null | grep -q PONG && { ready=1; break; }
    sleep 1
  done
  [ "$ready" = 1 ] || { echo "ERROR: Redis did not become ready"; exit 1; }

  ensure_image "$BUSYBOX_IMAGE"
  ensure_image "$K6_IMAGE"
}

build_app() {
  local proj="$1" slug="$2"
  local img="bench-$proj-$slug" dir="$ROOT/$(proj_dir "$proj")/$APP_LANG/$APP_FW"
  if [ "$SKIP_BUILD" = 1 ]; then
    podman image exists "$img" || { echo "ERROR: --skip-build but image $img missing"; return 1; }
    return 0
  fi
  if [ "$REBUILD" = 0 ] && podman image exists "$img"; then
    return 0
  fi
  [ -f "$dir/Dockerfile" ] || { echo "ERROR: no Dockerfile in $dir"; return 1; }
  echo ">>> build $img from $dir"
  podman build -q -t "$img" "$dir"
}

drop_table() {
  local proj="$1" db table
  db="$(proj_db "$proj")"; table="$(proj_table "$proj")"
  podman exec "$PG_CT" psql -U postgres -d "$db" -c "DROP TABLE IF EXISTS \"$table\" CASCADE" >/dev/null 2>&1 || true
}

wait_app() {
  local cname="$1" port="$2"
  local url="http://$cname:$port/"
  local ready=0
  for _ in $(seq 1 180); do
    if podman run --rm --network "$NET" "$BUSYBOX_IMAGE" wget -q -T 2 -O /dev/null "$url" >/dev/null 2>&1; then
      ready=1; break
    fi
    sleep 1
  done
  if [ "$ready" != 1 ]; then
    echo "ERROR: app not ready: $cname ($url)"
    podman logs --tail 40 "$cname" 2>&1 || true
    return 1
  fi
}

run_app() {
  local proj="$1" slug="$2"
  local cname="$CT_PREFIX-$proj-$slug" img="bench-$proj-$slug"
  podman rm -f "$cname" >/dev/null 2>&1 || true
  local envs; envs="$(app_env "$proj" "$slug")"
  local args=()
  for kv in $envs; do args+=( -e "$kv" ); done
  if [ "$slug" = "py-plain" ] || [ "$slug" = "py-flask" ]; then
    podman run -d --name "$cname" --network "$NET" "${args[@]}" "$img" \
      python -c "import app; app.app.run(host='0.0.0.0', port=$APP_PORT, debug=False)" >/dev/null
  else
    podman run -d --name "$cname" --network "$NET" "${args[@]}" "$img" >/dev/null
  fi
  wait_app "$cname" "$APP_PORT"
}

run_k6() {
  local proj="$1" slug="$2"
  local config; config="$(impl_config "$proj" "$slug")"
  mkdir -p "$RESULTS_DIR"
  local out="$RESULTS_DIR/$proj-$slug.json"
  local log="$RESULTS_DIR/$proj-$slug.k6.log"
  printf '%s\n' "$config" > "$RESULTS_DIR/$proj-$slug.cfg.json"
  echo ">>> k6 $proj/$slug (vus=$VUS duration=$DURATION seed=$SEED)"
  podman run --rm --user root --network "$NET" \
    -v "$BENCH_DIR:/bench:ro" \
    -v "$RESULTS_DIR:/out" \
    -e CONFIG_FILE="/out/$proj-$slug.cfg.json" \
    -e BENCH_VUS="$VUS" \
    -e BENCH_DURATION="$DURATION" \
    -e BENCH_OUT="/out/$proj-$slug.json" \
    "$K6_IMAGE" run /bench/crud.js >"$log" 2>&1
  [ -f "$out" ] || { echo "ERROR: no result file for $proj/$slug (see $log)"; return 1; }
}

report() {
  local fmt="%-12s %-14s %-14s %8s %8s %8s %8s %8s %9s %s\n"
  printf "$fmt" "Proyecto" "Implementacion" "Server" "RPS" "p50" "p95" "p99" "Err%" "Reqs" "Ops"
  for f in "$RESULTS_DIR"/*.json; do
    [ -f "$f" ] || continue
    case "$f" in *.cfg.json) continue ;; esac
    proj="$(jq -r .project "$f")"
    impl="$(jq -r .impl "$f")"
    server="$(jq -r .server "$f")"
    t="$(jq -c .total "$f")"
    ops="$(jq -r '.ops | keys | join(",")' "$f")"
    printf "$fmt" "$proj" "$impl" "$server" \
      "$(echo "$t" | jq -r .rps)" \
      "$(echo "$t" | jq -r '.p50_ms | tostring + "ms"')" \
      "$(echo "$t" | jq -r '.p95_ms | tostring + "ms"')" \
      "$(echo "$t" | jq -r '.p99_ms | tostring + "ms"')" \
      "$(echo "$t" | jq -r '.error_rate | tostring + "%"')" \
      "$(echo "$t" | jq -r .requests)" \
      "$ops"
  done | sort
}

cleanup() {
  for c in $(podman ps -aq --filter name="^$CT_PREFIX-" 2>/dev/null); do
    podman rm -f "$c" >/dev/null 2>&1 || true
  done
  podman network rm "$NET" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

parse_args "$@"

PROJECTS="$(expand_filter "$PROJECTS_FILTER" "$ALL_PROJECTS")"
SLUGS="$(expand_filter "$IMPLS_FILTER" "$ALL_SLUGS")"

if [ "$LIST_ONLY" = 1 ]; then
  for proj in $PROJECTS; do
    for slug in $SLUGS; do
      echo "$proj/$slug"
    done
  done
  exit 0
fi

[ -n "$PROJECTS" ] || { echo "ERROR: no valid projects selected"; exit 1; }
[ -n "$SLUGS" ] || { echo "ERROR: no valid implementations selected"; exit 1; }

if [ -n "$TAG" ]; then
  NET="bench-net-$TAG"
  CT_PREFIX="bench-$TAG"
  PG_CT="$CT_PREFIX-db"
  REDIS_CT="$CT_PREFIX-redis"
  RESULTS_DIR="$RESULTS_BASE/run-$TAG"
fi

echo ">>> Benchmark plan: projects='$PROJECTS' impls='$SLUGS' (vus=$VUS duration=$DURATION seed=$SEED)"
mkdir -p "$RESULTS_DIR"
rm -f "$RESULTS_DIR"/*.json "$RESULTS_DIR"/*.log 2>/dev/null || true
infra_up

FAILED=0
for proj in $PROJECTS; do
  echo ">>> Project: $proj"
  for slug in $SLUGS; do
    echo "=== $proj/$slug ==="
    app_info "$slug" || { echo "WARN: unknown impl '$slug'"; continue; }
    if ! build_app "$proj" "$slug"; then echo "SKIP: build failed for $proj/$slug"; continue; fi
    drop_table "$proj"
    if ! run_app "$proj" "$slug"; then echo "SKIP: app failed to boot for $proj/$slug"; FAILED=1; continue; fi
    run_k6 "$proj" "$slug" || FAILED=1
    podman rm -f "$CT_PREFIX-$proj-$slug" >/dev/null 2>&1 || true
  done
done

echo ""
echo "=== RESULTADOS (ms) ==="
report

[ "$FAILED" = 0 ] || { echo "WARN: some runs failed (see bench-results/*.k6.log)"; exit 1; }
echo "OK: benchmark complete ($RESULTS_DIR)"