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

function Expand-ConfiguredPath {
  param(
    [string]$Value,
    [string]$RootPath
  )
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $null
  }
  $expanded = [Environment]::ExpandEnvironmentVariables($Value)
  if ([System.IO.Path]::IsPathRooted($expanded)) {
    return $expanded
  }
  return (Join-Path $RootPath $expanded)
}

function Copy-DirectoryContent {
  param(
    [string]$Source,
    [string]$Destination
  )
  if (-not (Test-Path -LiteralPath $Source)) {
    return
  }
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
  }
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

function Sync-ClientMods {
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
      if (Test-IsClientHandshakeCompatibleMod $_.Name) {
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

function Find-Java {
  param([string]$RootPath)
  $candidates = @(
    (Join-Path $RootPath "tools\java\bin\java.exe"),
    (Join-Path $env:JAVA_HOME "bin\java.exe")
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  $cmd = Get-Command "java.exe" -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  return $null
}

function Get-ForgeInstaller {
  param(
    [string]$ForgeVersion,
    [string]$RootPath,
    [string]$MinecraftRoot
  )

  $installerForgeVersion = $ForgeVersion -replace "-forge-", "-"
  $installerName = "forge-$installerForgeVersion-installer.jar"
  $installerCandidates = @(
    (Join-Path $RootPath "tools\$installerName"),
    (Join-Path $RootPath "server\$installerName"),
    (Join-Path $MinecraftRoot $installerName)
  )

  foreach ($candidate in $installerCandidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  $target = Join-Path $RootPath "tools\$installerName"
  $installerUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/$installerForgeVersion/$installerName"
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
  Write-Host "Descargando Forge Client Installer:"
  Write-Host "  $installerUrl"
  Invoke-WebRequest -Uri $installerUrl -OutFile $target
  return $target
}

function Ensure-ForgeClient {
  param(
    [string]$MinecraftRoot,
    [string]$ForgeVersion,
    [string]$JavaExe,
    [string]$RootPath
  )

  $forgeVersionDir = Join-Path (Join-Path $MinecraftRoot "versions") $ForgeVersion
  if (Test-Path -LiteralPath $forgeVersionDir) {
    return
  }

  if (-not $JavaExe) {
    Write-Warning "No se encontro Java. Abre tu launcher e instala Forge $ForgeVersion una vez, o agrega tools\java al paquete."
    return
  }

  $installer = Get-ForgeInstaller $ForgeVersion $RootPath $MinecraftRoot

  Push-Location $MinecraftRoot
  try {
    & $JavaExe -jar $installer --installClient | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Fallo instalando Forge $ForgeVersion."
    }
  } finally {
    Pop-Location
  }
}

function Upsert-LauncherProfile {
  param(
    [string]$MinecraftRoot,
    [string]$ProfileId,
    [string]$ProfileName,
    [string]$GameDir,
    [string]$ForgeVersion
  )

  $profilesPath = Join-Path $MinecraftRoot "launcher_profiles.json"
  $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  $desiredJavaArgs = if ($mc.javaArgs) { [string]$mc.javaArgs } else { "-Xms2G -Xmx8G" }

  if (Test-Path -LiteralPath $profilesPath) {
    try {
      $profiles = Get-Content -LiteralPath $profilesPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
      throw "launcher_profiles.json invalido. No se modifica para proteger perfiles del usuario."
    }
  } else {
    $profiles = [pscustomobject]@{ profiles = [pscustomobject]@{} }
  }

  if (-not $profiles.profiles) {
    $profiles | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{}) -Force
  }

  $existing = $profiles.profiles.PSObject.Properties[$ProfileId]
  if ($existing) {
    $current = $existing.Value
    $alreadyOk = $current.name -eq $ProfileName -and
      $current.type -eq "custom" -and
      $current.lastVersionId -eq $ForgeVersion -and
      $current.gameDir -eq $GameDir -and
      $current.javaArgs -eq $desiredJavaArgs
    if ($alreadyOk) {
      return
    }
  }

  if (Test-Path -LiteralPath $profilesPath) {
    $backup = "$profilesPath.backup-$((Get-Date).ToString('yyyyMMddHHmmss'))"
    Copy-Item -LiteralPath $profilesPath -Destination $backup -Force
  }

  $profile = [ordered]@{
    name = $ProfileName
    type = "custom"
    created = if ($existing -and $existing.Value.created) { $existing.Value.created } else { $now }
    lastUsed = $now
    icon = "Crafting_Table"
    lastVersionId = $ForgeVersion
    gameDir = $GameDir
    javaArgs = $desiredJavaArgs
  }

  $profiles.profiles | Add-Member -NotePropertyName $ProfileId -NotePropertyValue $profile -Force
  $profiles | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $profilesPath -Encoding UTF8
}

function Test-ByteArrayEqual {
  param(
    [byte[]]$Left,
    [byte[]]$Right
  )

  if ($Left.Length -ne $Right.Length) {
    return $false
  }

  for ($i = 0; $i -lt $Left.Length; $i++) {
    if ($Left[$i] -ne $Right[$i]) {
      return $false
    }
  }

  return $true
}

function New-MinecraftServersDatBytes {
  param(
    [string]$Name,
    [string]$Address
  )

  $bytes = [System.Collections.Generic.List[byte]]::new()
  function Add-Byte([int]$Value) { $bytes.Add([byte]$Value) }
  function Add-Int16([int]$Value) {
    $bytes.Add([byte](($Value -shr 8) -band 0xff))
    $bytes.Add([byte]($Value -band 0xff))
  }
  function Add-Int32([int]$Value) {
    $bytes.Add([byte](($Value -shr 24) -band 0xff))
    $bytes.Add([byte](($Value -shr 16) -band 0xff))
    $bytes.Add([byte](($Value -shr 8) -band 0xff))
    $bytes.Add([byte]($Value -band 0xff))
  }
  function Add-StringPayload([string]$Value) {
    $encoded = [System.Text.Encoding]::UTF8.GetBytes($Value)
    Add-Int16 $encoded.Length
    $bytes.AddRange([byte[]]$encoded)
  }
  function Add-NamedByte([string]$Key, [byte]$Value) {
    Add-Byte 1
    Add-StringPayload $Key
    Add-Byte $Value
  }
  function Add-NamedString([string]$Key, [string]$Value) {
    Add-Byte 8
    Add-StringPayload $Key
    Add-StringPayload $Value
  }

  Add-Byte 10
  Add-Int16 0
  Add-Byte 9
  Add-StringPayload "servers"
  Add-Byte 10
  Add-Int32 1
  Add-NamedByte "hidden" 0
  Add-NamedString "ip" $Address
  Add-NamedString "name" $Name
  Add-Byte 0
  Add-Byte 0

  return $bytes.ToArray()
}

function Write-MinecraftServerList {
  param(
    [string]$GameDir,
    [string]$Name,
    [string]$Address
  )

  New-Item -ItemType Directory -Force -Path $GameDir | Out-Null
  $bytes = New-MinecraftServersDatBytes $Name $Address
  foreach ($fileName in @("servers.dat", "servers.dat_old")) {
    $target = Join-Path $GameDir $fileName
    if (Test-Path -LiteralPath $target) {
      $current = [System.IO.File]::ReadAllBytes($target)
      if (Test-ByteArrayEqual $current $bytes) {
        continue
      }
      $backup = "$target.before-minecraft-server-list"
      if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $target -Destination $backup -Force
      }
    }
    [System.IO.File]::WriteAllBytes($target, $bytes)
  }
}

function Repair-MinecraftQuickPlay {
  param(
    [string]$MinecraftRoot,
    [string]$ProfileId,
    [string]$ServerName,
    [string]$Address
  )

  $quickPlayPath = Join-Path $MinecraftRoot "launcher_quick_play.json"
  if (-not (Test-Path -LiteralPath $quickPlayPath)) {
    return
  }

  $quickPlay = Get-Content -LiteralPath $quickPlayPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $quickPlay.quickPlayData) {
    return
  }

  $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $changed = $false
  foreach ($account in @($quickPlay.quickPlayData.PSObject.Properties)) {
    $originalItems = @($account.Value)
    $retained = @()
    $desiredItem = $null
    $removedMatching = $false
    $desiredWasFirst = $false

    if ($originalItems.Count -gt 0) {
      $first = $originalItems[0]
      $firstConfigId = if ($first.javaInstance) { [string]$first.javaInstance.configId } else { "" }
      $desiredWasFirst = $first.name -eq $ServerName -and $first.id -eq $Address -and $firstConfigId -eq $ProfileId
    }

    foreach ($item in $originalItems) {
      $configId = if ($item.javaInstance) { [string]$item.javaInstance.configId } else { "" }
      $isDesired = $item.name -eq $ServerName -and $item.id -eq $Address -and $configId -eq $ProfileId
      $isMatching = $item.name -eq $ServerName -or $item.id -eq $Address -or $configId -eq $ProfileId

      if ($isDesired -and -not $desiredItem) {
        $desiredItem = $item
      } elseif ($isMatching) {
        $removedMatching = $true
      } else {
        $retained += $item
      }
    }

    if ($desiredItem) {
      $account.Value = @($desiredItem) + $retained
    } else {
      $entry = [pscustomobject]@{
        epochLastPlayedTimeMs = $nowMs
        id = $Address
        javaInstance = [pscustomobject]@{
          configId = $ProfileId
          game = [pscustomobject]@{
            gamemode = "creative"
            type = "multiplayer"
          }
        }
        name = $ServerName
        source = "Java"
      }
      $account.Value = @($entry) + $retained
      $changed = $true
    }

    if ($removedMatching -or -not $desiredWasFirst) {
      $changed = $true
    }
  }

  if ($changed) {
    try {
      $backup = "$quickPlayPath.before-minecraft-quick-play"
      if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $quickPlayPath -Destination $backup -Force
      }
      $quickPlay | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $quickPlayPath -Encoding UTF8
    } catch {
      Write-Host "Aviso: no se pudo actualizar Minecraft Quick Play porque el launcher lo tiene bloqueado." -ForegroundColor Yellow
    }
  }
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$config = Read-JsonFile (Join-Path $rootPath "game.config.json")
$manifestPath = Join-Path $rootPath "game-manifest.json"
$manifest = if (Test-Path -LiteralPath $manifestPath) { Read-JsonFile $manifestPath } else { $null }
$mc = $config.minecraft
if (-not $mc) {
  throw "game.config.json no tiene bloque minecraft."
}

