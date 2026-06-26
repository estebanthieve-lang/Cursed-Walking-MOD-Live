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

function Copy-DirectoryContent {
  param(
    [string]$Source,
    [string]$Destination
  )
  if ([string]::IsNullOrWhiteSpace($Source) -or -not (Test-Path -LiteralPath $Source)) {
    return
  }
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
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

function Sync-ServerMods {
  param(
    [string]$Source,
    [string]$Destination
  )
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Get-ChildItem -LiteralPath $Destination -Filter *.jar -File -ErrorAction SilentlyContinue | Remove-Item -Force

  $copied = 0
  $skipped = 0
  if (Test-Path -LiteralPath $Source) {
    Get-ChildItem -LiteralPath $Source -Filter *.jar -File -ErrorAction SilentlyContinue | ForEach-Object {
      if (Test-IsServerCompatibleMod $_.Name) {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $Destination $_.Name) -Force
        $copied += 1
      } else {
        $skipped += 1
      }
    }
  }

  return [pscustomobject]@{
    Copied = $copied
    Skipped = $skipped
  }
}

$rootPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
$gameConfig = Read-JsonFile (Join-Path $rootPath "game.config.json")
$mc = $gameConfig.minecraft
if (-not $mc) {
  throw "game.config.json no tiene bloque minecraft."
}

$serverConfigRel = if ($mc.serverConfig) { [string]$mc.serverConfig } else { "config/minecraft_server.json" }
$serverConfigPath = Resolve-GamePath $rootPath $serverConfigRel
$serverConfig = Read-JsonFile $serverConfigPath
if ($serverConfig.server.enabled -eq $false) {
  Write-Host "Servidor local desactivado en $serverConfigRel."
  exit 0
}

$serverRoot = Resolve-GamePath $rootPath ([string]$serverConfig.server.serverRoot)
$sourceMods = Resolve-GamePath $rootPath ([string]$mc.modsRoot)
$serverOverrides = if ($mc.serverOverridesRoot) { Resolve-GamePath $rootPath ([string]$mc.serverOverridesRoot) } else { $null }
$modDownloader = Join-Path $PSScriptRoot "descargar_mods_curseforge.ps1"
if (Test-Path -LiteralPath $modDownloader) {
  & $modDownloader -Root $rootPath
}
$mcVersion = [string]$serverConfig.server.minecraftVersion
$forgeVersion = [string]$serverConfig.server.forgeVersion
$forgeFull = "$mcVersion-$forgeVersion"
$installerName = "forge-$forgeFull-installer.jar"
$installerPath = Join-Path $serverRoot $installerName
$installerUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/$forgeFull/$installerName"
$javaExe = Join-Path $rootPath "tools\java\bin\java.exe"

if (-not (Test-Path -LiteralPath $javaExe)) {
  throw "Falta Java portable: tools\java\bin\java.exe. No se copia desde Live Arena para ahorrar espacio; agregalo al juego final."
}

$env:JAVA_HOME = Join-Path $rootPath "tools\java"
$env:PATH = (Join-Path $env:JAVA_HOME "bin") + ";" + $env:PATH

New-Item -ItemType Directory -Force -Path $serverRoot, (Join-Path $serverRoot "mods"), (Join-Path $serverRoot "config"), (Join-Path $serverRoot "logs") | Out-Null
Copy-DirectoryContent $serverOverrides $serverRoot
$serverModsResult = Sync-ServerMods $sourceMods (Join-Path $serverRoot "mods")

foreach ($fileName in @("server.properties", "eula.txt")) {
  $source = Join-Path $rootPath "server\$fileName"
  $target = Join-Path $serverRoot $fileName
  if (Test-Path -LiteralPath $source) {
    if ([System.IO.Path]::GetFullPath($source) -ne [System.IO.Path]::GetFullPath($target)) {
      Copy-Item -LiteralPath $source -Destination $target -Force
    }
  }
}

if (-not (Test-Path -LiteralPath $installerPath)) {
  Write-Host "Descargando Forge Server Installer:"
  Write-Host "  $installerUrl"
  Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
}

$runScript = Join-Path $serverRoot "run.bat"
if (-not (Test-Path -LiteralPath $runScript)) {
  Write-Host "Instalando servidor Forge..."
  Push-Location $serverRoot
  try {
    & $javaExe -jar $installerPath --installServer
    if ($LASTEXITCODE -ne 0) {
      throw "Forge server installer fallo con codigo $LASTEXITCODE."
    }
  } finally {
    Pop-Location
  }
}

Write-Host "Servidor preparado en: $serverRoot"
Write-Host "Mods servidor: copiados=$($serverModsResult.Copied) omitidos_cliente=$($serverModsResult.Skipped)"
