#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Finds the latest NuGet RC version from GitHub Packages if no version is provided

.PARAMETER RcVersion
    RC version to use (optional - if empty, will find latest)

.PARAMETER GitHubToken
    GitHub token for API access

.PARAMETER Repository
    GitHub repository (owner/repo)

.PARAMETER PackageName
    NuGet package name in GitHub Packages

.EXAMPLE
    .\find-latest-nuget-rc-version.ps1 -GitHubToken $token -Repository "optivem/optivem-testing-dotnet" -PackageName "Optivem.Testing"
    .\find-latest-nuget-rc-version.ps1 -RcVersion "1.0.5-rc.47" -GitHubToken $token -Repository "optivem/optivem-testing-dotnet" -PackageName "Optivem.Testing"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$RcVersion = "",
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$true)]
    [string]$Repository,
    
    [Parameter(Mandatory=$false)]
    [string]$PackageName = "Optivem.Testing"
)

if ([string]::IsNullOrWhiteSpace($RcVersion)) {
    Write-Host "🔍 No RC version provided, finding latest RC version from GitHub Packages..." -ForegroundColor Blue
    Write-Host "   Package: $PackageName" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Gray
    
    # Extract owner from repository (owner/repo format)
    $owner = $Repository.Split('/')[0]
    
    # Call GitHub API to get latest RC version for NuGet packages
    $headers = @{
        "Authorization" = "Bearer $GitHubToken"
        "Accept" = "application/vnd.github+json"
    }
    
    # Use NuGet package type endpoint
    # Try org endpoint first, fall back to user endpoint if needed
    $apiUrl = "https://api.github.com/orgs/$owner/packages/nuget/$PackageName/versions"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
    } catch {
        # If org endpoint fails, try user endpoint
        Write-Host "   Trying user packages endpoint..." -ForegroundColor Gray
        $apiUrl = "https://api.github.com/users/$owner/packages/nuget/$PackageName/versions"
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        } catch {
            Write-Host "❌ Failed to access GitHub Packages API: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "💡 Ensure the package exists and your token has 'read:packages' permission" -ForegroundColor Cyan
            exit 1
        }
    }
    
    # Filter for RC versions and sort by creation date
    $rcVersions = $response | Where-Object { $_.name -like "*-rc.*" } | Sort-Object { [datetime]$_.created_at } -Descending
    
    if ($rcVersions.Count -eq 0) {
        Write-Host "❌ No RC versions found in GitHub Packages for $PackageName" -ForegroundColor Red
        Write-Host "💡 Ensure RC packages have been published to GitHub Packages" -ForegroundColor Cyan
        exit 1
    }
    
    $latestRc = $rcVersions[0].name
    Write-Host "✅ Found latest RC version: $latestRc" -ForegroundColor Green
    "rc-version=$latestRc" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
} else {
    Write-Host "📋 Using provided RC version: $RcVersion" -ForegroundColor Green
    "rc-version=$RcVersion" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
}