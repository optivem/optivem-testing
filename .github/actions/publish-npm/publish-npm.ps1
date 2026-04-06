#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Publishes an npm package to npm.org

.PARAMETER PackagePath
    Path to the .tgz file to publish

.EXAMPLE
    .\publish-npm.ps1 -PackagePath "/tmp/rc-artifacts/optivem-optivem-testing-1.0.1.tgz"
#>

# TODO: Long-term, switch to npm Trusted Publishing (OIDC) instead of NPM_TOKEN:
# 1. Add id-token: write permission to the release job
# 2. Remove the echo _authToken line below
# 3. Add --provenance flag

param(
    [Parameter(Mandatory=$true)]
    [string]$PackagePath
)

Write-Host "📤 Publishing npm package to npm.org..." -ForegroundColor Blue
Write-Host "   Package: $PackagePath" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray

if (-not (Test-Path $PackagePath)) {
    Write-Host "❌ Package file not found: $PackagePath" -ForegroundColor Red
    exit 1
}

$packageFile = Get-Item $PackagePath
Write-Host "✅ Package file found" -ForegroundColor Green
Write-Host "   Size: $([math]::Round($packageFile.Length / 1KB, 2)) KB" -ForegroundColor Gray

if ([string]::IsNullOrWhiteSpace($env:NPM_TOKEN)) {
    Write-Host "❌ NPM_TOKEN environment variable is not set" -ForegroundColor Red
    Write-Host "💡 Set NPM_TOKEN secret in your repository" -ForegroundColor Cyan
    exit 1
}

# Write npmrc for npm.org auth
$npmrcPath = "/tmp/release.npmrc"
@"
registry=https://registry.npmjs.org/
//registry.npmjs.org/:_authToken=$($env:NPM_TOKEN)
"@ | Set-Content $npmrcPath

Write-Host "" -ForegroundColor Gray
Write-Host "🚀 Publishing to npm.org..." -ForegroundColor Blue

npm publish $PackagePath --access public --userconfig $npmrcPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "" -ForegroundColor Gray
    Write-Host "❌ Failed to publish package" -ForegroundColor Red
    exit 1
}

Write-Host "" -ForegroundColor Gray
Write-Host "✅ Package published successfully!" -ForegroundColor Green
