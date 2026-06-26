param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$Foreground
)

$ErrorActionPreference = "Stop"

function Read-JsonFile {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "No existe: $Path"
  }
  return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-SystemPython {
  param([string]$CommandName)
  if ([string]::IsNullOrWhiteSpace($CommandName)) {
    $CommandName = "python"
  }

  $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
  if (-not $cmd) {
    return @()
  }

  try {
    & $cmd.Source --version *> $null
    if ($LASTEXITCODE -eq 0) {
      return @([string]$cmd.Source)
    }
  } catch {
    return @()
  }

  return @()
}

function Ensure-PortablePython {
  param([string]$RootPath)
  $portable = Join-Path $RootPath "tools\python-embed\python.exe"
  if (Test-Path -LiteralPath $portable) {
    return @($portable)
  }
  throw "No hay Python disponible. Incluye tools\python-embed\python.exe en el paquete o prepara Python portable desde la app."
}

function Get-PortablePython {
  param([string]$RootPath)
  $portable = Join-Path $RootPath "tools\python-embed\python.exe"
  if (Test-Path -LiteralPath $portable) {
    return @($portable)
  }
  return @()
}

function Quote-ProcessArgument {
  param([string]$Value)
  if ($null -eq $Value) {
    return '""'
  }
  return '"' + $Value.Replace('"', '\"') + '"'
}

function Stop-PortListener {
  param([int]$Port)
  $listeners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
  foreach ($listener in $listeners) {
    if ($listener.OwningProcess) {
      Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue
    }
  }
}

function Wait-Manifest {
  param([string]$Url)
  for ($i = 0; $i -lt 30; $i++) {
    try {
      Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 1 | Out-Null
      return $true
    } catch {
      Start-Sleep -Milliseconds 400
    }
  }
  return $false
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$config = Read-JsonFile (Join-Path $rootPath "game.config.json")
$manifest = Read-JsonFile (Join-Path $rootPath "game-manifest.json")
$eventBus = $manifest.eventBus
if (-not $eventBus) {
  throw "game-manifest.json no tiene eventBus."
}

$hostName = if ($eventBus.host) { [string]$eventBus.host } else { "127.0.0.1" }
$port = [int]$eventBus.port
$runtimeRel = if ($config.runtimeScript) { [string]$config.runtimeScript } else { "runtime/event_bus.py" }
$runtimePath = Join-Path $rootPath $runtimeRel
if (-not (Test-Path -LiteralPath $runtimePath)) {
  throw "No existe runtimeScript: $runtimePath"
}

$python = @(Get-PortablePython $rootPath)
if (-not $python -or -not $python[0]) {
  $python = @(Get-SystemPython ([string]$config.pythonCommand))
}
if (-not $python -or -not $python[0]) {
  $python = @(Ensure-PortablePython $rootPath)
}

$pythonExe = [string]$python[0]
if ([string]::IsNullOrWhiteSpace($pythonExe)) {
  throw "No se pudo resolver Python para iniciar el EventBus."
}

$pythonArgs = @()
if ($python.Count -gt 1) {
  $pythonArgs = @($python | Select-Object -Skip 1)
}

$logsDir = Join-Path $rootPath "logs\launcher"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$stdoutLog = Join-Path $logsDir "event-bus.log"
$stderrLog = Join-Path $logsDir "event-bus.err.log"

Stop-PortListener $port

if ($Foreground) {
  & $pythonExe @pythonArgs $runtimePath
  exit $LASTEXITCODE
}

$argumentList = @()
$argumentList += $pythonArgs
$argumentList += $runtimePath
$quotedArguments = ($argumentList | ForEach-Object { Quote-ProcessArgument ([string]$_) }) -join " "
Start-Process -FilePath $pythonExe -ArgumentList $quotedArguments -WorkingDirectory $rootPath -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog | Out-Null

$manifestUrl = "http://$hostName`:$port/manifest"
if (-not (Wait-Manifest $manifestUrl)) {
  throw "EventBus no respondio en $manifestUrl. Revisa $stdoutLog y $stderrLog"
}

Write-Host "EventBus listo: $manifestUrl"
