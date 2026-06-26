param(
  [Parameter(Mandatory = $true)]
  [string]$InstallRoot,

  [string]$UpdateRoot = ""
)

$ErrorActionPreference = "Stop"

function Normalize-InputPath([string]$path) {
  return ($path -replace '"', "").Trim()
}

function Resolve-LocalPath([string]$root, [string]$relative) {
  $clean = $relative -replace "/", "\"
  return [System.IO.Path]::GetFullPath((Join-Path (Normalize-InputPath $root) $clean))
}

function Resolve-ConfiguredPath([string]$root, [string]$path) {
  if (-not $path) { return "" }
  $appData = if ($env:APPDATA) { $env:APPDATA } else { Join-Path $env:USERPROFILE "AppData\Roaming" }
  $expanded = $path -replace "%APPDATA%", [System.Text.RegularExpressions.Regex]::Escape($appData)
  $expanded = $expanded -replace "\\\\", "\"
  $expanded = [Environment]::ExpandEnvironmentVariables($expanded)
  if ([System.IO.Path]::IsPathRooted($expanded)) { return [System.IO.Path]::GetFullPath($expanded) }
  return Resolve-LocalPath $root $expanded
}

function Read-JsonFile([string]$path) {
  return Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
}

function Read-JsonFromUrl([string]$url) {
  $response = Invoke-WebRequest -Uri $url -UseBasicParsing
  $json = [string]$response.Content
  return $json.Trim([char]0xFEFF) | ConvertFrom-Json
}

function Get-LatestManifest($manifest) {
  $latestUrl = [string]$manifest.updates.latestManifestUrl
  if (-not $latestUrl) { return $manifest }

  Write-Host ""
  Write-Host "Leyendo manifest remoto:" -ForegroundColor Cyan
  Write-Host "  $latestUrl"
  return Read-JsonFromUrl $latestUrl
}

function Backup-ExistingPath([string]$target, [string]$backupRoot, [string]$relative) {
  if (-not (Test-Path -LiteralPath $target)) { return }
  $backupTarget = Resolve-LocalPath $backupRoot $relative
  $backupParent = Split-Path $backupTarget -Parent
  if ($backupParent) { New-Item -ItemType Directory -Force -Path $backupParent | Out-Null }
  Copy-Item -LiteralPath $target -Destination $backupTarget -Recurse -Force
}

function Sync-Directory([string]$sourceDir, [string]$targetDir) {
  if ((Test-Path -LiteralPath $targetDir) -and -not (Get-Item -LiteralPath $targetDir).PSIsContainer) {
    Remove-Item -LiteralPath $targetDir -Force
  }

  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

  $sourceNames = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  Get-ChildItem -LiteralPath $sourceDir -Force | ForEach-Object {
    $sourceNames[$_.Name] = $_.FullName
  }

  Get-ChildItem -LiteralPath $targetDir -Force | ForEach-Object {
    if (-not $sourceNames.ContainsKey($_.Name)) {
      Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
  }

  Get-ChildItem -LiteralPath $sourceDir -Force | ForEach-Object {
    $targetChild = Join-Path $targetDir $_.Name
    if ($_.PSIsContainer) {
      Sync-Directory $_.FullName $targetChild
    } else {
      $targetParent = Split-Path $targetChild -Parent
      if ($targetParent) { New-Item -ItemType Directory -Force -Path $targetParent | Out-Null }
      if ((Test-Path -LiteralPath $targetChild) -and (Get-Item -LiteralPath $targetChild).PSIsContainer) {
        Remove-Item -LiteralPath $targetChild -Recurse -Force
      }
      Copy-Item -LiteralPath $_.FullName -Destination $targetChild -Force
    }
  }
}

function Copy-UpdatePath([string]$source, [string]$target) {
  if ((Get-Item -LiteralPath $source).PSIsContainer) {
    Sync-Directory $source $target
    return
  }
  $targetParent = Split-Path $target -Parent
  if ($targetParent) { New-Item -ItemType Directory -Force -Path $targetParent | Out-Null }
  if ((Test-Path -LiteralPath $target) -and (Get-Item -LiteralPath $target).PSIsContainer) {
    Remove-Item -LiteralPath $target -Recurse -Force
  }
  Copy-Item -LiteralPath $source -Destination $target -Force
}

function Get-DownloadedUpdateRoot($manifest) {
  $latestManifest = Get-LatestManifest $manifest
  $downloadUrl = [string]$latestManifest.updates.downloadUrl
  if (-not $downloadUrl) { return $null }

  Write-Host ""
  Write-Host "Descargando paquete liviano de actualizacion:" -ForegroundColor Cyan
  Write-Host "  $downloadUrl"

  $tempRoot = Join-Path $env:TEMP ("juego-update-" + [guid]::NewGuid().ToString("N"))
  $zipPath = Join-Path $tempRoot "update.zip"
  $extractRoot = Join-Path $tempRoot "extract"
  New-Item -ItemType Directory -Force -Path $tempRoot,$extractRoot | Out-Null
  Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
  Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force

  $candidate = Get-ChildItem -LiteralPath $extractRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName "game-manifest.json")
  } | Select-Object -First 1
  if (-not $candidate -and (Test-Path -LiteralPath (Join-Path $extractRoot "game-manifest.json"))) {
    $candidate = Get-Item -LiteralPath $extractRoot
  }
  if (-not $candidate) {
    throw "El ZIP descargado no trae game-manifest.json en la raiz."
  }

  return @{
    Root = $candidate.FullName
    Temp = $tempRoot
  }
}

