Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$composeRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Split-Path -Parent $composeRoot
$webUiPath = Join-Path $projectRoot "web-ui"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "npm을 찾을 수 없습니다. Node.js LTS를 설치한 뒤 다시 실행하십시오."
}

if (-not (Test-Path (Join-Path $webUiPath "package.json"))) {
    Push-Location $projectRoot
    try {
        $env:npm_config_yes = "true"
        npm create vite@latest web-ui -- --template react-ts --eslint --no-interactive
    }
    finally {
        Pop-Location
    }
}

Push-Location $webUiPath
try {
    npm install
}
finally {
    Pop-Location
}

Write-Host "web-ui 초기화가 완료되었습니다: $webUiPath"
