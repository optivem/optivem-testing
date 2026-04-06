#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Extracts version from Directory.Build.props for .NET projects

.DESCRIPTION
    Reads the VersionPrefix property from Directory.Build.props and outputs it as a GitHub Actions output

.EXAMPLE
    .\extract-dotnet-version.ps1
#>

Write-Host "📦 Extracting version from Directory.Build.props..." -ForegroundColor Blue

# Check if Directory.Build.props exists
if (-not (Test-Path "Directory.Build.props")) {
    Write-Host "❌ Directory.Build.props not found in current directory" -ForegroundColor Red
    exit 1
}

# Parse XML and extract VersionPrefix
[xml]$props = Get-Content "Directory.Build.props"
$VERSION = $props.Project.PropertyGroup.VersionPrefix

if ([string]::IsNullOrWhiteSpace($VERSION)) {
    Write-Host "❌ VersionPrefix not found in Directory.Build.props" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Extracted base version: $VERSION" -ForegroundColor Green

# Output for GitHub Actions
if ($env:GITHUB_OUTPUT) {
    "version=$VERSION" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
} else {
    # Local testing output
    Write-Host "Base version: $VERSION"
}
