#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deprecates and unlists all legacy Optivem packages

.DESCRIPTION
    This script processes all packages starting with:
    - Optivem.Framework
    - Optivem.Atomiv
    
    For each package, it:
    1. Unlists all versions
    2. Attempts to deprecate them
    
.PARAMETER DryRun
    If specified, only lists packages without making changes

.PARAMETER ApiKey
    NuGet.org API key (if not provided, will look for NUGET_API_KEY env var)

.EXAMPLE
    # Preview what will be done
    .\Deprecate-Legacy-Packages.ps1 -DryRun
    
    # Actually run the deprecation
    .\Deprecate-Legacy-Packages.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = $env:NUGET_API_KEY
)

$ErrorActionPreference = "Stop"

# List of packages to deprecate (157 total packages - all legacy Optivem packages)
$packages = @(
    # ATDD Accelerator packages
    "atdd-accelerator",
    "atdd-accelerator-cli",
    
    # Optivem.Atomiv.Core packages
    "Optivem.Atomiv.Core.All",
    "Optivem.Atomiv.Core.Application",
    "Optivem.Atomiv.Core.Application.Interface",
    "Optivem.Atomiv.Core.Common",
    "Optivem.Atomiv.Core.Domain",
    
    # Optivem.Atomiv.DependencyInjection packages
    "Optivem.Atomiv.DependencyInjection.Common",
    "Optivem.Atomiv.DependencyInjection.Core.Application",
    "Optivem.Atomiv.DependencyInjection.Core.Domain",
    "Optivem.Atomiv.DependencyInjection.Infrastructure.AspNetCore",
    "Optivem.Atomiv.DependencyInjection.Infrastructure.AutoMapper",
    "Optivem.Atomiv.DependencyInjection.Infrastructure.EntityFrameworkCore",
    "Optivem.Atomiv.DependencyInjection.Infrastructure.FluentValidation",
    "Optivem.Atomiv.DependencyInjection.Infrastructure.MediatR",
    "Optivem.Atomiv.DependencyInjection.Infrastructure.NewtonsoftJson",
    "Optivem.Atomiv.DependencyInjection.Infrastructure.System",
    
    # Optivem.Atomiv.Infrastructure packages
    "Optivem.Atomiv.Infrastructure.AspNetCore",
    "Optivem.Atomiv.Infrastructure.AutoMapper",
    "Optivem.Atomiv.Infrastructure.CsvHelper",
    "Optivem.Atomiv.Infrastructure.EntityFrameworkCore",
    "Optivem.Atomiv.Infrastructure.EPPlus",
    "Optivem.Atomiv.Infrastructure.FluentValidation",
    "Optivem.Atomiv.Infrastructure.MediatR",
    "Optivem.Atomiv.Infrastructure.NewtonsoftJson",
    "Optivem.Atomiv.Infrastructure.Selenium",
    "Optivem.Atomiv.Infrastructure.SequentialGuid",
    "Optivem.Atomiv.Infrastructure.System",
    
    # Optivem.Atomiv.Templates
    "Optivem.Atomiv.Templates",
    
    # Optivem.Atomiv.Test packages
    "Optivem.Atomiv.Test.AspNetCore",
    "Optivem.Atomiv.Test.EntityFrameworkCore",
    "Optivem.Atomiv.Test.FluentAssertions",
    "Optivem.Atomiv.Test.MicrosoftExtensions",
    "Optivem.Atomiv.Test.Selenium",
    "Optivem.Atomiv.Test.Xunit",
    
    # Optivem.Atomiv.Web packages
    "Optivem.Atomiv.Web.AspNetCore",
    
    # Optivem.Common packages
    "Optivem.Common.Http",
    "Optivem.Common.Serialization",
    "Optivem.Common.WebAutomation",
    
    # Optivem.Core packages
    "Optivem.Core.All",
    "Optivem.Core.Application",
    "Optivem.Core.Application.Interface",
    "Optivem.Core.Common",
    "Optivem.Core.Domain",
    
    # Optivem.DependencyInjection packages
    "Optivem.DependencyInjection",
    "Optivem.DependencyInjection.Core.Application",
    "Optivem.DependencyInjection.Core.Domain",
    "Optivem.DependencyInjection.Infrastructure.AutoMapper",
    
    # Optivem.Framework.Core packages
    "Optivem.Framework.Core.All",
    "Optivem.Framework.Core.Application",
    "Optivem.Framework.Core.Application.Interface",
    "Optivem.Framework.Core.Application.Service",
    "Optivem.Framework.Core.Application.Service.Default",
    "Optivem.Framework.Core.Application.Services",
    "Optivem.Framework.Core.Application.Services.Default",
    "Optivem.Framework.Core.Common",
    "Optivem.Framework.Core.Common.Mapping",
    "Optivem.Framework.Core.Common.Parsing",
    "Optivem.Framework.Core.Common.Repository",
    "Optivem.Framework.Core.Common.RestClient",
    "Optivem.Framework.Core.Common.Serialization",
    "Optivem.Framework.Core.Common.WebAutomation",
    "Optivem.Framework.Core.Domain",
    "Optivem.Framework.Core.Domain.Entities",
    "Optivem.Framework.Core.Domain.Repositories",
    
    # Optivem.Framework.DependencyInjection packages
    "Optivem.Framework.DependencyInjection.Common",
    "Optivem.Framework.DependencyInjection.Core.Application",
    "Optivem.Framework.DependencyInjection.Core.Domain",
    "Optivem.Framework.DependencyInjection.Infrastructure.AutoMapper",
    "Optivem.Framework.DependencyInjection.Infrastructure.EntityFrameworkCore",
    "Optivem.Framework.DependencyInjection.Infrastructure.FluentValidation",
    "Optivem.Framework.DependencyInjection.Infrastructure.MediatR",
    "Optivem.Framework.DependencyInjection.Infrastructure.NewtonsoftJson",
    "Optivem.Framework.DependencyInjection.Infrastructure.System",
    
    # Optivem.Framework.Infrastructure packages
    "Optivem.Framework.Infrastructure.AspNetCore",
    "Optivem.Framework.Infrastructure.AutoMapper",
    "Optivem.Framework.Infrastructure.Common.Mapping.AutoMapper",
    "Optivem.Framework.Infrastructure.Common.Parsing.Default",
    "Optivem.Framework.Infrastructure.Common.Repository.EntityFrameworkCore",
    "Optivem.Framework.Infrastructure.Common.RestClient.Default",
    "Optivem.Framework.Infrastructure.Common.Serialization.Csv.CsvHelper",
    "Optivem.Framework.Infrastructure.Common.Serialization.Default",
    "Optivem.Framework.Infrastructure.Common.Serialization.Json.NewtonsoftJson",
    "Optivem.Framework.Infrastructure.Common.WebAutomation.Selenium",
    "Optivem.Framework.Infrastructure.CsvHelper",
    "Optivem.Framework.Infrastructure.Domain.Repositories.EntityFrameworkCore",
    "Optivem.Framework.Infrastructure.EntityFrameworkCore",
    "Optivem.Framework.Infrastructure.EPPlus",
    "Optivem.Framework.Infrastructure.FluentValidation",
    "Optivem.Framework.Infrastructure.MediatR",
    "Optivem.Framework.Infrastructure.NewtonsoftJson",
    "Optivem.Framework.Infrastructure.Selenium",
    "Optivem.Framework.Infrastructure.SequentialGuid",
    "Optivem.Framework.Infrastructure.System",
    
    # Optivem.Framework.Test packages
    "Optivem.Framework.Test.AspNetCore",
    "Optivem.Framework.Test.Common",
    "Optivem.Framework.Test.EntityFrameworkCore",
    "Optivem.Framework.Test.FluentAssertions",
    "Optivem.Framework.Test.MicrosoftExtensions",
    "Optivem.Framework.Test.Selenium",
    "Optivem.Framework.Test.Xunit",
    "Optivem.Framework.Test.Xunit.Common",
    "Optivem.Framework.Test.Xunit.Web.AspNetCore",
    
    # Optivem.Framework.Web packages
    "Optivem.Framework.Web.AspNetCore",
    "Optivem.Framework.Web.AspNetCore.Rest",
    
    # Optivem.Infrastructure packages
    "Optivem.Infrastructure.All",
    "Optivem.Infrastructure.AspNetCore",
    "Optivem.Infrastructure.AutoMapper",
    "Optivem.Infrastructure.CsvHelper",
    "Optivem.Infrastructure.EntityFrameworkCore",
    "Optivem.Infrastructure.FluentValidation",
    "Optivem.Infrastructure.Http.System",
    "Optivem.Infrastructure.Mapping.AutoMapper",
    "Optivem.Infrastructure.MediatR",
    "Optivem.Infrastructure.Messaging.MediatR",
    "Optivem.Infrastructure.NewtonsoftJson",
    "Optivem.Infrastructure.Persistence.EntityFrameworkCore",
    "Optivem.Infrastructure.Selenium",
    "Optivem.Infrastructure.Serialization.CsvHelper",
    "Optivem.Infrastructure.Serialization.NewtonsoftJson",
    "Optivem.Infrastructure.Serialization.System",
    "Optivem.Infrastructure.System",
    "Optivem.Infrastructure.Validation.FluentValidation",
    "Optivem.Infrastructure.WebAutomation.Selenium",
    
    # Optivem.Platform.Core packages
    "Optivem.Platform.Core.Application.Service",
    "Optivem.Platform.Core.Application.Service.Default",
    "Optivem.Platform.Core.Common.Mapping",
    "Optivem.Platform.Core.Common.Parsing",
    "Optivem.Platform.Core.Common.Repository",
    "Optivem.Platform.Core.Common.RestClient",
    "Optivem.Platform.Core.Common.Serialization",
    "Optivem.Platform.Core.Common.WebAutomation",
    
    # Optivem.Platform.Infrastructure packages
    "Optivem.Platform.Infrastructure.Common.Mapping.AutoMapper",
    "Optivem.Platform.Infrastructure.Common.Parsing.Default",
    "Optivem.Platform.Infrastructure.Common.Repository.EntityFrameworkCore",
    "Optivem.Platform.Infrastructure.Common.RestClient.Default",
    "Optivem.Platform.Infrastructure.Common.Serialization.Csv.CsvHelper",
    "Optivem.Platform.Infrastructure.Common.Serialization.Default",
    "Optivem.Platform.Infrastructure.Common.Serialization.Json.NewtonsoftJson",
    "Optivem.Platform.Infrastructure.Common.WebAutomation.Selenium",
    
    # Optivem.Platform.Test packages
    "Optivem.Platform.Test.Xunit.Common",
    "Optivem.Platform.Test.Xunit.Web.AspNetCore",
    
    # Optivem.Platform.Web packages
    "Optivem.Platform.Web.AspNetCore.Rest",
    
    # Optivem.Template/Templates
    "Optivem.Template",
    "Optivem.Templates",
    
    # Optivem.Test packages
    "Optivem.Test.All",
    "Optivem.Test.AspNetCore",
    "Optivem.Test.AspNetCore.EntityFrameworkCore",
    "Optivem.Test.Common",
    "Optivem.Test.EntityFrameworkCore",
    "Optivem.Test.Xunit",
    "Optivem.Test.Xunit.All",
    "Optivem.Test.Xunit.AspNetCore",
    "Optivem.Test.Xunit.AspNetCore.EntityFrameworkCore",
    "Optivem.Test.Xunit.Common",
    "Optivem.Test.Xunit.Selenium",
    
    # Optivem.Web packages
    "Optivem.Web.AspNetCore"
)

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Legacy Package Deprecation Script" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "📦 Found $($packages.Count) packages to process:" -ForegroundColor White
Write-Host ""
foreach ($pkg in $packages) {
    Write-Host "  • $pkg" -ForegroundColor Gray
}
Write-Host ""

