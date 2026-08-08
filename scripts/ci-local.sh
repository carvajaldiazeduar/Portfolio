#!/usr/bin/env bash
set -euo pipefail

JOB="${1:-all}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NET="ci-local-net"
NODE_CT="ci-local-node"
PYTHON_CT="ci-local-python"
PHP_CT="ci-local-php"
RUBY_CT="ci-local-ruby"
DOTNET_CT="ci-local-dotnet"
POSTGRES_CT="ci-local-postgres"
MARIADB_CT="ci-local-mariadb"
MSSQL_CT="ci-local-mssql"
MONGO_CT="ci-local-mongo"

DB_CT_NAMES=("$POSTGRES_CT" "$MARIADB_CT" "$MSSQL_CT" "$MONGO_CT")
ALL_CTS=("$NODE_CT" "$PYTHON_CT" "$PHP_CT" "$RUBY_CT" "$DOTNET_CT" "${DB_CT_NAMES[@]}")

cleanup() {
  for c in "${ALL_CTS[@]}"; do
    podman rm -f "$c" >/dev/null 2>&1 || true
  done
  podman network rm "$NET" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Borra todos los contenedores detenidos de ejecuciones previas (mantiene los activos).
cleanup_stopped_containers() {
  podman container prune -f >/dev/null 2>&1 || true
}
cleanup_stopped_containers

ensure_image() { podman image exists "$1" || podman pull "$1"; }

# Mapa de nombres de base de datos por proyecto (para BDs remotas)
proj_dbname() {
  case "$1" in
    Contacts/*) echo contacts ;;
    Inboxes/*) echo inboxes ;;
    PasswordGenerator/*) echo passwords ;;
    TasksList/*) echo tasks ;;
    *) echo "" ;;
  esac
}

# start_db_infra [neededs]: boots only the DB containers a job requires.
# neededs is a space list from: postgres mariadb mssql mongo (default: all).
start_db_infra() {
  local needed="${1:-postgres mariadb mssql mongo}"
  need_postgres=0; need_mariadb=0; need_mssql=0; need_mongo=0
  for d in $needed; do
    case "$d" in
      postgres|pgsql) need_postgres=1 ;;
      mariadb|mysql)  need_mariadb=1 ;;
      sqlserver|mssql) need_mssql=1 ;;
      mongodb|mongo)  need_mongo=1 ;;
    esac
  done
  podman network create "$NET" >/dev/null 2>&1 || true

  if [ "$need_postgres" = 1 ]; then
    echo ">>> PostgreSQL 16"
    ensure_image docker.io/library/postgres:16
    podman run -d --name "$POSTGRES_CT" --network "$NET" \
      -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres \
      docker.io/library/postgres:16 >/dev/null
    ready=0
    for _ in $(seq 1 90); do
      if podman exec "$POSTGRES_CT" pg_isready -U postgres >/dev/null 2>&1; then ready=1; break; fi
      sleep 1
    done
    [ "$ready" = 1 ] || { echo "ERROR: PostgreSQL did not become ready"; exit 1; }
    for db in contacts inboxes passwords tasks; do
      podman exec "$POSTGRES_CT" psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1 \
        || podman exec "$POSTGRES_CT" psql -U postgres -c "CREATE DATABASE $db" >/dev/null
    done
  fi

  if [ "$need_mariadb" = 1 ]; then
    echo ">>> MariaDB 11 (driver: mysql)"
    ensure_image docker.io/library/mariadb:11
    podman run -d --name "$MARIADB_CT" --network "$NET" \
      -e MARIADB_ROOT_PASSWORD=secret -e MARIADB_DATABASE=contacts \
      docker.io/library/mariadb:11 >/dev/null
    ready=0
    for _ in $(seq 1 90); do
      if podman exec "$MARIADB_CT" sh -c "command -v mariadb-admin >/dev/null 2>&1 && mariadb-admin ping -uroot -psecret --silent 2>/dev/null || mysqladmin ping -uroot -psecret --silent 2>/dev/null"; then ready=1; break; fi
      sleep 1
    done
    [ "$ready" = 1 ] || { echo "ERROR: MariaDB did not become ready"; exit 1; }
    for db in contacts inboxes passwords tasks; do
      podman exec "$MARIADB_CT" mysql -uroot -psecret -e "CREATE DATABASE IF NOT EXISTS $db" >/dev/null 2>&1 || true
    done
  fi

  if [ "$need_mssql" = 1 ]; then
    echo ">>> SQL Server 2022 (driver: sqlserver)"
    ensure_image mcr.microsoft.com/mssql/server:2022-latest
    podman run -d --name "$MSSQL_CT" --network "$NET" \
      -e ACCEPT_EULA=Y -e SA_PASSWORD='YourStrong!Pass1' -e MSSQL_PID=Developer \
      mcr.microsoft.com/mssql/server:2022-latest >/dev/null
    ready=0
    for _ in $(seq 1 150); do
      # El servidor 2022 no incluye sqlcmd; el probe TCP se hace desde dentro del contenedor al localhost:1433.
      if podman exec "$MSSQL_CT" bash -c 'timeout 2 bash -c "</dev/tcp/127.0.0.1/1433"' >/dev/null 2>&1; then ready=1; break; fi
      sleep 1
    done
    [ "$ready" = 1 ] || { echo "ERROR: SQL Server did not become ready"; exit 1; }
    # Crear bases (sqlcmd no viene en la imagen 2022; se instala bajo demanda si falta).
    if podman exec "$MSSQL_CT" command -v /opt/mssql-tools/bin/sqlcmd >/dev/null 2>&1 || podman exec "$MSSQL_CT" command -v sqlcmd >/dev/null 2>&1; then
      for db in contacts inboxes passwords tasks; do
        podman exec "$MSSQL_CT" sqlcmd -S localhost -U sa -P 'YourStrong!Pass1' -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name='$db') CREATE DATABASE $db" >/dev/null 2>&1 || true
      done
    fi
  fi

  if [ "$need_mongo" = 1 ]; then
    echo ">>> MongoDB 7 (driver: mongodb)"
    ensure_image docker.io/library/mongo:7
    podman run -d --name "$MONGO_CT" --network "$NET" docker.io/library/mongo:7 >/dev/null
    ready=0
    for _ in $(seq 1 90); do
      if podman exec "$MONGO_CT" mongosh --quiet --eval "1" >/dev/null 2>&1; then ready=1; break; fi
      sleep 1
    done
    [ "$ready" = 1 ] || { echo "ERROR: MongoDB did not become ready"; exit 1; }
    for db in contacts inboxes passwords tasks; do
      podman exec "$MONGO_CT" mongosh --quiet --eval "db.getSiblingDB('$db').getCollectionNames()" >/dev/null 2>&1 || true
    done
  fi
}

# db_env <driver> <proj-rel>: prints env "KEY=VALUE" pairs (sqlite uses DB_FILE)
db_env() {
  local driver="$1" rel="$2"
  local proj db
  proj="${rel%%/*}"
  db="$(proj_dbname "$rel")"
  local name="${db:-${proj}}"
  case "$driver" in
    sqlite)    echo "DB_DRIVER=sqlite DB_FILE=/tmp/${name}.db CACHE_TYPE=local" ;;
    pgsql)     echo "DB_DRIVER=pgsql DB_HOST=$POSTGRES_CT DB_PORT=5432 DB_NAME=$name DB_USER=postgres DB_PASSWORD=postgres CACHE_TYPE=local" ;;
    mysql)     echo "DB_DRIVER=mysql DB_HOST=$MARIADB_CT DB_PORT=3306 DB_NAME=$name DB_USER=root DB_PASSWORD=secret CACHE_TYPE=local" ;;
    sqlserver) echo "DB_DRIVER=sqlserver DB_HOST=$MSSQL_CT DB_PORT=1433 DB_NAME=$name DB_USER=sa DB_PASSWORD=YourStrong!Pass1 CACHE_TYPE=local" ;;
    mongodb)   echo "DB_DRIVER=mongodb DB_HOST=$MONGO_CT DB_PORT=27017 DB_NAME=$name CACHE_TYPE=local" ;;
  esac
}

# exec_in <ct> <envs-string> <command...>: runs command in container with env pairs as -e
exec_in() {
  local ct="$1" envs="$2"; shift 2
  local args=()
  for kv in $envs; do args+=( -e "$kv" ); done
  podman exec "${args[@]}" "$ct" "$@"
}

start_runner() {
  local name="$1" image="$2"
  ensure_image "$image"
  podman run -d --name "$name" --network "$NET" -v "$ROOT:/app" -w /app "$image" sleep infinity >/dev/null
}

# PHP driver matrix (pdo_sqlsrv needs PHP >= 8.3 -> not available on php:8.2-cli)
PHP_DRIVERS=(sqlite pgsql mysql mongodb)
# Full matrix for languages with native drivers
FULL_DRIVERS=(sqlite pgsql mysql sqlserver mongodb)

drivers_for() {
  case "$1" in
    php) echo "${PHP_DRIVERS[*]}" ;;
    *)   echo "${FULL_DRIVERS[*]}" ;;
  esac
}

# dbs_for <lang>: which DB containers the job needs (kept minimal -> faster boots).
dbs_for() {
  case "$1" in
    php)   echo "postgres mariadb mongo" ;;
    node)  echo "postgres mariadb mssql mongo" ;;
    python) echo "postgres mariadb mssql mongo" ;;
    ruby)  echo "postgres mariadb" ;;
    csharp) echo "postgres mariadb mssql mongo" ;;
    *)     echo "postgres mariadb mssql mongo" ;;
  esac
}

podman network exists "$NET" || podman network create "$NET" >/dev/null

########################################################################
# Per-language, per-driver test runners
########################################################################

# --- PHP ---
run_php_cli_tests() {
  echo ">>> PHP (CLI tests)"
  local failed=0
  while IFS= read -r t; do
    rel="${t#"$ROOT"/}"
    echo "=== $rel ==="
    podman exec "$PHP_CT" php -d zend.assertions=1 -d assert.exception=1 "/app/$rel" || failed=1
  done < <(find "$ROOT" -name '*Test.php' -path '*/PHP/Cli/tests/*' | sort)
  [ "$failed" = 0 ] || { echo "ERROR: PHP CLI tests failed"; exit 1; }
}

run_php_web_plain() {
  local envs="$1"
  local failed=0
  for tdir in $(find "$ROOT" -type d -path '*/PHP/Web/Plain/src/tests' | sort); do
    src="$(dirname "$tdir")"
    rel="${src#"$ROOT"/}"
    echo "=== $rel ==="
    tests=""
    for t in "$tdir"/*Test.php; do
      [ -f "$t" ] || continue
      tests="$tests /app/${t#"$ROOT"/}"
    done
    [ -z "$tests" ] && continue
    exec_in "$PHP_CT" "$envs" bash -c "cd '/app/$rel'; php -S 127.0.0.1:8000 index.php >/tmp/php-web-server.log 2>&1 &
      SRVPID=\$!
      ready=0
      for _ in \$(seq 1 60); do
        php -r '\$h=@file_get_contents(\"http://127.0.0.1:8000/\"); exit(\$h!==false?0:1);' 2>/dev/null && { ready=1; break; }
        sleep 1
      done
      rc=0
      if [ \$ready != 1 ]; then echo 'ERROR: server not ready'; cat /tmp/php-web-server.log; rc=1
      else
        for t in$tests; do echo \"--- \$(basename \"\$t\") ---\"; php -d zend.assertions=1 -d assert.exception=1 \"\$t\" || rc=1; done
      fi
      kill \$SRVPID 2>/dev/null || true
      wait \$SRVPID 2>/dev/null || true
      exit \$rc" || failed=1
  done
  [ "$failed" = 0 ] || { echo "ERROR: PHP Web Plain tests failed ($envs)"; exit 1; }
}

# --- Python ---
run_python_tests() {
  local envs="$1"
  local failed=0
  while IFS= read -r t; do
    d="$(dirname "$t")"
    rel="${d#"$ROOT"/}"
    echo "=== $rel ==="
    exec_in "$PYTHON_CT" "$envs" sh -c "cd '/app/$rel' && python -m pytest -q" || failed=1
  done < <(find "$ROOT" -type d -name tests -path '*/Python/*' -not -path '*/node_modules/*' | sort)
  [ "$failed" = 0 ] || { echo "ERROR: Python tests failed ($envs)"; exit 1; }
}

# --- Node.js ---
# A project's factory (DatabaseFactory.js) / Prisma datasource only supports a subset
# of drivers. When a project rejects a driver with an explicit "Unsupported...driver/protocol"
# error, we skip it for that driver instead of failing the whole run.
is_unsupported() {
  grep -qiE "Unsupported database driver|must start with the protocol|Unsupported DB driver|Invalid datasource|provider .* does not support|datasource|engine type" "$1" 2>/dev/null
}
run_node_tests() {
  local envs="$1"
  local failed=0
  while IFS= read -r pkg; do
    d="$(dirname "$pkg")"
    rel="${d#"$ROOT"/}"
    [ -d "$d/tests" ] || continue
    # Prisma projects: solo el driver cuyo provider coincide.
    if [ -d "$d/prisma" ] && [ -f "$d/prisma/schema.prisma" ]; then
      prov="$(awk '/^datasource[[:space:]]/{f=1} f&&/provider[[:space:]]*=/{sub(/.*= */,""); gsub(/"/,""); print; exit}' "$d/prisma/schema.prisma")"
      cur="$(printf '%s' "$envs" | sed -n 's/.*DB_DRIVER=\([^ ]*\).*/\1/p')"
      case "$prov" in
        postgresql|postgres) want=pgsql ;;
        mysql) want=mysql ;;
        sqlite|sqlite3) want=sqlite ;;
        sqlserver|mssql) want=sqlserver ;;
        mongodb) want=mongodb ;;
        *) want="" ;;
      esac
      if [ -n "$want" ] && [ "$cur" != "$want" ]; then
        echo "=== $rel (skipped: prisma provider=$prov, driver=$cur)"
        continue
      fi
    fi
    echo "=== $rel ==="
    exec_in "$NODE_CT" "$envs" sh -c "cd '/app/$rel' && npm install --no-fund --no-audit >/dev/null 2>&1" || failed=1
    out_file="$(mktemp)"
    rc=0
    if [ -d "$d/prisma" ]; then
      db="$(sed -n "s/.*DB_NAME.*|| '\([^']*\)'.*/\1/p" "$d/server.js")"
      url="postgresql://postgres:postgres@$POSTGRES_CT:5432/$db"
      case " $envs " in
        *"DB_DRIVER=sqlite"*) url="file:/tmp/${db}.db?connection_limit=1&_pragma=journal_mode=WAL" ;;
        *"DB_DRIVER=mysql"*)   url="mysql://root:secret@$MARIADB_CT:3306/$db" ;;
        *"DB_DRIVER=sqlserver"*|*"DB_DRIVER=mssql"*) url="sqlserver://sa:YourStrong!Pass1@$MSSQL_CT:1433/$db" ;;
        *"DB_DRIVER=mongodb"*) url="mongodb://$MONGO_CT:27017/$db" ;;
      esac
      push_file="$(mktemp)"
      exec_in "$NODE_CT" "$envs -e DATABASE_URL=$url" sh -c "cd '/app/$rel' && npx prisma generate >/dev/null 2>&1 && npx prisma db push --accept-data-loss --skip-generate >'$push_file' 2>&1; npx jest --ci --runInBand --forceExit" >"$out_file" 2>&1 || rc=$?
      if [ $rc -ne 0 ] && { is_unsupported "$out_file" || is_unsupported "$push_file"; }; then
        echo "=== $rel (skipped: driver unsupported by project)"
      else
        cat "$out_file"
        [ $rc -ne 0 ] && failed=1
      fi
      rm -f "$push_file"
    else
      exec_in "$NODE_CT" "$envs" sh -c "cd '/app/$rel' && npx jest --ci --runInBand --forceExit" >"$out_file" 2>&1 || rc=$?
      if [ $rc -ne 0 ] && is_unsupported "$out_file"; then
        echo "=== $rel (skipped: driver unsupported by project)"
      else
        cat "$out_file"
        [ $rc -ne 0 ] && failed=1
      fi
    fi
    rm -f "$out_file"
  done < <(find "$ROOT" -name package.json -path '*/Node.js/*' -not -path '*/node_modules/*' | sort)
  [ "$failed" = 0 ] || { echo "ERROR: Node.js tests failed ($envs)"; exit 1; }
}

