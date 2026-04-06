#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Prepares NuGet release artifacts by repacking RC package with release version

.PARAMETER RcVersion
    The RC version to rename from

.PARAMETER ReleaseVersion
    The release version to rename to

.PARAMETER PackageName
    The NuGet package name (default: Optivem.Testing)

.EXAMPLE
    .\prepare-nuget-release-artifacts.ps1 -RcVersion "2026.02.05-rc.47" -ReleaseVersion "2026.02.05"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RcVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$PackageName = "Optivem.Testing"
)

Write-Host "📦 Preparing NuGet release artifacts..." -ForegroundColor Blue
Write-Host "   RC Version: $RcVersion" -ForegroundColor Gray
Write-Host "   Release Version: $ReleaseVersion" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray

# Verify downloaded artifacts exist
Write-Host "🔍 Verifying downloaded artifacts..." -ForegroundColor Yellow
if (-not (Test-Path "temp-artifacts")) {
    Write-Host "❌ temp-artifacts directory not found!" -ForegroundColor Red
    exit 1
}

$rcPackageFile = "$PackageName.$RcVersion.nupkg"
$rcPackagePath = "temp-artifacts\$rcPackageFile"

if (-not (Test-Path $rcPackagePath)) {
    Write-Host "❌ RC package not found: $rcPackageFile" -ForegroundColor Red
    Write-Host "   Expected path: $rcPackagePath" -ForegroundColor Red
    Write-Host "   Available files:" -ForegroundColor Yellow
    Get-ChildItem temp-artifacts/ | Format-Table -AutoSize
    exit 1
}

Write-Host "✅ RC package found: $rcPackageFile" -ForegroundColor Green

# Create directories for extraction and output
Write-Host "" -ForegroundColor Gray
Write-Host "📂 Creating directories..." -ForegroundColor Yellow
$extractDir = "temp-release\extracted"
$outputDir = "temp-release"
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

# Extract the .nupkg (it's just a zip file)
Write-Host "📦 Extracting RC package..." -ForegroundColor Yellow
Expand-Archive -Path $rcPackagePath -DestinationPath $extractDir -Force

# Find and update .nuspec file
Write-Host "✏️  Updating version in .nuspec..." -ForegroundColor Yellow
$nuspecFile = Get-ChildItem -Path $extractDir -Filter "*.nuspec" | Select-Object -First 1

if (-not $nuspecFile) {
    Write-Host "❌ .nuspec file not found in package" -ForegroundColor Red
    exit 1
}

Write-Host "   Found .nuspec: $($nuspecFile.Name)" -ForegroundColor Gray

# Update version in .nuspec
$nuspecPath = $nuspecFile.FullName
$nuspecContent = Get-Content $nuspecPath -Raw
$nuspecContent = $nuspecContent -replace "<version>$([regex]::Escape($RcVersion))</version>", "<version>$ReleaseVersion</version>"
Set-Content -Path $nuspecPath -Value $nuspecContent

Write-Host "   Updated version: $RcVersion → $ReleaseVersion" -ForegroundColor Gray

# Repack as .nupkg
Write-Host "" -ForegroundColor Gray
Write-Host "📦 Repacking as release package..." -ForegroundColor Yellow
$releasePackageFile = "$PackageName.$ReleaseVersion.nupkg"
$releasePackagePath = "$outputDir\$releasePackageFile"

# Create zip (rename as .nupkg)
Compress-Archive -Path "$extractDir\*" -DestinationPath "$outputDir\temp.zip" -Force
Move-Item -Path "$outputDir\temp.zip" -Destination $releasePackagePath -Force

Write-Host "" -ForegroundColor Gray
Write-Host "✅ Release package prepared" -ForegroundColor Green
Write-Host "   Location: $releasePackagePath" -ForegroundColor Gray
Get-ChildItem $releasePackagePath | Format-Table -AutoSize