$minecraftRoot = Join-Path $env:APPDATA ".minecraft"
$versionsRoot = Join-Path $minecraftRoot "versions"
$mcVersion = [string]$mc.mcVersion
$loaderVersion = [string]$mc.loaderVersion
$profileName = [string]$mc.profileName
$versionFolder = [string]$mc.versionFolder
$profileId = if ($mc.profileId) { [string]$mc.profileId } else { $versionFolder.ToLowerInvariant() }
$forgeVersion = "$mcVersion-forge-$loaderVersion"

if ([string]::IsNullOrWhiteSpace($versionFolder)) {
  throw "minecraft.versionFolder es obligatorio."
}

$gameDir = Expand-ConfiguredPath ([string]$mc.gameDir) $rootPath
if (-not $gameDir) {
  $gameDir = Join-Path $versionsRoot $versionFolder
}

$sourceMods = Expand-ConfiguredPath ([string]$mc.modsRoot) $rootPath
$sourceConfig = Expand-ConfiguredPath ([string]$mc.configRoot) $rootPath
$sourceOverrides = Expand-ConfiguredPath ([string]$mc.overridesRoot) $rootPath
$modDownloader = Join-Path $PSScriptRoot "descargar_mods_curseforge.ps1"
if (Test-Path -LiteralPath $modDownloader) {
  & $modDownloader -Root $rootPath
}