# --- C# ---
run_csharp_tests() {
  local envs="$1"
  local failed=0
  while IFS= read -r csproj; do
    rel="${csproj#"$ROOT"/}"
    echo "=== $rel ==="
    exec_in "$DOTNET_CT" "$envs" sh -c "cd /app && dotnet test '$rel' --nologo" || failed=1
  done < <(find "$ROOT" -name '*.Tests.csproj' -not -path '*/node_modules/*' | sort)
  [ "$failed" = 0 ] || { echo "ERROR: C# tests failed ($envs)"; exit 1; }
}

# --- Ruby ---

case "$JOB" in
  all)   JOBS="node python php ruby csharp" ;;
  node)  JOBS="node" ;;
  python) JOBS="python" ;;
  php)   JOBS="php" ;;
  ruby)  JOBS="ruby" ;;
  csharp) JOBS="csharp" ;;
  *) echo "Usage: $0 [all|node|python|php|ruby|csharp]"; exit 1 ;;
esac

for job in $JOBS; do
  # Reset infra from any previous job so container names don't collide.
  cleanup
  case "$job" in
      node)
      start_db_infra "$(dbs_for node)"
      start_runner "$NODE_CT" docker.io/library/node:20
      echo ">>> Node.js (Jest)"
      for driver in $(drivers_for node); do
        echo ">>> Node.js drivers ($driver)"
        run_node_tests "$(db_env "$driver" "Contacts/Node.js/Web/Plain/src")"
      done
      ;;

     python)
      start_db_infra "$(dbs_for python)"
      start_runner "$PYTHON_CT" docker.io/library/python:3.11-slim
      echo ">>> Python (pytest) — installing deps"
      exec_in "$PYTHON_CT" "" sh -c "pip install --quiet --upgrade pip && pip install --quiet pytest flask flask-sqlalchemy redis psycopg2-binary pymysql pymongo pymssql chromadb pinecone-client duckdb fastapi uvicorn httpx python-multipart"
      for driver in $(drivers_for python); do
        echo ">>> Python drivers ($driver)"
        run_python_tests "$(db_env "$driver" "Contacts/Python/Web/Plain/src")"
      done
      ;;

     php)
      start_db_infra "$(dbs_for php)"
      start_runner "$PHP_CT" docker.io/library/php:8.2-cli
      echo ">>> PHP (lint + assert)"
      podman exec "$PHP_CT" sh -c "set -e; for f in \$(find /app -name '*.php' -not -path '*/vendor/*' | sort); do php -l \"\$f\" >/dev/null; done"
      podman exec "$PHP_CT" sh -c "cd /app/ChatAI/PHP/Web/Plain/src && php -d zend.assertions=1 -d assert.exception=1 tests/test_app.php"
      # instalar extensiones de BD (pdo_pgsql, pdo_mysql, pdo_sqlite, mongodb).
      # pdo_sqlite a veces devuelve rc!=0 aun instalándose; por eso cada paso es independiente.
      podman exec "$PHP_CT" sh -c "apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq libpq-dev default-libmysqlclient-dev libssl-dev build-essential autoconf >/dev/null 2>&1 && docker-php-ext-install pdo_pgsql pdo_mysql pdo_sqlite >/dev/null 2>&1 || true; yes '' | pecl install mongodb >/dev/null 2>&1 || echo 'WARN: pecl mongodb install failed'; docker-php-ext-enable mongodb >/dev/null 2>&1 || true"
      if ! podman exec "$PHP_CT" php -m | grep -qi mongodb; then echo "WARN: mongodb extension not loaded"; fi
      run_php_cli_tests
      for driver in $(drivers_for php); do
        echo ">>> PHP Web Plain ($driver)"
        run_php_web_plain "$(db_env "$driver" "Contacts/PHP/Web/Plain/src")"
      done
      ;;

      ruby)
      start_db_infra "$(dbs_for ruby)"
      start_runner "$RUBY_CT" docker.io/library/ruby:3.2
      echo ">>> Ruby (minitest)"
      exec_in "$RUBY_CT" "" sh -c "cd /app/ChatAI/Ruby/Web/Plain/src && bundle install --quiet"
      while IFS= read -r t; do
        rel="${t#"$ROOT"/}"
        echo "=== $rel ==="
        exec_in "$RUBY_CT" "$(db_env sqlite "ChatAI/Ruby/Web/Plain/src")" sh -c "ruby '/app/$rel'"
      done < <(find "$ROOT" -name '*_test.rb' -not -path '*/node_modules/*' -not -path '*/ChatAI/*' -not -path '*/RubyOnRails/src/test/*' | sort)
      exec_in "$RUBY_CT" "" sh -c "cd /app/ChatAI/Ruby/Web/Plain/src && bundle exec ruby -I. tests/test_server.rb"
      echo ">>> Ruby (Rails)"
      while IFS= read -r tdir; do
        if [ -z "$(find "$tdir" -name '*_test.rb' | head -1)" ]; then
          echo "=== ${tdir#"$ROOT"/} (no tests, skipped) ==="
          continue
        fi
        src="$(dirname "$tdir")"
        rel="${src#"$ROOT"/}"
        dbn="$(proj_dbname "$rel")"
        echo "=== $rel ==="
        exec_in "$RUBY_CT" "$(db_env sqlite "$rel")" sh -c "cd '/app/$rel' && bundle install --quiet && RAILS_ENV=test DB_DRIVER=sqlite DB_FILE=/tmp/${dbn:-contacts}_test.db bundle exec ruby -Itest -I. -e 'require \"config/environment\"; ActiveRecord::Base.connection.migration_context.migrate; Dir[\"test/**/*_test.rb\"].sort.each { |f| require File.expand_path(f) }'"
      done < <(find "$ROOT" -type d -path '*/RubyOnRails/src/test' | sort)
      ;;

     csharp)
      start_db_infra "$(dbs_for csharp)"
      start_runner "$DOTNET_CT" mcr.microsoft.com/dotnet/sdk:9.0
      echo ">>> C# (.NET 9)"
      for driver in $(drivers_for csharp); do
        echo ">>> C# drivers ($driver)"
        run_csharp_tests "$(db_env "$driver" "Contacts/CSharp/Web/AspNetMinimalApi/src")"
      done
      ;;
  esac
done

echo "OK: CI jobs passed locally ($JOB)."