#!/usr/bin/env bash
# run-tests.sh — Ejecuta todos los tests del Portfolio en contenedores Podman.
#
# Uso:
#   ./scripts/run-tests.sh                 # todos los proyectos
#   ./scripts/run-tests.sh -t python       # solo Python
#   ./scripts/run-tests.sh -p APIGateway   # solo APIGateway
#
# Requisitos: Podman instalado (sin necesidad de lenguajes en el host).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASSED=0
FAILED=0
RUNS=()
TECH=""
PROJECT=""

usage() {
    echo "Uso: $0 [-t tech] [-p project]"
    echo "  -t  Filtrar por tecnologia: csharp | java | python"
    echo "  -p  Filtrar por nombre de proyecto (substring del path)"
    exit 0
}

while getopts "t:p:h" opt; do
    case $opt in
        t) TECH="$OPTARG" ;;
        p) PROJECT="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

podman_run() {
    local image="$1" workdir="$2" cmd="$3"
    local rel="${workdir#"$ROOT"}"
    rel="${rel#/}"
    local args=(run --rm -v "$ROOT:/app")
    if [ -n "$rel" ]; then
        args+=(--workdir "/app/$rel")
    else
        args+=(--workdir /app)
    fi
    args+=(-e CACHE_TYPE=local -e DB_DRIVER=sqlite -e DB_FILE=/tmp/test.db)
    args+=("$image" sh -c "$cmd")
    local output
    output=$(podman "${args[@]}" 2>&1) || true
    local exitcode=$?
    if [ -n "$output" ]; then
        echo "$output"
    fi
    return $exitcode
}

record() {
    local tech="$1" project="$2" status="$3" exitcode="$4"
    RUNS+=("$tech|$status|$exitcode|$project")
    if [ "$status" = "PASS" ]; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
}

echo -e "${CYAN}== Repo raiz: $ROOT${NC}"
echo -e "${CYAN}== Podman: $(podman --version)${NC}"
echo ""

# ---------------- .NET / C# ----------------
if [ "$TECH" = "" ] || [ "$TECH" = "csharp" ]; then
    echo -e "\n${MAGENTA}########## .NET (C#) ##########${NC}"
    while IFS= read -r f; do
        proj="${f#"$ROOT/"}"
        if [ -n "$PROJECT" ] && [[ "$proj" != *"$PROJECT"* ]]; then continue; fi
        testsDir="$(dirname "$f")"
        srcDir="$(dirname "$testsDir")"
        csName="$(basename "$f")"
        cmd="dotnet test tests/$csName --nologo -c Release"
        echo -e "\n${YELLOW}--- C# : $proj${NC}"
        if podman_run "mcr.microsoft.com/dotnet/sdk:10.0-alpine" "$srcDir" "$cmd"; then
            echo -e "    => ${GREEN}PASS${NC}"
            record "csharp" "$proj" "PASS" 0
        else
            echo -e "    => ${RED}FAIL${NC}"
            record "csharp" "$proj" "FAIL" 1
        fi
    done < <(find "$ROOT" -name '*.Tests.csproj' -not -path '*/node_modules/*' | sort)
fi

# ---------------- Java ----------------
if [ "$TECH" = "" ] || [ "$TECH" = "java" ]; then
    echo -e "\n${MAGENTA}########## Java ##########${NC}"
    while IFS= read -r f; do
        proj="${f#"$ROOT/"}"
        if [ -n "$PROJECT" ] && [[ "$proj" != *"$PROJECT"* ]]; then continue; fi
        pomDir="$(dirname "$f")"
        cmd="mvn -q test"
        echo -e "\n${YELLOW}--- Java: $proj${NC}"
        if podman_run "maven:3.9-eclipse-temurin-21" "$pomDir" "$cmd"; then
            echo -e "    => ${GREEN}PASS${NC}"
            record "java" "$proj" "PASS" 0
        else
            echo -e "    => ${RED}FAIL${NC}"
            record "java" "$proj" "FAIL" 1
        fi
    done < <(find "$ROOT" -name 'pom.xml' -not -path '*/target/*' -not -path '*/node_modules/*' | sort)
fi

# ---------------- Python ----------------
if [ "$TECH" = "" ] || [ "$TECH" = "python" ]; then
    echo -e "\n${MAGENTA}########## Python ##########${NC}"
    declare -A PY_PROJECTS=(
        ["APIGateway/Python/FastAPI"]="src/requirements.txt"
        ["Inboxes/Python/Flask/src"]="requirements.txt"
        ["PasswordGenerator/Python/Flask/src"]="requirements.txt"
        ["SemanticSearch/Python/FastAPI/src"]="requirements.txt"
        ["SemanticSearch/Python/Flask/src"]="requirements.txt"
        ["StreamVideo/Python/Pipeline"]="requirements.txt"
    )
    for rel in "${!PY_PROJECTS[@]}"; do
        if [ -n "$PROJECT" ] && [[ "$rel" != *"$PROJECT"* ]]; then continue; fi
        req="${PY_PROJECTS[$rel]}"
        cmd="pip install -q --disable-pip-version-check -r $req pytest >/dev/null 2>&1 && python -m pytest tests/ -q"
        work="$ROOT/$rel"
        echo -e "\n${YELLOW}--- Python: $rel${NC}"
        if podman_run "python:3.11-slim" "$work" "$cmd"; then
            echo -e "    => ${GREEN}PASS${NC}"
            record "python" "$rel" "PASS" 0
        else
            echo -e "    => ${RED}FAIL${NC}"
            record "python" "$rel" "FAIL" 1
        fi
    done
fi

# ---------------- Resumen ----------------
echo -e "\n\n${CYAN}================ RESUMEN ================${NC}"
printf "%-10s %-6s %-6s %s\n" "TECH" "EXIT" "STATUS" "PROJECT"
printf "%-10s %-6s %-6s %s\n" "----" "----" "------" "-------"
for run in "${RUNS[@]}"; do
    IFS='|' read -r tech status exitcode project <<< "$run"
    color="$GREEN"
    [ "$status" = "FAIL" ] && color="$RED"
    printf "%-10s %-6s ${color}%-6s${NC} %s\n" "$tech" "$exitcode" "$status" "$project"
done
TOTAL=$((PASSED + FAILED))
if [ "$FAILED" -eq 0 ]; then
    echo -e "\n${GREEN}PASS: $PASSED  |  FAIL: $FAILED  |  TOTAL: $TOTAL${NC}"
else
    echo -e "\n${RED}PASS: $PASSED  |  FAIL: $FAILED  |  TOTAL: $TOTAL${NC}"
    echo -e "${RED}ALGUNA PRUEBA FALLO${NC}"
fi