New-Item -ItemType Directory -Force -Path $minecraftRoot, $versionsRoot, $gameDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $gameDir "mods"), (Join-Path $gameDir "config"), (Join-Path $gameDir "saves"), (Join-Path $gameDir "logs") | Out-Null

Copy-DirectoryContent $sourceOverrides $gameDir
$clientModsResult = Sync-ClientMods $sourceMods (Join-Path $gameDir "mods")
Copy-DirectoryContent $sourceConfig (Join-Path $gameDir "config")

$infoPath = Join-Path $gameDir "tiktok-live-launcher-info.json"
$infoMatches = $false
if (Test-Path -LiteralPath $infoPath) {
  try {
    $currentInfo = Get-Content -LiteralPath $infoPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $infoMatches = $currentInfo.profileName -eq $profileName -and
      $currentInfo.profileId -eq $profileId -and
      $currentInfo.versionFolder -eq $versionFolder -and
      $currentInfo.forgeVersion -eq $forgeVersion -and
      $currentInfo.gameDir -eq $gameDir -and
      $currentInfo.packageRoot -eq $rootPath
  } catch {
    $infoMatches = $false
  }
}
if (-not $infoMatches) {
  [ordered]@{
    profileName = $profileName
    profileId = $profileId
    versionFolder = $versionFolder
    forgeVersion = $forgeVersion
    gameDir = $gameDir
    packageRoot = $rootPath
    preparedAt = (Get-Date).ToUniversalTime().ToString("o")
  } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $infoPath -Encoding UTF8
}

$javaExe = Find-Java $rootPath
Ensure-ForgeClient $minecraftRoot $forgeVersion $javaExe $rootPath
Upsert-LauncherProfile $minecraftRoot $profileId $profileName $gameDir $forgeVersion
$serverHost = if ($mc.serverHost) { [string]$mc.serverHost } else { "127.0.0.1" }
$serverPort = if ($mc.serverPort) { [int]$mc.serverPort } else { 25565 }
$connectAddress = if ($mc.connectAddress) { [string]$mc.connectAddress } else { "${serverHost}:$serverPort" }
$serverName = if ($manifest -and $manifest.minecraft -and $manifest.minecraft.serverName) {
  [string]$manifest.minecraft.serverName
} elseif ($manifest -and $manifest.name) {
  [string]$manifest.name
} else {
  $profileName
}
Write-MinecraftServerList $gameDir $serverName $connectAddress
Repair-MinecraftQuickPlay $minecraftRoot $profileId $serverName $connectAddress

Write-Host "Cliente Minecraft preparado."
Write-Host "Perfil oficial: $profileName"
Write-Host "TLauncher/modpacks: $versionFolder"
Write-Host "Version base si la pide: $forgeVersion"
Write-Host "Servidor local: $connectAddress"
Write-Host "Game directory: $gameDir"
Write-Host "Mods cliente: copiados=$($clientModsResult.Copied) omitidos_por_servidor_local=$($clientModsResult.Skipped)"
Write-Host "Info: $infoPath"
