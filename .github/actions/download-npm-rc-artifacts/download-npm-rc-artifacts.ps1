#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Downloads npm RC artifacts from GitHub Packages

.PARAMETER RcVersion
    The RC version to download

.PARAMETER PackageName
    npm package name without scope (default: optivem-testing)

.EXAMPLE
    .\download-npm-rc-artifacts.ps1 -RcVersion "1.0.1-rc.47"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RcVersion,

    [Parameter(Mandatory=$false)]
    [string]$PackageName = "optivem-testing"
)

Write-Host "📥 Downloading npm RC package from GitHub Packages..." -ForegroundColor Blue
Write-Host "   Package: @optivem/$PackageName" -ForegroundColor Gray
Write-Host "   Version: $RcVersion" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray

$artifactsDir = "/tmp/rc-artifacts"
New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null

# Write npmrc with GitHub Packages auth
$npmrcPath = "$artifactsDir/.npmrc"
@"
@optivem:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=$($env:GITHUB_TOKEN)
"@ | Set-Content $npmrcPath

Push-Location $artifactsDir
try {
    npm pack "@optivem/$PackageName@$RcVersion" --userconfig $npmrcPath

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to download package" -ForegroundColor Red
        exit 1
    }

    Write-Host "" -ForegroundColor Gray
    Write-Host "✅ RC package downloaded successfully" -ForegroundColor Green
    Write-Host "   Location: $artifactsDir" -ForegroundColor Gray
    Get-ChildItem $artifactsDir -Filter "*.tgz" | Format-Table Name, Length -AutoSize
} finally {
    Pop-Location
}
