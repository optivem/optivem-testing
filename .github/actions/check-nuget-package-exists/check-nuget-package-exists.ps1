#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Checks if a release version already exists on NuGet.org.

.PARAMETER ReleaseVersion
    The release version to check.

.PARAMETER PackageName
    Package name on NuGet.org.

.EXAMPLE
    .\check-nuget-exists.ps1 -ReleaseVersion "2026.02.05" -PackageName "Optivem.Testing"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ReleaseVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$PackageName = "Optivem.Testing"
)

Write-Host "🔍 Checking if version $ReleaseVersion exists on NuGet.org..." -ForegroundColor Cyan

try {
    $packageNameLower = $PackageName.ToLower()
    $response = Invoke-RestMethod -Uri "https://api.nuget.org/v3-flatcontainer/$packageNameLower/index.json"
    
    $exists = $response.versions | Where-Object { $_ -eq $ReleaseVersion }
    
    if ($exists) {
        Write-Host "❌ Version $ReleaseVersion already exists on NuGet.org" -ForegroundColor Red
        Write-Host "Please choose a different version or delete the existing release." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Version $ReleaseVersion does not exist on NuGet.org" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Could not verify NuGet.org (package may not exist yet): $_" -ForegroundColor Yellow
    Write-Host "Continuing anyway..." -ForegroundColor Yellow
}
