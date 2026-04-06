# Scripts

This folder contains utility scripts for development and CI/CD.

## Configure-GitHubPackages.ps1

Configures NuGet to authenticate with GitHub Packages using environment variables.

**Prerequisites:**
- Set `GITHUB_USERNAME` environment variable
- Set `GITHUB_READ_PACKAGES_TOKEN` environment variable with a GitHub PAT that has `read:packages` scope

**Usage:**
```powershell
.\scripts\Configure-GitHubPackages.ps1
```

This only needs to be run once on a new machine. The credentials are stored globally in your NuGet configuration.

**Setting Environment Variables:**
```powershell
# Set environment variables (one-time setup)
[System.Environment]::SetEnvironmentVariable('GITHUB_USERNAME','your-github-username','User')
[System.Environment]::SetEnvironmentVariable('GITHUB_READ_PACKAGES_TOKEN','your-token','User')

# Restart VS Code to load the new environment variables
```
