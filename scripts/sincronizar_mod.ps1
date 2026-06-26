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

$rootPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
$gameConfig = Read-JsonFile (Join-Path $rootPath "game.config.json")
$mc = $gameConfig.minecraft
$serverConfigRel = if ($mc.serverConfig) { [string]$mc.serverConfig } else { "config/minecraft_server.json" }
$serverConfig = Read-JsonFile (Resolve-GamePath $rootPath $serverConfigRel)
$mod = $serverConfig.mod

$pattern = [string]$mod.jarPattern
$candidateFolders = @(
  (Resolve-GamePath $rootPath ([string]$mod.latestJarFolder)),
  (Resolve-GamePath $rootPath ([string]$mod.packagedJarFolder)),
  (Join-Path $rootPath "mods")
)

$latestJar = $null
foreach ($folder in $candidateFolders) {
  if (-not $folder -or -not (Test-Path -LiteralPath $folder)) { continue }
  $latestJar = Get-ChildItem -LiteralPath $folder -Filter $pattern -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($latestJar) { break }
}

if (-not $latestJar) {
  throw "No hay mod bridge disponible. Agrega un jar que calce con '$pattern' en game/mods o dist/mods."
}

foreach ($target in @($mod.installTargets)) {
  $targetPath = Resolve-GamePath $rootPath ([string]$target)
  New-Item -ItemType Directory -Force -Path $targetPath | Out-Null

  if ([System.IO.Path]::GetFullPath($targetPath) -eq [System.IO.Path]::GetFullPath($latestJar.DirectoryName)) {
    Write-Host "Mod ya presente en: $targetPath"
    continue
  }

  Get-ChildItem -LiteralPath $targetPath -Filter $pattern -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

  Copy-Item -LiteralPath $latestJar.FullName -Destination (Join-Path $targetPath $latestJar.Name) -Force
  Write-Host "Mod instalado en: $targetPath"
}
