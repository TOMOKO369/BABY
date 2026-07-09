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

function Find-Executable {
    param(
        [string[]]$Names,
        [string[]]$FallbackPaths
    )

    foreach ($name in $Names) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }

    foreach ($path in $FallbackPaths) {
        if (Test-Path $path) { return (Resolve-Path $path).Path }
    }

    return $null
}

$url = "file:///" + ($svgFull.Path -replace '\\','/')

$edgePath = Find-Executable -Names @('msedge') -FallbackPaths @(
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
)
$chromePath = Find-Executable -Names @('chrome') -FallbackPaths @(
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
)

$renderArgs = @(
    '--headless',
    '--disable-gpu',
    "--screenshot=$outFull",
    "--window-size=$Width,$Height",
    $url
)

if ($edgePath) {
    Write-Host "Using msedge to render PNG..."
    $ok = Try-Run $edgePath $renderArgs
    if ($ok) { Write-Host "Created: $outFull"; exit 0 }
}

if ($chromePath) {
    Write-Host "Using chrome to render PNG..."
    $ok = Try-Run $chromePath $renderArgs
    if ($ok) { Write-Host "Created: $outFull"; exit 0 }
}

Write-Host "Unable to find msedge or chrome in PATH, or rendering failed."
Write-Host "Alternative: install ImageMagick and run: magick convert -size ${Width}x${Height} $SvgPath -background none -resize ${Width}x${Height} $OutPath"
exit 1
