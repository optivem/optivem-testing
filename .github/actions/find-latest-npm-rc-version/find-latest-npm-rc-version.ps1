#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Finds the latest npm RC version from GitHub Packages if no version is provided

.PARAMETER RcVersion
    RC version to use (optional - if empty, will find latest)

.PARAMETER GitHubToken
    GitHub token for API access

.PARAMETER Repository
    GitHub repository (owner/repo)

.PARAMETER PackageName
    npm package name in GitHub Packages (without scope)

.EXAMPLE
    .\find-latest-npm-rc-version.ps1 -GitHubToken $token -Repository "optivem/optivem-testing-typescript" -PackageName "optivem-testing"
    .\find-latest-npm-rc-version.ps1 -RcVersion "1.0.1-rc.47" -GitHubToken $token -Repository "optivem/optivem-testing-typescript" -PackageName "optivem-testing"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$RcVersion = "",

    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,

    [Parameter(Mandatory=$true)]
    [string]$Repository,

    [Parameter(Mandatory=$false)]
    [string]$PackageName = "optivem-testing"
)

if ([string]::IsNullOrWhiteSpace($RcVersion)) {
    Write-Host "🔍 No RC version provided, finding latest RC version from GitHub Packages..." -ForegroundColor Blue
    Write-Host "   Package: $PackageName" -ForegroundColor Gray
    Write-Host ""

    $owner = $Repository.Split('/')[0]

    $headers = @{
        "Authorization" = "Bearer $GitHubToken"
        "Accept"        = "application/vnd.github+json"
    }

    # Try org endpoint first, fall back to user endpoint
    $apiUrl = "https://api.github.com/orgs/$owner/packages/npm/$PackageName/versions"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
    } catch {
        Write-Host "   Trying user packages endpoint..." -ForegroundColor Gray
        $apiUrl = "https://api.github.com/users/$owner/packages/npm/$PackageName/versions"
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        } catch {
            Write-Host "❌ Failed to access GitHub Packages API: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "💡 Ensure the package exists and your token has 'read:packages' permission" -ForegroundColor Cyan
            exit 1
        }
    }

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
