param(
  [ValidateSet('run', 'build')]
  [string]$Mode = 'run'
)

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env.local"

if (-not (Test-Path $envFile)) {
  Write-Error "Arquivo local nao encontrado: $envFile"
  Write-Host "Use o .env.local.example como base para criar o seu .env.local."
  exit 1
}

if ($Mode -eq 'build') {
  flutter build web --release --dart-define-from-file=$envFile
  exit $LASTEXITCODE
}

flutter run -d chrome --dart-define-from-file=$envFile
exit $LASTEXITCODE
