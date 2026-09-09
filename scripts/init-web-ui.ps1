Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$composeRoot = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $composeRoot "docker-compose.staticweb.dev.yml"
$envFile = Join-Path $composeRoot ".env"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI was not found. Install and start Docker Desktop."
}

# Initialization runs inside the normal Vite container at startup.
& docker compose --project-directory $composeRoot --env-file $envFile -f $composeFile up --build -d vite-devserver
if ($LASTEXITCODE -ne 0) {
    throw "The Vite container could not be started. Check Docker Desktop and Compose logs."
}

Write-Host "Vite is starting. Initialization and npm installation run inside the container."
Write-Host "Follow progress with: docker compose -f docker-compose.staticweb.dev.yml logs -f vite-devserver"
