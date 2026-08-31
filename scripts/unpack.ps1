param(
    [Parameter(Mandatory = $true)]
    [string]$ThemeFile,

    [string]$OutDir = ""
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $scriptDir "..\src"
}

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ThemeFile)) {
    Write-Error "Theme file not found: $ThemeFile"
}

$resolved = Resolve-Path $ThemeFile
$tempZip = Join-Path ([System.IO.Path]::GetTempPath()) ("oppo_theme_" + [guid]::NewGuid().ToString() + ".zip")

try {
    Copy-Item -LiteralPath $resolved -Destination $tempZip -Force

    if (Test-Path $OutDir) {
        Get-ChildItem -LiteralPath $OutDir -Force | Remove-Item -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    }

    Expand-Archive -LiteralPath $tempZip -DestinationPath $OutDir -Force
    Write-Host "Unpacked to: $OutDir"
} finally {
    if (Test-Path $tempZip) {
        Remove-Item -LiteralPath $tempZip -Force
    }
}
