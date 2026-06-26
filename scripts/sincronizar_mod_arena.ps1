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

function Copy-Jars {
  param(
    [string]$Source,
    [string]$Destination
  )
  if (-not (Test-Path -LiteralPath $Source)) {
    return 0
  }
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  $count = 0
  Get-ChildItem -LiteralPath $Source -Filter *.jar -File -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $Destination $_.Name) -Force
    $count += 1
  }
  return $count
}

$rootPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
$config = Read-JsonFile (Join-Path $rootPath "game.config.json")
$mc = $config.minecraft
if (-not $mc) {
  throw "game.config.json no tiene bloque minecraft."
}

$downloader = Join-Path $PSScriptRoot "descargar_mods_curseforge.ps1"
if (Test-Path -LiteralPath $downloader) {
  & $downloader -Root $rootPath
}

$modsRoot = Resolve-GamePath $rootPath ([string]$mc.modsRoot)
$gameDir = Resolve-GamePath $rootPath ([string]$mc.gameDir)
$serverConfigRel = if ($mc.serverConfig) { [string]$mc.serverConfig } else { "config/minecraft_server.json" }
$serverConfig = Read-JsonFile (Resolve-GamePath $rootPath $serverConfigRel)
$serverRoot = Resolve-GamePath $rootPath ([string]$serverConfig.server.serverRoot)

$clientCount = Copy-Jars $modsRoot (Join-Path $gameDir "mods")
$serverCount = Copy-Jars $modsRoot (Join-Path $serverRoot "mods")
$total = (Get-ChildItem -LiteralPath $modsRoot -Filter *.jar -File -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host "Mods sincronizados para compatibilidad launcher: fuente=$total cliente=$clientCount servidor=$serverCount"
