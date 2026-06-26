param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Read-JsonFile {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "No existe: $Path"
  }
  return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Resolve-GamePath {
  param(
    [string]$RootPath,
    [string]$Value
  )
  $expanded = [Environment]::ExpandEnvironmentVariables($Value).Replace("/", "\")
  if ([System.IO.Path]::IsPathRooted($expanded)) {
    return [System.IO.Path]::GetFullPath($expanded)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RootPath $expanded))
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

$rootPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
$gameConfig = Read-JsonFile (Join-Path $rootPath "game.config.json")
$mc = $gameConfig.minecraft
$serverConfigRel = if ($mc.serverConfig) { [string]$mc.serverConfig } else { "config/minecraft_server.json" }
$serverConfig = Read-JsonFile (Resolve-GamePath $rootPath $serverConfigRel)
if ($serverConfig.server.enabled -eq $false) {
  Write-Host "Servidor local desactivado."
  exit 0
}

$serverRoot = Resolve-GamePath $rootPath ([string]$serverConfig.server.serverRoot)
$mcVersion = [string]$serverConfig.server.minecraftVersion
$forgeVersion = [string]$serverConfig.server.forgeVersion
$javaArgs = [string]$serverConfig.server.javaArgs
$serverPort = if ($serverConfig.server.port) { [int]$serverConfig.server.port } else { [int]$mc.serverPort }
$javaExe = Join-Path $rootPath "tools\java\bin\java.exe"
$forgeArgs = Join-Path $serverRoot "libraries\net\minecraftforge\forge\$mcVersion-$forgeVersion\win_args.txt"

if (-not (Test-Path -LiteralPath $javaExe)) {
  throw "Falta Java portable: $javaExe"
}
if (-not (Test-Path -LiteralPath $forgeArgs)) {
  throw "Falta Forge instalado en servidor. Ejecuta preparar_servidor.ps1 primero."
}

$jvmArgsPath = Join-Path $serverRoot "user_jvm_args.txt"
if (-not (Test-Path -LiteralPath $jvmArgsPath)) {
  Set-Content -LiteralPath $jvmArgsPath -Encoding UTF8 -Value $javaArgs
}

Stop-PortListener $serverPort

$logsDir = Join-Path $rootPath "logs\launcher"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$stdoutLog = Join-Path $logsDir "minecraft-server.log"
$stderrLog = Join-Path $logsDir "minecraft-server.err.log"
$args = @("@user_jvm_args.txt", "@libraries/net/minecraftforge/forge/$mcVersion-$forgeVersion/win_args.txt", "nogui")

Start-Process -FilePath $javaExe -ArgumentList $args -WorkingDirectory $serverRoot -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog | Out-Null
Write-Host "Servidor Minecraft iniciado en 127.0.0.1:$serverPort"