$installPath = [System.IO.Path]::GetFullPath((Normalize-InputPath $InstallRoot))
$configPath = Join-Path $installPath "game.config.json"
if (-not (Test-Path -LiteralPath $configPath)) {
  throw "Falta game.config.json en la instalacion actual."
}

$config = Read-JsonFile $configPath
$currentManifestPath = Join-Path $installPath "game-manifest.json"
$currentManifest = if (Test-Path -LiteralPath $currentManifestPath) { Read-JsonFile $currentManifestPath } else { $null }
$downloaded = $null

if (-not $UpdateRoot) {
  $downloaded = Get-DownloadedUpdateRoot $currentManifest
  if ($downloaded) {
    $UpdateRoot = $downloaded.Root
  } else {
    Write-Host ""
    Write-Host "Pega la ruta de la carpeta de actualizacion."
    Write-Host "Debe ser una carpeta nueva del mismo juego, no un ZIP directo."
    $UpdateRoot = Read-Host "Ruta"
  }
}

$updatePath = [System.IO.Path]::GetFullPath((Normalize-InputPath $UpdateRoot))
if (-not (Test-Path -LiteralPath $updatePath)) {
  throw "No existe la carpeta de actualizacion: $updatePath"
}

$incomingManifestPath = Join-Path $updatePath "game-manifest.json"
if (-not (Test-Path -LiteralPath $incomingManifestPath)) {
  throw "La actualizacion no trae game-manifest.json"
}

$incomingManifest = Read-JsonFile $incomingManifestPath
if ($currentManifest -and $currentManifest.gameId -and $incomingManifest.gameId -and $currentManifest.gameId -ne $incomingManifest.gameId) {
  throw "La actualizacion es de otro juego. Actual: $($currentManifest.gameId), update: $($incomingManifest.gameId)"
}

$incomingConfigPath = Join-Path $updatePath "game.config.json"
$incomingConfig = if (Test-Path -LiteralPath $incomingConfigPath) { Read-JsonFile $incomingConfigPath } else { $null }

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$updateBackupRoot = if ($config.updateBackupRoot) { Resolve-ConfiguredPath $installPath ([string]$config.updateBackupRoot) } else { Join-Path $installPath "backups\updates" }
$backupRoot = Join-Path $updateBackupRoot "update-$timestamp"
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

$protected = @($config.protectedPaths)
$updatable = @($config.updatablePaths)
if ($incomingConfig) {
  $protected += @($incomingConfig.protectedPaths)
  $updatable += @($incomingConfig.updatablePaths)
}
$protected = $protected | Where-Object { $_ } | Select-Object -Unique
$updatable = $updatable | Where-Object { $_ } | Select-Object -Unique
if (-not $updatable -or $updatable.Count -eq 0) {
  $updatable = @("runtime", "assets", "game", "scripts", "game-manifest.json", "ACTUALIZAR_JUEGO.cmd", "INICIAR_JUEGO.cmd", "VALIDAR_JUEGO.cmd")
}

Write-Host ""
Write-Host "Instalacion: $installPath"
Write-Host "Actualizacion: $updatePath"
Write-Host "Backup: $backupRoot"
if ($config.saveRoot) {
  Write-Host "No se tocaran partidas/datos Live: $(Resolve-ConfiguredPath $installPath ([string]$config.saveRoot))" -ForegroundColor Green
}
Write-Host ""

foreach ($relative in $updatable) {
  if ($protected -contains $relative) {
    Write-Host "Saltando ruta protegida: $relative" -ForegroundColor Yellow
    continue
  }

  $source = Resolve-LocalPath $updatePath $relative
  if (-not (Test-Path -LiteralPath $source)) {
    Write-Host "No viene en update, se deja igual: $relative"
    continue
  }

  $target = Resolve-LocalPath $installPath $relative
  Backup-ExistingPath $target $backupRoot $relative
  Copy-UpdatePath $source $target
  Write-Host "Actualizado: $relative" -ForegroundColor Green
}

Write-Host ""
Write-Host "Listo. No se tocaron estas carpetas protegidas:" -ForegroundColor Green
foreach ($relative in $protected) {
  Write-Host "- $relative"
}
Write-Host ""
Write-Host "Ahora ejecuta VALIDAR_JUEGO.cmd y luego INICIAR_JUEGO.cmd." -ForegroundColor Cyan

if ($downloaded -and $downloaded.Temp -and (Test-Path -LiteralPath $downloaded.Temp)) {
  Remove-Item -LiteralPath $downloaded.Temp -Recurse -Force -ErrorAction SilentlyContinue
}