if ($DryRun) {
    Write-Host "✓ Dry run complete. Use without -DryRun to actually deprecate packages." -ForegroundColor Green
    exit 0
}

# Confirm with user
Write-Host "⚠️  WARNING: This will unlist and deprecate all versions of these packages!" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Type 'YES' to proceed"
if ($confirmation -ne 'YES') {
    Write-Host "❌ Operation cancelled by user" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "❌ API key not provided. Set NUGET_API_KEY environment variable" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Starting Package Deprecation" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failCount = 0
$skippedCount = 0

foreach ($packageId in $packages) {
    Write-Host ""
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "📦 Processing: $packageId" -ForegroundColor Cyan
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    try {
        # Call the single package script
        $scriptPath = Join-Path $PSScriptRoot "Deprecate-Package.ps1"
        
        & $scriptPath -PackageId $packageId -ApiKey $ApiKey
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully processed $packageId" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "⚠️  Failed to process $packageId" -ForegroundColor Yellow
            $failCount++
        }
        
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "❌ Error processing $packageId`: $errorMessage" -ForegroundColor Red
        $failCount++
        
        # If rate limit error, suggest longer wait
        if ($errorMessage -like "*Rate limit*" -or $errorMessage -like "*403*") {
            Write-Host "" 
            Write-Host "⏳ Rate limit exceeded. Recommendation:" -ForegroundColor Yellow
            Write-Host "   1. Wait 1 hour for rate limit to reset" -ForegroundColor Cyan
            Write-Host "   2. Run script again - it will skip already processed packages" -ForegroundColor Cyan
            Write-Host "" 
            break  # Stop processing more packages
        }
    }
    
    # Delay between packages to avoid rate limiting
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Successfully processed: $successCount" -ForegroundColor Green
Write-Host "❌ Failed: $failCount" -ForegroundColor Red
Write-Host "📊 Total packages: $($packages.Count)" -ForegroundColor White
Write-Host ""
Write-Host "📝 Remember to manually deprecate on NuGet.org:" -ForegroundColor Yellow
Write-Host "   https://www.nuget.org/profiles/optivem" -ForegroundColor Cyan
Write-Host ""
