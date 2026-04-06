# Configure NuGet to authenticate with GitHub Packages
# This script uses GITHUB_USERNAME and GITHUB_READ_PACKAGES_TOKEN environment variables

Write-Host "Configuring NuGet for GitHub Packages..." -ForegroundColor Cyan

# Load environment variables
$username = [System.Environment]::GetEnvironmentVariable('GITHUB_USERNAME','User')
$token = [System.Environment]::GetEnvironmentVariable('GITHUB_READ_PACKAGES_TOKEN','User')

if (-not $username) {
    Write-Host "ERROR: GITHUB_USERNAME environment variable is not set" -ForegroundColor Red
    Write-Host "Set it with: [System.Environment]::SetEnvironmentVariable('GITHUB_USERNAME','your-username','User')" -ForegroundColor Yellow
    exit 1
}

if (-not $token) {
    Write-Host "ERROR: GITHUB_READ_PACKAGES_TOKEN environment variable is not set" -ForegroundColor Red
    Write-Host "Set it with: [System.Environment]::SetEnvironmentVariable('GITHUB_READ_PACKAGES_TOKEN','your-token','User')" -ForegroundColor Yellow
    exit 1
}

Write-Host "Username: $username" -ForegroundColor Green

# Check if source already exists
$sources = dotnet nuget list source
if ($sources -match "github") {
    Write-Host "Removing existing 'github' source..." -ForegroundColor Yellow
    dotnet nuget remove source github
}

# Add GitHub Packages as NuGet source
Write-Host "Adding GitHub Packages source..." -ForegroundColor Cyan
dotnet nuget add source "https://nuget.pkg.github.com/optivem/index.json" `
    --name github `
    --username $username `
    --password $token `
    --store-password-in-clear-text

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ GitHub Packages configured successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now restore packages from GitHub Packages:" -ForegroundColor Cyan
    Write-Host "  dotnet restore SystemTest/Optivem.Testing.SystemTest.SmokeTestRc/" -ForegroundColor White
} else {
    Write-Host "✗ Failed to configure GitHub Packages" -ForegroundColor Red
    exit 1
}
