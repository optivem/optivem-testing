#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Prepares npm release artifacts by repacking RC package with release version

.PARAMETER RcVersion
    The RC version to rename from

.PARAMETER ReleaseVersion
    The release version to rename to

.PARAMETER PackageName
    npm package name without scope (default: optivem-testing)

.EXAMPLE
    .\prepare-npm-release-artifacts.ps1 -RcVersion "1.0.1-rc.47" -ReleaseVersion "1.0.1"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RcVersion,

    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,

    [Parameter(Mandatory=$false)]
    [string]$PackageName = "optivem-testing"
)

Write-Host "📦 Preparing npm release artifacts..." -ForegroundColor Blue
Write-Host "   RC Version:      $RcVersion" -ForegroundColor Gray
Write-Host "   Release Version: $ReleaseVersion" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray

$artifactsDir = "/tmp/rc-artifacts"

# Find the RC tgz - npm pack names it optivem-{name}-{version}.tgz
$rcTgz = Get-ChildItem -Path $artifactsDir -Filter "optivem-$PackageName-*.tgz" | Select-Object -First 1

if (-not $rcTgz) {
    Write-Host "❌ RC tgz not found in $artifactsDir" -ForegroundColor Red
    Write-Host "   Available files:" -ForegroundColor Yellow
    Get-ChildItem $artifactsDir | Format-Table -AutoSize
    exit 1
}

Write-Host "✅ Found RC package: $($rcTgz.Name)" -ForegroundColor Green

Push-Location $artifactsDir
try {
    # Extract tgz (npm pack produces a package/ folder inside)
    Write-Host "📂 Extracting RC package..." -ForegroundColor Yellow
    tar -xzf $rcTgz.Name

    # Update version in package/package.json
    Write-Host "✏️  Updating version in package.json..." -ForegroundColor Yellow
    $pkgJsonPath = "package/package.json"

    if (-not (Test-Path $pkgJsonPath)) {
        Write-Host "❌ package/package.json not found after extraction" -ForegroundColor Red
        exit 1
    }

    $pkg = Get-Content $pkgJsonPath | ConvertFrom-Json
    $pkg.version = $ReleaseVersion
    $pkg | ConvertTo-Json -Depth 10 | Set-Content $pkgJsonPath

    Write-Host "   Updated version: $RcVersion → $ReleaseVersion" -ForegroundColor Gray

    # Repack
    Write-Host "" -ForegroundColor Gray
    Write-Host "📦 Repacking as release package..." -ForegroundColor Yellow
    $releaseTgz = "optivem-$PackageName-$ReleaseVersion.tgz"
    tar -czf $releaseTgz package/

    Write-Host "" -ForegroundColor Gray
    Write-Host "✅ Release artifact prepared" -ForegroundColor Green
    Write-Host "   Location: $artifactsDir/$releaseTgz" -ForegroundColor Gray
    Get-ChildItem $artifactsDir -Filter $releaseTgz | Format-Table Name, Length -AutoSize
} finally {
    Pop-Location
}
