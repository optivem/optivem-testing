#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deprecates and unlists all versions of a NuGet package

.DESCRIPTION
    This script:
    1. Unlists all versions (using dotnet nuget delete)
    2. Deprecates all versions (using nuget CLI)

.PARAMETER PackageId
    The NuGet package ID to deprecate

.PARAMETER ApiKey
    NuGet.org API key (if not provided, will look for NUGET_API_KEY env var)

.PARAMETER DeprecationMessage
    Message to show users (optional)

.EXAMPLE
    .\Deprecate-Package.ps1 -PackageId "Optivem.Framework.Core.Common" -ApiKey "your-key"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PackageId,
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = $env:NUGET_API_KEY,
    
    [Parameter(Mandatory=$false)]
    [string]$DeprecationMessage = "This package is deprecated and no longer maintained."
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "❌ API key not provided. Set NUGET_API_KEY environment variable or pass -ApiKey parameter" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Fetching versions for $PackageId..." -ForegroundColor Cyan

try {
    $packageIdLower = $PackageId.ToLower()
    $response = Invoke-RestMethod -Uri "https://api.nuget.org/v3-flatcontainer/$packageIdLower/index.json"
    $versions = $response.versions
    
    Write-Host "📦 Found $($versions.Count) versions: $($versions -join ', ')" -ForegroundColor Yellow
    
    # Unlist all versions
    Write-Host "`n🚫 Unlisting all versions..." -ForegroundColor Cyan
    $versionIndex = 0
    foreach ($version in $versions) {
        $versionIndex++
        Write-Host "  [$versionIndex/$($versions.Count)] Unlisting $version..." -ForegroundColor Gray
        
        $retryCount = 0
        $maxRetries = 3
        $success = $false
        
        while (-not $success -and $retryCount -lt $maxRetries) {
            dotnet nuget delete $PackageId $version `
                --source https://api.nuget.org/v3/index.json `
                --api-key $ApiKey `
                --non-interactive 2>&1 | Out-String -OutVariable output | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Unlisted $version" -ForegroundColor Green
                $success = $true
            } elseif ($output -like "*403*" -or $output -like "*Quota*") {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    $waitTime = [Math]::Pow(2, $retryCount) * 30  # Exponential backoff: 60s, 120s, 240s
                    Write-Host "  ⏳ Rate limit hit. Waiting $waitTime seconds before retry $retryCount/$maxRetries..." -ForegroundColor Yellow
                    Start-Sleep -Seconds $waitTime
                } else {
                    Write-Host "  ❌ Rate limit exceeded after $maxRetries retries. Skipping remaining versions." -ForegroundColor Red
                    Write-Host "  💡 Wait 1 hour and run script again to continue." -ForegroundColor Cyan
                    throw "Rate limit exceeded"
                }
            } else {
                Write-Host "  ⚠ Failed to unlist $version (may already be unlisted)" -ForegroundColor Yellow
                $success = $true  # Continue to next version
            }
        }
        
        # Delay between versions to avoid rate limiting (only if not last version)
        if ($versionIndex -lt $versions.Count) {
            Start-Sleep -Seconds 3
        }
    }
    
    # Check if nuget.exe is available for deprecation
    Write-Host "`n⚠️ Deprecating packages..." -ForegroundColor Cyan
    $nugetPath = Get-Command nuget -ErrorAction SilentlyContinue
    
    if ($null -eq $nugetPath) {
        Write-Host "⚠️ nuget.exe not found. Installing NuGet CLI..." -ForegroundColor Yellow
        dotnet tool install -g NuGet.CommandLine
        $nugetPath = Get-Command nuget -ErrorAction SilentlyContinue
    }
    
    if ($null -ne $nugetPath) {
        # Deprecate using version range (all versions)
        Write-Host "  Deprecating all versions with message: '$DeprecationMessage'" -ForegroundColor Gray
        
        # NuGet CLI deprecate command syntax:
        # nuget deprecate <package-id> <version-range> -Source <source> -ApiKey <key> -Message <message>
        
        $minVersion = $versions[0]
        $maxVersion = $versions[-1]
        $versionRange = "[$minVersion,$maxVersion]"
        
        nuget deprecate $PackageId $versionRange `
            -Source https://api.nuget.org/v3/index.json `
            -ApiKey $ApiKey `
            -Message $DeprecationMessage
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Deprecated all versions" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Deprecation may have failed (check NuGet.org manually)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️ Could not install nuget.exe. You'll need to deprecate manually on NuGet.org:" -ForegroundColor Yellow
        Write-Host "   https://www.nuget.org/packages/$PackageId/manage" -ForegroundColor Cyan
    }
    
    Write-Host "`n✅ Package processing complete!" -ForegroundColor Green
    Write-Host "📝 Verify changes at: https://www.nuget.org/packages/$PackageId" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
