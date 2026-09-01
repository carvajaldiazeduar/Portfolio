#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Ejecuta los tests de cada proyecto del Portfolio desde Podman, por tecnologia.

.DESCRIPTION
  Descubre los proyectos con tests (.NET, Java, Python) y corre cada suite
  dentro de un contenedor Podman efimero (--rm), montando el repo en /app.
  Usa CACHE_TYPE=local y base de datos SQLite cuando el proyecto la necesita,
  para no levantar la pila de BDs (pgsql/mysql/sqlserver/mongodb).

.PARAMETER Tech
  Filtro de tecnologia: 'csharp' | 'java' | 'python'. Vacio = todas.

.PARAMETER Project
  Filtro por nombre de proyecto (substring del path relativo). Vacio = todos.

.EXAMPLE
  ./scripts/run-tests.ps1                 # todos los proyectos
  ./scripts/run-tests.ps1 -Tech python    # solo Python
  ./scripts/run-tests.ps1 -Project APIGateway  # solo APIGateway
#>
[CmdletBinding()]
param(
    [ValidateSet('csharp', 'java', 'python', '')]
    [string]$Tech = '',
    [string]$Project = ''
)

$ErrorActionPreference = 'Continue'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Runs = @()

# Imagenes Podman por tecnologia
$Images = @{
    csharp = 'mcr.microsoft.com/dotnet/sdk:10.0-alpine'
    java   = 'maven:3.9-eclipse-temurin-21'
    python = 'python:3.11-slim'
}

function Invoke-PodmanRun {
    param(
        [string]$Image,
        [string]$WorkDir,   # ruta absoluta Windows que se monta como working dir
        [string]$Cmd        # comando a ejecutar dentro del contenedor (sh -c)
    )
    $rel = $WorkDir.Substring($Root.Length).TrimStart('\', '/')
    $rel = $rel.Replace('\', '/')
    $inv = @('run', '--rm')
    $inv += '-v', "$Root`:/app"
    if ($rel) {
        $inv += '--workdir', "/app/$rel"
    } else {
        $inv += '--workdir', '/app'
    }
    $inv += '-e', 'CACHE_TYPE=local'
    $inv += '-e', 'DB_DRIVER=sqlite'
    $inv += '-e', 'DB_FILE=/tmp/test.db'
    $inv += $Image
    $inv += 'sh', '-c', $Cmd
    $output = & podman @inv 2>&1
    $exit = $LASTEXITCODE
    if ($output) { $output | ForEach-Object { Write-Host $_ } }
    return $exit
}

Write-Host "== Repo raiz: $Root" -ForegroundColor Cyan
Write-Host "== Podman: $((podman --version))`n" -ForegroundColor Cyan

# ---------------- .NET / C# ----------------
if ($Tech -eq '' -or $Tech -eq 'csharp') {
    Write-Host "`n########## .NET (C#) ##########" -ForegroundColor Magenta
    $csprojs = Get-ChildItem -Path $Root -Recurse -Filter '*.Tests.csproj' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike '*node_modules*' } |
        Sort-Object FullName
    foreach ($f in $csprojs) {
        $proj = $f.FullName.Substring($Root.Length).TrimStart('\')
        if ($Project -and $proj -notlike "*$Project*") { continue }
        $testsDir = Split-Path $f.FullName          # ...\src\tests
        $srcDir   = Split-Path $testsDir            # ...\src
        $csName   = Split-Path $f -Leaf             # Xxx.Tests.csproj
        $cmd = "dotnet test tests/$csName --nologo -c Release"
        Write-Host "`n--- C# : $proj" -ForegroundColor Yellow
        $code = Invoke-PodmanRun -Image $Images.csharp -WorkDir $srcDir -Cmd $cmd
        $status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
        Write-Host "    => $status (exit $code)" -ForegroundColor $(if ($code -eq 0) { 'Green' } else { 'Red' })
        $Runs += [pscustomobject]@{ Tech = 'csharp'; Project = $proj; Status = $status; Exit = $code }
    }
}

# ---------------- Java ----------------
if ($Tech -eq '' -or $Tech -eq 'java') {
    Write-Host "`n########## Java ##########" -ForegroundColor Magenta
    $poms = Get-ChildItem -Path $Root -Recurse -Filter 'pom.xml' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike '*target*' -and $_.FullName -notlike '*node_modules*' } |
        Sort-Object FullName
    foreach ($f in $poms) {
        $proj = $f.FullName.Substring($Root.Length).TrimStart('\')
        if ($Project -and $proj -notlike "*$Project*") { continue }
        $pomDir = Split-Path $f.FullName
        $cmd = 'mvn -q test'
        Write-Host "`n--- Java: $proj" -ForegroundColor Yellow
        $code = Invoke-PodmanRun -Image $Images.java -WorkDir $pomDir -Cmd $cmd
        $status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
        Write-Host "    => $status (exit $code)" -ForegroundColor $(if ($code -eq 0) { 'Green' } else { 'Red' })
        $Runs += [pscustomobject]@{ Tech = 'java'; Project = $proj; Status = $status; Exit = $code }
    }
}

# ---------------- Python ----------------
if ($Tech -eq '' -or $Tech -eq 'python') {
    Write-Host "`n########## Python ##########" -ForegroundColor Magenta
    # working dir (relativo a raiz) -> ruta de requirements relativa al working dir
    $pyProjects = [ordered]@{
        'APIGateway/Python/FastAPI'          = 'src/requirements.txt'
        'Inboxes/Python/Flask/src'           = 'requirements.txt'
        'PasswordGenerator/Python/Flask/src' = 'requirements.txt'
        'SemanticSearch/Python/FastAPI/src'  = 'requirements.txt'
        'SemanticSearch/Python/Flask/src'    = 'requirements.txt'
        'StreamVideo/Python/Pipeline'        = 'requirements.txt'
    }
    foreach ($rel in $pyProjects.Keys) {
        if ($Project -and $rel -notlike "*$Project*") { continue }
        $req = $pyProjects[$rel]
        $cmd = "pip install -q --disable-pip-version-check -r $req pytest >/dev/null 2>&1 && python -m pytest tests/ -q"
        Write-Host "`n--- Python: $rel" -ForegroundColor Yellow
        $work = Join-Path $Root ($rel.Replace('/', '\'))
        $code = Invoke-PodmanRun -Image $Images.python -WorkDir $work -Cmd $cmd
        $status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
        Write-Host "    => $status (exit $code)" -ForegroundColor $(if ($code -eq 0) { 'Green' } else { 'Red' })
        $Runs += [pscustomobject]@{ Tech = 'python'; Project = $rel; Status = $status; Exit = $code }
    }
}

# ---------------- Resumen ----------------
Write-Host "`n`n================ RESUMEN ================" -ForegroundColor Cyan
$pass = ($Runs | Where-Object Status -eq 'PASS').Count
$fail = ($Runs | Where-Object Status -eq 'FAIL').Count
$Runs | Format-Table Tech, Status, Exit, Project -AutoSize
Write-Host "PASS: $pass  |  FAIL: $fail  |  TOTAL: $($Runs.Count)" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Red' })
if ($fail -gt 0) { Write-Host "ALGUNA PRUEBA FALLO" -ForegroundColor Red }
