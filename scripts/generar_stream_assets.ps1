param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function New-Dir {
  param([string]$Path)
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Draw-Banner {
  param(
    [string]$Output,
    [int]$Width,
    [int]$Height,
    [string]$Title,
    [string]$Subtitle,
    [array]$Icons
  )

  $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle 0, 0, $Width, $Height),
    ([System.Drawing.Color]::FromArgb(13, 18, 24)),
    ([System.Drawing.Color]::FromArgb(41, 9, 14)),
    25
  )
  $graphics.FillRectangle($bg, 0, 0, $Width, $Height)

  $accent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(24, 208, 220))
  $danger = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(224, 54, 54))
  $panel = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(185, 8, 12, 16))
  $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(248, 252, 255))
  $muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(205, 218, 225))
  $penAccent = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(24, 208, 220)), ([Math]::Max(4, [int]($Height * 0.01)))
  $penDanger = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(224, 54, 54)), ([Math]::Max(3, [int]($Height * 0.008)))

  $graphics.FillRectangle($panel, [int]($Width * 0.04), [int]($Height * 0.08), [int]($Width * 0.92), [int]($Height * 0.84))
  $graphics.DrawLine($penAccent, [int]($Width * 0.06), [int]($Height * 0.12), [int]($Width * 0.42), [int]($Height * 0.12))
  $graphics.DrawLine($penDanger, [int]($Width * 0.58), [int]($Height * 0.88), [int]($Width * 0.94), [int]($Height * 0.88))

  $titleSize = [Math]::Max(30, [int]($Height * 0.115))
  $subSize = [Math]::Max(16, [int]($Height * 0.038))
  $tagSize = [Math]::Max(14, [int]($Height * 0.03))
  $titleFont = New-Object System.Drawing.Font "Arial", $titleSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $subFont = New-Object System.Drawing.Font "Arial", $subSize, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
  $tagFont = New-Object System.Drawing.Font "Arial", $tagSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)

  $left = [int]($Width * 0.08)
  $top = [int]($Height * 0.25)
  $graphics.DrawString($Title, $titleFont, $white, $left, $top)
  $graphics.DrawString($Subtitle, $subFont, $muted, $left, [int]($top + $titleSize * 1.18))
  $graphics.DrawString("TIKTOK LIVE ACTIONS  |  FORGE 1.20.1", $tagFont, $accent, $left, [int]($Height * 0.72))

  $iconSize = [int]([Math]::Min($Width, $Height) * 0.15)
  $iconGap = [int]($iconSize * 0.18)
  $startX = [int]($Width * 0.64)
  $startY = [int]($Height * 0.2)
  $i = 0
  foreach ($iconPath in $Icons | Select-Object -First 6) {
    if (-not (Test-Path -LiteralPath $iconPath)) { continue }
    $img = [System.Drawing.Image]::FromFile($iconPath)
    $x = $startX + (($i % 3) * ($iconSize + $iconGap))
    $y = $startY + ([Math]::Floor($i / 3) * ($iconSize + $iconGap))
    $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
    $graphics.FillEllipse($shadow, $x + 6, $y + 10, $iconSize, $iconSize)
    $graphics.DrawImage($img, $x, $y, $iconSize, $iconSize)
    $img.Dispose()
    $i++
  }

  $bitmap.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
}

$rootPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
$sourceIcons = Join-Path $rootPath "assets"
$streamRoot = Join-Path $rootPath "stream-assets"
$iconOut = Join-Path $streamRoot "icons"
$bannerOut = Join-Path $streamRoot "banners"
New-Dir $iconOut
New-Dir $bannerOut

Get-ChildItem -LiteralPath $sourceIcons -Recurse -Filter *.png -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 0 } | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $iconOut $_.Name) -Force
}

$icons = Get-ChildItem -LiteralPath $iconOut -Filter *.png -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -gt 1024 } |
  Select-Object -ExpandProperty FullName

Draw-Banner (Join-Path $bannerOut "cursed-walking-live-1920x1080.png") 1920 1080 "Cursed Walking MOD Live" "Zombies, armas y acciones del chat en vivo." $icons
Draw-Banner (Join-Path $bannerOut "cursed-walking-live-1920x640.png") 1920 640 "Cursed Walking MOD Live" "Modpack conectado a TikTok Live Games." $icons
Draw-Banner (Join-Path $bannerOut "cursed-walking-live-1200x630.png") 1200 630 "Cursed Walking MOD Live" "Stream to Earn ready assets." $icons
Draw-Banner (Join-Path $bannerOut "cursed-walking-live-1280x720.png") 1280 720 "Cursed Walking MOD Live" "Acciones, hordas y armas para el directo." $icons

@"
# Stream Assets

Carpeta para overlays, banners y catalogo externo.

- `icons/`: iconos PNG de acciones. La mayoria son 192x192; sirven para botones y tarjetas chicas.
- `banners/`: banners PNG grandes generados para stream/catalogo.

Tamanos recomendados:

- 1920x1080: pantalla completa o preview grande.
- 1920x640: banner ancho.
- 1280x720: miniatura/video.
- 1200x630: card social/catalogo.

No estires iconos de 192x192 como banner completo; usalos dentro de un banner grande.
"@ | Set-Content -LiteralPath (Join-Path $streamRoot "README.md") -Encoding UTF8

Write-Host "Stream assets generados en: $streamRoot"
