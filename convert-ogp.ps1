# convert-ogp.ps1
# SVG を 1200x630 PNG に変換する簡易スクリプト
# 要件: ローカルに msedge または chrome がインストールされていること

param(
    [string]$SvgPath = "ogp.svg",
    [string]$OutPath = "ogp.png",
    [int]$Width = 1200,
    [int]$Height = 630
)

$svgFull = Resolve-Path $SvgPath -ErrorAction Stop
$outFull = Resolve-Path (Join-Path (Get-Location) $OutPath) -ErrorAction SilentlyContinue
if (-not $outFull) { $outFull = Join-Path (Get-Location) $OutPath }

function Try-Run {
    param($exe, $args)
    try {
        $p = Start-Process -FilePath $exe -ArgumentList $args -NoNewWindow -PassThru -Wait -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

$url = "file:///" + ($svgFull.Path -replace '\\','/')

# Try Edge (msedge)
$edgeCmd = "--headless --disable-gpu --screenshot='$outFull' --window-size=$Width,$Height `"$url`""
if (Get-Command msedge -ErrorAction SilentlyContinue) {
    Write-Host "Using msedge to render PNG..."
    $ok = Try-Run msedge $edgeCmd
    if ($ok) { Write-Host "Created: $outFull"; exit 0 }
}

# Try Chrome (chrome)
$chromeCmd = "--headless --disable-gpu --screenshot='$outFull' --window-size=$Width,$Height `"$url`""
if (Get-Command chrome -ErrorAction SilentlyContinue) {
    Write-Host "Using chrome to render PNG..."
    $ok = Try-Run chrome $chromeCmd
    if ($ok) { Write-Host "Created: $outFull"; exit 0 }
}

Write-Host "Unable to find msedge or chrome in PATH, or rendering failed."
Write-Host "Alternative: install ImageMagick and run: magick convert -size ${Width}x${Height} $SvgPath -background none -resize ${Width}x${Height} $OutPath"
exit 1
