#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Downloads NuGet RC artifacts from GitHub Packages

.PARAMETER RcVersion
    The RC version to download

.PARAMETER GitHubUsername
    GitHub username for authentication

.PARAMETER GitHubToken
    GitHub token for authentication

.PARAMETER Repository
    GitHub repository (owner/repo)

.PARAMETER PackageName
    NuGet package name (default: Optivem.Testing)

.EXAMPLE
    .\download-nuget-rc-artifacts.ps1 -RcVersion "2026.02.05-rc.47" -GitHubUsername "user" -GitHubToken $token -Repository "optivem/optivem-testing-dotnet"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RcVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$true)]
    [string]$Repository,
    
    [Parameter(Mandatory=$false)]
    [string]$PackageName = "Optivem.Testing"
)

Write-Host "📥 Downloading NuGet RC package from GitHub Packages..." -ForegroundColor Blue
Write-Host "   Package: $PackageName" -ForegroundColor Gray
Write-Host "   Version: $RcVersion" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray

New-Item -ItemType Directory -Path "temp-artifacts" -Force | Out-Null

# Extract owner from repository
$owner = $Repository.Split('/')[0]

# Configure NuGet source for GitHub Packages
$sourceName = "github-temp"
Write-Host "🔧 Configuring temporary NuGet source..." -ForegroundColor Yellow

# Remove source if it already exists
dotnet nuget remove source $sourceName 2>$null | Out-Null

# Add GitHub Packages as NuGet source
dotnet nuget add source "https://nuget.pkg.github.com/$owner/index.json" `
    --name $sourceName `
    --username $GitHubUsername `
    --password $GitHubToken `
    --store-password-in-clear-text | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to configure NuGet source" -ForegroundColor Red
    exit 1
}

Write-Host "✅ NuGet source configured" -ForegroundColor Green

# Download the package
$packageFileName = "$PackageName.$RcVersion.nupkg"
$outputPath = "temp-artifacts\$packageFileName"

Write-Host "" -ForegroundColor Gray
Write-Host "⬇️  Downloading $packageFileName..." -ForegroundColor Yellow

$maxRetries = 3
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        # Create temporary project to download package
        $tempDir = "temp-artifacts/temp-project"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        # Create minimal .csproj
        @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
"@ | Set-Content "$tempDir/temp.csproj"
        
        # Create nuget.config that references the GitHub Packages source
        @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="github" value="https://nuget.pkg.github.com/$owner/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <github>
      <add key="Username" value="$GitHubUsername" />
      <add key="ClearTextPassword" value="$GitHubToken" />
    </github>
  </packageSourceCredentials>
</configuration>
"@ | Set-Content "$tempDir/nuget.config"
        
        # Download package using dotnet add
        Push-Location $tempDir
        $downloadOutput = dotnet add package $PackageName --version $RcVersion --package-directory ../packages 2>&1
        Pop-Location
        
        Write-Host "   Download command output:" -ForegroundColor Gray
        Write-Host "   $downloadOutput" -ForegroundColor Gray
        
        # NuGet downloads to: packages/{package-lowercase}/{version}/{package-lowercase}.{version}.nupkg
        $packageNameLower = $PackageName.ToLower()
        $nupkgPath = "temp-artifacts/packages/$packageNameLower/$RcVersion/$packageNameLower.$RcVersion.nupkg"
        
        Write-Host "   Looking for package at: $nupkgPath" -ForegroundColor Gray
        
        if (Test-Path $nupkgPath) {
            # Copy to output location
            Copy-Item -Path $nupkgPath -Destination $outputPath -Force
            Write-Host "✅ Downloaded $packageFileName" -ForegroundColor Green
            $success = $true
            
            # Clean up temp directories
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "temp-artifacts/packages" -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "   ❌ Package not found at expected path" -ForegroundColor Yellow
            Write-Host "   Searching for .nupkg files in temp-artifacts..." -ForegroundColor Yellow
            $allFiles = Get-ChildItem -Path "temp-artifacts" -Recurse -ErrorAction SilentlyContinue
            if ($allFiles) {
                Write-Host "   Files found:" -ForegroundColor Gray
                foreach ($file in $allFiles) {
                    Write-Host "     $($file.FullName)" -ForegroundColor Gray
                }
            } else {
                Write-Host "   No files found in temp-artifacts" -ForegroundColor Red
            }
            throw "Package not found at expected path: $nupkgPath"
        }
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "⚠️  Attempt $retryCount failed, retrying in 5 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        } else {
            Write-Host "❌ Failed to download package after $maxRetries attempts: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "💡 Ensure the RC package is published to GitHub Packages" -ForegroundColor Cyan
            
            # Cleanup
            dotnet nuget remove source $sourceName 2>$null | Out-Null
            exit 1
        }
    }
}

# Cleanup temporary source
Write-Host "" -ForegroundColor Gray
Write-Host "🧹 Cleaning up temporary NuGet source..." -ForegroundColor Yellow
dotnet nuget remove source $sourceName 2>$null | Out-Null

Write-Host "" -ForegroundColor Gray
Write-Host "✅ NuGet package downloaded successfully" -ForegroundColor Green
Write-Host "   Location: $outputPath" -ForegroundColor Gray