param(
    [string]$ThemeName = "haifengchui2",
    [string]$SrcDir = ""
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($SrcDir)) {
    $SrcDir = (Resolve-Path (Join-Path $scriptDir "..\src")).Path
}
$OutDir = (Resolve-Path (Join-Path $scriptDir "..\release") -ErrorAction SilentlyContinue).Path
if (-not $OutDir) {
    $OutDir = Join-Path $scriptDir "..\release"
}

$ErrorActionPreference = "Stop"

function Pack-UnpackedToBlob {
    param(
        [string]$UnpackedDir,
        [string]$BlobPath
    )
    if (-not (Test-Path $UnpackedDir)) {
        Write-Warning "Skip blob (no unpacked dir): $UnpackedDir"
        return
    }
    $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) ("oppo_blob_" + [guid]::NewGuid().ToString() + ".zip")
    try {
        if (Test-Path $BlobPath) {
            Remove-Item -LiteralPath $BlobPath -Force
        }
        Compress-Archive -Path (Join-Path $UnpackedDir "*") -DestinationPath $tempZip -Force
        Move-Item -LiteralPath $tempZip -Destination $BlobPath -Force
        Write-Host "Blob: $BlobPath"
    } finally {
        if (Test-Path $tempZip) {
            Remove-Item -LiteralPath $tempZip -Force
        }
    }
}

if (-not (Test-Path $SrcDir)) {
    Write-Error "Source directory not found: $SrcDir"
}

Pack-UnpackedToBlob (Join-Path $SrcDir "wallpaper_unpacked") (Join-Path $SrcDir "wallpaper")
Pack-UnpackedToBlob (Join-Path $SrcDir "com.android.systemui_unpacked") (Join-Path $SrcDir "com.android.systemui")
Pack-UnpackedToBlob (Join-Path $SrcDir "framework-res_unpacked") (Join-Path $SrcDir "framework-res")

$entries = @(
    (Join-Path $SrcDir "themeInfo.xml"),
    (Join-Path $SrcDir "wallpaper"),
    (Join-Path $SrcDir "com.android.systemui"),
    (Join-Path $SrcDir "framework-res")
) | Where-Object { Test-Path $_ }

if ($entries.Count -eq 0) {
    Write-Error "No theme inputs in src/. Need themeInfo.xml and *_unpacked/ folders."
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$outFile = Join-Path $OutDir ($ThemeName + ".theme")
$tempZip = Join-Path ([System.IO.Path]::GetTempPath()) ("oppo_theme_pack_" + [guid]::NewGuid().ToString() + ".zip")

try {
    if (Test-Path $outFile) {
        Remove-Item -LiteralPath $outFile -Force
    }

    Compress-Archive -Path $entries -DestinationPath $tempZip -Force
    Move-Item -LiteralPath $tempZip -Destination $outFile -Force
    Write-Host "Packed: $outFile"
} finally {
    if (Test-Path $tempZip) {
        Remove-Item -LiteralPath $tempZip -Force
    }
}
