#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Checks if a package version is available on NuGet.org.

.PARAMETER PackageName
    The NuGet package name.

.PARAMETER Version
    The package version to check.

.EXAMPLE
    .\check-nuget-available.ps1 "Optivem.Testing" "2026.02.05"

.NOTES
    Exit code 0 = Package is available (condition met)
    Exit code 2 = Package not available yet (keep polling)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PackageName,
    
    [Parameter(Mandatory=$true)]
    [string]$Version
)

try {
    $packageNameLower = $PackageName.ToLower()
    $response = Invoke-RestMethod -Uri "https://api.nuget.org/v3-flatcontainer/$packageNameLower/index.json" -ErrorAction Stop
    
    $exists = $response.versions | Where-Object { $_ -eq $Version }
    
    if ($exists) {
        Write-Host "✅ Package $PackageName version $Version is now available on NuGet.org" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "⏳ Package not yet indexed on NuGet.org..." -ForegroundColor Yellow
        exit 2
    }
}
catch {
    Write-Host "⏳ Package not yet available on NuGet.org (may not exist or still indexing)..." -ForegroundColor Yellow
    exit 2
}
