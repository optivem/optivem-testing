#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check if package is available on npm registry
.DESCRIPTION
    Returns exit code 0 if package version exists on registry.npmjs.org, non-zero otherwise
.PARAMETER Version
    The version to check
.PARAMETER PackageName
    npm package name (default: @optivem/optivem-testing)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$PackageName
)

# Validate inputs
if ([string]::IsNullOrWhiteSpace($Version) -or [string]::IsNullOrWhiteSpace($PackageName)) {
    Write-Host "   ❌ Invalid parameters: Version and PackageName are required" -ForegroundColor Red
    exit 1  # Permanent failure - invalid input
}

try {
    $result = npm view "${PackageName}@${Version}" version --registry "https://registry.npmjs.org/" 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $result -match $Version) {
        Write-Host "   ✅ Package available on npm" -ForegroundColor Green
        exit 0  # Success
    }
    
    Write-Host "   ⏳ Not yet available" -ForegroundColor Gray
    exit 2  # Transient failure - retry
    
} catch {
    Write-Host "   ⏳ Not yet available ($_)" -ForegroundColor Gray
    exit 2  # Transient failure - retry
}
