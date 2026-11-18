\xef\xbb\xbf# Uso: .\install.ps1 [-Team ollama]
param([string]$Team = "ollama")

$Src  = $PSScriptRoot
$Dest = Join-Path $env:USERPROFILE ".openclaude"
$Ts   = [DateTimeOffset]::Now.ToUnixTimeSeconds()

# settings.local.json (ignorado pelo git, pode ter chaves) tem prioridade
$Cfg = Join-Path $Src "teams\$Team\settings.local.json"
if (-not (Test-Path $Cfg)) { $Cfg = Join-Path $Src "teams\$Team\settings.json" }
if (-not (Test-Path $Cfg)) { Write-Error "Time '$Team' não encontrado"; exit 1 }

# Nome de modelo com espaço (ex.: "ollama run x") é erro de digitação
if (Select-String -Path $Cfg -Pattern '"model"\s*:\s*"[^"]* [^"]*"' -Quiet) {
  Write-Error "Há um modelo com espaço em $Cfg. Use só o nome (ex.: deepseek-v4.1-flash:cloud)."
  exit 1
}

$AgentsDest = Join-Path $Dest "agents"
$CmdDest    = Join-Path $Dest "commands"
New-Item -ItemType Directory -Force -Path $AgentsDest | Out-Null
New-Item -ItemType Directory -Force -Path $CmdDest | Out-Null

$Settings = Join-Path $Dest "settings.json"
if (Test-Path $Settings) {
  Copy-Item $Settings "$Settings.bak.$Ts"
}
Copy-Item $Cfg $Settings -Force

# No Windows, symlink exige admin; copiamos (rode de novo após editar)
function Install-Folder($from, $to) {
  if (-not (Test-Path $from)) { return }
  foreach ($f in Get-ChildItem $from -Filter *.md) {
    $target = Join-Path $to $f.Name
    if (Test-Path $target) { Copy-Item $target "$target.bak.$Ts" }
    Copy-Item $f.FullName $target -Force
  }
}
Install-Folder (Join-Path $Src "agents")   $AgentsDest
Install-Folder (Join-Path $Src "commands") $CmdDest

Write-Host "Time '$Team' instalado em $Dest (backup do settings anterior salvo)."

# Verificações que já causaram problema
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
  Write-Warning "'ollama' não encontrado no PATH."
}
$Profiles = @(
  (Join-Path $env:USERPROFILE ".openclaude.json"),
  (Join-Path $Dest ".openclaude-profile.json")
)
foreach ($p in $Profiles) {
  if ((Test-Path $p) -and (Select-String -Path $p -Pattern 'ollama run' -Quiet)) {
    Write-Warning "$p tem 'ollama run' no nome do modelo. Deixe só o nome (ex.: deepseek-v4.1-flash:cloud), com o OpenClaude fechado."
  }
}
Write-Host "Obs.: o sandbox em Docker (bin/ia-sandbox) é para Linux/macOS."
