# Publish StarWorld-OppoTheme to GitHub and create a release with the packed .theme file.
# Prerequisites: gh CLI installed and authenticated (`gh auth login`).

param(
    [string]$Version = "v1.0.0",
    [string]$ThemeName = "haifengchui2",
    [ValidateSet("public", "private")]
    [string]$Visibility = "private",
    [string]$Repo = "StopTheClocks1108/StarWorld-OppoTheme"
)

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$rootDir = (Resolve-Path (Join-Path $scriptDir "..")).Path

function Require-GhAuth {
    $status = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "GitHub CLI is not authenticated. Run: gh auth login" -ForegroundColor Yellow
        exit 1
    }
}

Push-Location $rootDir
try {
    Require-GhAuth

    Write-Host "Packing theme..." -ForegroundColor Cyan
    & (Join-Path $scriptDir "pack.ps1") -ThemeName $ThemeName

    $themeFile = Join-Path $rootDir "release\$ThemeName.theme"
    if (-not (Test-Path $themeFile)) {
        throw "Packed theme not found: $themeFile"
    }

    $remoteUrl = "https://github.com/$Repo.git"
    $hasOrigin = git remote get-url origin 2>$null
    if (-not $hasOrigin) {
        Write-Host "Creating GitHub repo $Repo ($Visibility)..." -ForegroundColor Cyan
        gh repo create $Repo --$Visibility --source=. --remote=origin --description "OPPO ColorOS theme sources for StarWorld"
    } else {
        $currentUrl = git remote get-url origin
        if ($currentUrl -ne $remoteUrl) {
            git remote set-url origin $remoteUrl
        }
    }

    Write-Host "Pushing to origin..." -ForegroundColor Cyan
    git push -u origin HEAD

    $tag = $Version
    if (-not $tag.StartsWith("v")) { $tag = "v$tag" }

    $existingRelease = gh release view $tag --repo $Repo 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Release $tag exists, uploading asset..." -ForegroundColor Cyan
        gh release upload $tag $themeFile --repo $Repo --clobber
    } else {
        Write-Host "Creating release $tag..." -ForegroundColor Cyan
        gh release create $tag $themeFile `
            --repo $Repo `
            --title "海风吹 2.0 ($tag)" `
            --notes "OPPO ColorOS theme for StarWorld. Download the .theme file and apply in OPPO Theme Store, or use StarWorld Settings > Download OPPO Theme."
    }

    $downloadUrl = "https://github.com/$Repo/releases/download/$tag/$ThemeName.theme"
    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
    Write-Host "Download URL (add to StarWorld local.properties):" -ForegroundColor Green
    Write-Host "OPPO_THEME_DOWNLOAD_URL=$downloadUrl"
} finally {
    Pop-Location
}
