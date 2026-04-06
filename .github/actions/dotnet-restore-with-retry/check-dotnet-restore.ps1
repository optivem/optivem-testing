#!/usr/bin/env pwsh

<##
.SYNOPSIS
    Attempts dotnet restore for a project.

.PARAMETER ProjectPath
    Path to the .csproj to restore.

.PARAMETER Version
    Package version to pass via -p:Version.

.PARAMETER ExtraArgs
    Extra arguments for dotnet restore.

.NOTES
    Exit code 0 = restore succeeded
    Exit code 2 = restore failed, retry
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$ExtraArgs = ""
)

Write-Host "Restoring $ProjectPath..."

$command = "dotnet restore `"$ProjectPath`" --force --no-cache -p:Version=`"$Version`" $ExtraArgs"
Invoke-Expression $command

if ($LASTEXITCODE -eq 0) {
    Write-Host "Restore succeeded"
    exit 0
}

Write-Host "Restore failed"
exit 2
