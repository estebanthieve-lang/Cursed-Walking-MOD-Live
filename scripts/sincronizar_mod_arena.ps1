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

function Get-ClientHandshakeExcludedModPatterns {
  return @(
    "*copycats*",
    "create-*",
    "*create_netherless*",
    "*createdeco*",
    "*inventorysorter*",
    "*particular*",
    "*sliceanddice*",
    "*steam_rails*"
  )
}

function Test-IsClientHandshakeCompatibleMod {
  param([string]$FileName)
  $name = $FileName.ToLowerInvariant()
  foreach ($pattern in Get-ClientHandshakeExcludedModPatterns) {
    if ($name -like $pattern) {
      return $false
    }
  }
  return $true
}

function Copy-ClientJars {
  param(
    [string]$Source,
    [string]$Destination
  )
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Get-ChildItem -LiteralPath $Destination -Filter *.jar -File -ErrorAction SilentlyContinue | Remove-Item -Force

  $count = 0
  $skipped = 0
  if (Test-Path -LiteralPath $Source) {
    Get-ChildItem -LiteralPath $Source -Filter *.jar -File -ErrorAction SilentlyContinue | ForEach-Object {
      if (Test-IsClientHandshakeCompatibleMod $_.Name) {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $Destination $_.Name) -Force
        $count += 1
      } else {
        $skipped += 1
      }
    }
  }

  return [pscustomobject]@{
    Copied = $count
    Skipped = $skipped
  }
}

function Get-ClientOnlyServerModPatterns {
  return @(
    "*ambientenvironment*",
    "*ambientsounds*",
    "*appleskin*",
    "*badoptimizations*",
    "*betterbiomereblend*",
    "*chat_heads*",
    "*cleanswing*",
    "*colorwheel*",
    "*controlling*",
    "*copycats*",
    "*craftpresence*",
    "create-*",
    "*create_netherless*",
    "*createdeco*",
    "*crashassistant*",
    "*drippyloadingscreen*",
    "*dynamiclights*",
    "*eatinganimation*",
    "*embeddium*",
    "*emi-*",
    "*enchantmentdescriptions*",
    "*enhancedvisuals*",
    "*entity_model_features*",
    "*entity_texture_features*",
    "*entityculling*",
    "*euphoriapatcher*",
    "*fancymenu*",
    "*gamemenuremove*",
    "*immediatelyfast*",
    "*inventorysorter*",
    "*jade-*",
    "*jei-*",
    "*konkrete*",
    "*melody*",
    "*mousetweaks*",
    "*not enough recipe book*",
    "*notenoughanimations*",
    "*oculus*",
    "*particular*",
    "*searchables*",
    "*sliceanddice*",
    "*sound-physics*",
    "*steam_rails*",
    "*toastcontrol*",
    "*xaeros_minimap*",
    "*xaerosworldmap*"
  )
}

function Test-IsServerCompatibleMod {
  param([string]$FileName)
  $name = $FileName.ToLowerInvariant()
  foreach ($pattern in Get-ClientOnlyServerModPatterns) {
    if ($name -like $pattern) {
      return $false
    }
  }
  return $true
}

function Copy-ServerJars {
  param(
    [string]$Source,
    [string]$Destination
  )
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Get-ChildItem -LiteralPath $Destination -Filter *.jar -File -ErrorAction SilentlyContinue | Remove-Item -Force

  $count = 0
  $skipped = 0
  if (Test-Path -LiteralPath $Source) {
    Get-ChildItem -LiteralPath $Source -Filter *.jar -File -ErrorAction SilentlyContinue | ForEach-Object {
      if (Test-IsServerCompatibleMod $_.Name) {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $Destination $_.Name) -Force
        $count += 1
      } else {
        $skipped += 1
      }
    }
  }

  return [pscustomobject]@{
    Copied = $count
    Skipped = $skipped
  }
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

$clientResult = Copy-ClientJars $modsRoot (Join-Path $gameDir "mods")
$serverResult = Copy-ServerJars $modsRoot (Join-Path $serverRoot "mods")
$total = (Get-ChildItem -LiteralPath $modsRoot -Filter *.jar -File -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host "Mods sincronizados para compatibilidad launcher: fuente=$total cliente=$($clientResult.Copied) omitidos_handshake=$($clientResult.Skipped) servidor=$($serverResult.Copied) omitidos_cliente=$($serverResult.Skipped)"
