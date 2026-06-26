param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Error([string]$Message) { $errors.Add($Message) | Out-Null }
function Add-Warning([string]$Message) { $warnings.Add($Message) | Out-Null }

function Read-JsonFile {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    Add-Error "No existe: $Path"
    return $null
  }
  try {
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Add-Error "JSON invalido: $Path"
    return $null
  }
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$configPath = Join-Path $rootPath "game.config.json"
$manifestPath = Join-Path $rootPath "game-manifest.json"
$config = Read-JsonFile $configPath
$manifest = Read-JsonFile $manifestPath

foreach ($relative in @(
  "INICIAR_JUEGO.cmd",
  "PREPARAR_CLIENTE.cmd",
  "VALIDAR_JUEGO.cmd",
  "ACTUALIZAR_JUEGO.cmd",
  "scripts\actualizar_juego.ps1",
  "scripts\preparar_cliente.ps1",
  "scripts\preparar_servidor.ps1",
  "scripts\sincronizar_mod.ps1",
  "scripts\iniciar_servidor.ps1",
  "scripts\iniciar_event_bus.ps1",
  "runtime\event_bus.py",
  "runtime\game_adapter.py",
  "config\minecraft_server.json",
  "server\server.properties",
  "server\eula.txt"
)) {
  if (-not (Test-Path -LiteralPath (Join-Path $rootPath $relative))) {
    Add-Error "Falta archivo obligatorio de plantilla: $relative"
  }
}

if ($config) {
  if ($config.openBaseOnStart -eq $true) {
    Add-Error "openBaseOnStart debe ser false en la app Tauri."
  }
  if ([string]$config.baseUrl -match "127\.0\.0\.1:5177") {
    Add-Error "No apuntar a 127.0.0.1:5177 en plantillas Tauri."
  }

  $mc = $config.minecraft
  if (-not $mc) {
    Add-Error "Falta bloque minecraft en game.config.json."
  } else {
    foreach ($key in @("mcVersion", "loader", "loaderVersion", "profileId", "profileName", "versionFolder", "gameDir", "modsRoot", "serverPort", "serverRoot", "serverConfig", "bridge", "bridgeQueue")) {
      if (-not $mc.$key) {
        Add-Error "minecraft.$key es obligatorio."
      }
    }
    if ([string]$mc.versionFolder -eq "TikTokMinecraftLive") {
      Add-Error "No reutilizar TikTokMinecraftLive en juegos nuevos."
    }
    if ([string]$mc.profileName -eq "TikTok Minecraft Live") {
      Add-Error "No reutilizar el perfil del juego principal."
    }
  }
}

$serverConfigPath = Join-Path $rootPath "config\minecraft_server.json"
$serverConfig = Read-JsonFile $serverConfigPath
if ($serverConfig) {
  if (-not $serverConfig.server) { Add-Error "config/minecraft_server.json necesita server." }
  if (-not $serverConfig.mod) { Add-Error "config/minecraft_server.json necesita mod." }
  if (-not $serverConfig.bridge) { Add-Error "config/minecraft_server.json necesita bridge." }
  if ($serverConfig.mod -and -not $serverConfig.mod.jarPattern) { Add-Error "config/minecraft_server.json necesita mod.jarPattern." }
  if ($serverConfig.server -and $serverConfig.server.enabled -ne $false) {
    if (-not $serverConfig.server.serverRoot) { Add-Error "config/minecraft_server.json necesita server.serverRoot." }
    if (-not $serverConfig.server.minecraftVersion) { Add-Error "config/minecraft_server.json necesita server.minecraftVersion." }
    if (-not $serverConfig.server.forgeVersion) { Add-Error "config/minecraft_server.json necesita server.forgeVersion." }
  }
}

$eulaPath = Join-Path $rootPath "server\eula.txt"
if (Test-Path -LiteralPath $eulaPath) {
  $eulaText = Get-Content -LiteralPath $eulaPath -Raw -Encoding UTF8
  if ($eulaText -match "eula=false") {
    Add-Warning "server/eula.txt esta en eula=false. Correcto para plantilla; un juego final debe resolver la aceptacion antes de arrancar server."
  }
}

if ($manifest) {
  if (-not $manifest.gameId) { Add-Error "game-manifest.json necesita gameId." }
  if (-not $manifest.eventBus) {
    Add-Error "game-manifest.json necesita eventBus."
  } else {
    if (-not $manifest.eventBus.port) { Add-Error "eventBus.port es obligatorio." }
    if ([int]$manifest.eventBus.port -eq 9010 -and [string]$manifest.gameId -ne "minecraft-tiktok-live") {
      Add-Error "El puerto 9010 pertenece a Minecraft Live Arena. Usa otro puerto."
    }
  }
  if (-not $manifest.actions -or $manifest.actions.Count -eq 0) {
    Add-Warning "El manifest no declara acciones reales."
  }
}

if ($config) {
  if (-not $config.protectedPaths -or $config.protectedPaths.Count -eq 0) {
    Add-Error "game.config.json necesita protectedPaths."
  }
  if (-not $config.updatablePaths -or $config.updatablePaths.Count -eq 0) {
    Add-Error "game.config.json necesita updatablePaths."
  }
  if ($config.protectedPaths -and $config.updatablePaths) {
    $protectedSet = @{}
    foreach ($protectedPath in @($config.protectedPaths)) {
      $protectedSet[[string]$protectedPath] = $true
    }
    foreach ($updatablePath in @($config.updatablePaths)) {
      if ($protectedSet.ContainsKey([string]$updatablePath)) {
        Add-Error "La ruta '$updatablePath' no puede ser protegida y actualizable a la vez."
      }
    }
  }
  foreach ($expectedProtected in @("config", "data", "logs", "user-data", "server/world", "server/logs", "server/crash-reports")) {
    if (@($config.protectedPaths) -notcontains $expectedProtected) {
      Add-Warning "Recomendado proteger '$expectedProtected'."
    }
  }
  foreach ($expectedUpdatable in @("runtime", "scripts", "assets", "game/mods", "server/mods", "ACTUALIZAR_JUEGO.cmd", "INICIAR_JUEGO.cmd", "VALIDAR_JUEGO.cmd")) {
    if (@($config.updatablePaths) -notcontains $expectedUpdatable) {
      Add-Warning "Recomendado marcar actualizable '$expectedUpdatable'."
    }
  }
}

$scriptText = Get-ChildItem -LiteralPath (Join-Path $rootPath "scripts") -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object {
  $_.Name -ne "validar_juego.ps1"
} | ForEach-Object {
  Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
}
if (($scriptText -join "`n") -match "\$python\s*=\s*Get-SystemPython") {
  Add-Error "No usar `$python = Get-SystemPython`; usar `$python = @(Get-SystemPython ...)."
}

if ($warnings.Count -gt 0) {
  Write-Host "Advertencias:"
  $warnings | ForEach-Object { Write-Host "- $_" }
}

if ($errors.Count -gt 0) {
  Write-Host "Errores:"
  $errors | ForEach-Object { Write-Host "- $_" }
  exit 1
}

Write-Host "Plantilla Minecraft valida."
