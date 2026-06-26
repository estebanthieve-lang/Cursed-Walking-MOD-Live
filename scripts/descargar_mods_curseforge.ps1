param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$RequiredOnly,
  [int]$Retries = 3
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

function Get-RedirectLocation {
  param([string]$Url)

  try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 60
    if ($response.Headers.Location) {
      return [string]$response.Headers.Location
    }
  } catch {
    $response = $_.Exception.Response
    if ($response -and $response.Headers.Location) {
      return [string]$response.Headers.Location
    }
    throw
  }

  throw "CurseForge no entrego URL de descarga para $Url"
}

function Get-FileNameFromUrl {
  param(
    [string]$Url,
    [string]$Fallback
  )
  $uri = [Uri]$Url
  $name = [Uri]::UnescapeDataString([System.IO.Path]::GetFileName($uri.AbsolutePath))
  if ([string]::IsNullOrWhiteSpace($name) -or -not $name.EndsWith(".jar", [System.StringComparison]::OrdinalIgnoreCase)) {
    return $Fallback
  }
  return Get-SafeFileName $name
}

function Get-SafeFileName {
  param([string]$Name)

  $safe = $Name
  foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
    $safe = $safe.Replace([string]$char, "_")
  }
  $safe = $safe.Replace("[", "(").Replace("]", ")")
  $safe = $safe.Trim().TrimEnd(".")
  if ([string]::IsNullOrWhiteSpace($safe)) {
    return "curseforge-mod.jar"
  }
  return $safe
}

function Read-State {
  param([string]$Path)
  $state = @{}
  if (-not (Test-Path -LiteralPath $Path)) {
    return $state
  }

  try {
    $json = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($item in @($json.files)) {
      if ($item.key) {
        $state[[string]$item.key] = [string]$item.fileName
      }
    }
  } catch {
    Write-Host "No se pudo leer estado previo de mods, se reconstruira: $Path" -ForegroundColor Yellow
  }
  return $state
}

function Write-State {
  param(
    [string]$Path,
    [hashtable]$State
  )

  $items = foreach ($key in ($State.Keys | Sort-Object)) {
    [ordered]@{
      key = $key
      fileName = $State[$key]
    }
  }

  [ordered]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    files = @($items)
  } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
}

$rootPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
$config = Read-JsonFile (Join-Path $rootPath "game.config.json")
$mc = $config.minecraft
if (-not $mc) {
  throw "game.config.json no tiene bloque minecraft."
}

$curseforge = $config.curseforge
$manifestRel = if ($curseforge -and $curseforge.sourceManifest) { [string]$curseforge.sourceManifest } else { "curseforge/manifest.json" }
$manifestPath = Resolve-GamePath $rootPath $manifestRel
$manifest = Read-JsonFile $manifestPath
$modsRoot = Resolve-GamePath $rootPath ([string]$mc.modsRoot)
New-Item -ItemType Directory -Force -Path $modsRoot | Out-Null

$files = @($manifest.files | Where-Object { -not $RequiredOnly -or $_.required -ne $false })
if ($files.Count -eq 0) {
  throw "El manifest CurseForge no trae archivos para descargar: $manifestPath"
}

$statePath = Join-Path $modsRoot ".curseforge-downloads.json"
$state = Read-State $statePath
$fallbackDownloads = @{
  "930207:5650506" = [ordered]@{
    fileName = "noisium-forge-2.3.0+mc1.20-1.20.1.jar"
    url = "https://github.com/Steveplays28/noisium/releases/download/v2.3.0%2Bmc1.20-1.20.1/noisium-forge-2.3.0%2Bmc1.20-1.20.1.jar"
  }
}
$failures = New-Object System.Collections.Generic.List[string]
$downloaded = 0
$skipped = 0
$total = $files.Count
$index = 0

foreach ($file in $files) {
  $index++
  $projectId = [string]$file.projectID
  $fileId = [string]$file.fileID
  if ([string]::IsNullOrWhiteSpace($projectId) -or [string]::IsNullOrWhiteSpace($fileId)) {
    $failures.Add("Entrada invalida en manifest: projectID=$projectId fileID=$fileId") | Out-Null
    continue
  }

  $key = "${projectId}:${fileId}"
  if ($state.ContainsKey($key)) {
    $existingPath = Join-Path $modsRoot $state[$key]
    if (Test-Path -LiteralPath $existingPath) {
      $skipped++
      continue
    }
  }

  $apiUrl = "https://www.curseforge.com/api/v1/mods/$projectId/files/$fileId/download"
  $ok = $false
  $lastError = $null

  for ($attempt = 1; $attempt -le $Retries; $attempt++) {
    try {
      Write-Host "[$index/$total] Descargando mod $projectId/$fileId..."
      try {
        $downloadUrl = Get-RedirectLocation $apiUrl
        $fileName = Get-FileNameFromUrl $downloadUrl "${projectId}-${fileId}.jar"
      } catch {
        if (-not $fallbackDownloads.ContainsKey($key)) {
          throw
        }
        $fallback = $fallbackDownloads[$key]
        $downloadUrl = [string]$fallback.url
        $fileName = Get-SafeFileName ([string]$fallback.fileName)
        Write-Host "Usando descarga alternativa oficial para $key."
      }
      $targetPath = Join-Path $modsRoot $fileName
      $partialPath = "$targetPath.part"

      Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing -MaximumRedirection 5 -TimeoutSec 180 -OutFile $partialPath
      if (-not (Test-Path -LiteralPath $partialPath) -or (Get-Item -LiteralPath $partialPath).Length -le 0) {
        throw "Descarga vacia: $fileName"
      }
      Move-Item -LiteralPath $partialPath -Destination $targetPath -Force
      $state[$key] = $fileName
      Write-State $statePath $state
      $downloaded++
      $ok = $true
      break
    } catch {
      $lastError = $_.Exception.Message
      Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 8))
    } finally {
      if ($partialPath -and (Test-Path -LiteralPath $partialPath)) {
        Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
      }
    }
  }

  if (-not $ok) {
    $failures.Add("$key -> $lastError") | Out-Null
  }
}

$jarCount = (Get-ChildItem -LiteralPath $modsRoot -Filter *.jar -File -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host "Mods CurseForge listos: $jarCount jar(s). Descargados: $downloaded. Ya estaban: $skipped."

if ($failures.Count -gt 0) {
  Write-Host "Fallaron $($failures.Count) descarga(s):" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host "- $failure" -ForegroundColor Red
  }
  throw "No se pudieron descargar todos los mods de CurseForge."
}
