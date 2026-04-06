#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Publishes a NuGet package to NuGet.org

.PARAMETER PackagePath
    Path to the .nupkg file to publish

.PARAMETER NuGetApiKey
    NuGet.org API key for authentication

.PARAMETER Source
    NuGet source URL (default: https://api.nuget.org/v3/index.json)

.EXAMPLE
    .\publish-nuget.ps1 -PackagePath "temp-release\Optivem.Testing.2026.02.05.nupkg" -NuGetApiKey $apiKey
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PackagePath,
    
    [Parameter(Mandatory=$true)]
    [string]$NuGetApiKey,
    
    [Parameter(Mandatory=$false)]
    [string]$Source = "https://api.nuget.org/v3/index.json"
)

Write-Host "📤 Publishing NuGet package to NuGet.org..." -ForegroundColor Blue
Write-Host "   Package: $PackagePath" -ForegroundColor Gray
Write-Host "   Source: $Source" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray

# Verify package file exists
if (-not (Test-Path $PackagePath)) {
    Write-Host "❌ Package file not found: $PackagePath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Package file found" -ForegroundColor Green
$packageFile = Get-Item $PackagePath
Write-Host "   Size: $([math]::Round($packageFile.Length / 1KB, 2)) KB" -ForegroundColor Gray

# Verify API key is provided
if ([string]::IsNullOrWhiteSpace($NuGetApiKey)) {
    Write-Host "❌ NuGet API key is required" -ForegroundColor Red
    Write-Host "💡 Set NUGET_API_KEY secret in your repository" -ForegroundColor Cyan
    exit 1
}

Write-Host "" -ForegroundColor Gray
Write-Host "🚀 Publishing to NuGet.org..." -ForegroundColor Blue

try {
    # Publish using dotnet nuget push
    dotnet nuget push $PackagePath `
        --api-key $NuGetApiKey `
        --source $Source `
        --skip-duplicate
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "" -ForegroundColor Gray
        Write-Host "❌ Failed to publish package" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "" -ForegroundColor Gray
    Write-Host "✅ Package published successfully!" -ForegroundColor Green
    
    # Extract package name and version from path
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($PackagePath)
    $parts = $fileName -split '\.'
    
    if ($parts.Count -ge 2) {
        # Try to extract package name and version
        # Format: PackageName.Version.nupkg
        $version = $parts[-1]
        $packageName = ($parts[0..($parts.Count - 2)] -join '.')
        
        Write-Host "" -ForegroundColor Gray
        Write-Host "📦 Package Details:" -ForegroundColor Cyan
        Write-Host "   Name: $packageName" -ForegroundColor Gray
        Write-Host "   Version: $version" -ForegroundColor Gray
        Write-Host "" -ForegroundColor Gray
        Write-Host "🔗 NuGet.org URL:" -ForegroundColor Cyan
        Write-Host "   https://www.nuget.org/packages/$packageName/$version" -ForegroundColor White
    }
    
    Write-Host "" -ForegroundColor Gray
    Write-Host "⏳ Note: It may take a few minutes for the package to be indexed and searchable" -ForegroundColor Yellow
    
} catch {
    Write-Host "" -ForegroundColor Gray
    Write-Host "❌ Error publishing package: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
