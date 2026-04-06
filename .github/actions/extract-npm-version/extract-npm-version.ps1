#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Extracts version from package.json

.DESCRIPTION
    Reads the version property from package.json and outputs it as a GitHub Actions output

.EXAMPLE
    .\extract-npm-version.ps1
#>

Write-Host "📦 Extracting version from package.json..." -ForegroundColor Blue

if (-not (Test-Path "package.json")) {
    Write-Host "❌ package.json not found in current directory" -ForegroundColor Red
    exit 1
}

$pkg = Get-Content "package.json" | ConvertFrom-Json
$version = $pkg.version

if ([string]::IsNullOrWhiteSpace($version)) {
    Write-Host "❌ version not found in package.json" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Extracted version: $version" -ForegroundColor Green

"version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
