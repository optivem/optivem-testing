# Smoke Test Release

This module verifies the release version of optivem-testing library published to NuGet.org.

## Purpose

- Tests the published release version from NuGet.org
- Ensures the library is correctly published and accessible
- Validates basic functionality of the released artifacts
- Simulates real-world consumer experience of the package

## Key Differences from Smoke Test RC

Unlike `Optivem.Testing.SystemTest.SmokeTestRc` which tests RC versions from GitHub Packages:
- References `Optivem.Testing` from **NuGet.org only** (no GitHub Packages)
- Tests **stable release versions** (e.g., 1.0.2) not RC versions
- Uses wildcard version `*` to resolve the latest release version
- Validates the package accessible to public consumers

## Running Tests

### Test default version (from Directory.Build.props)
```bash
cd SystemTest/Optivem.Testing.SystemTest.SmokeTestRelease
dotnet restore
dotnet test
```

### Test specific version (useful for verifying newly published releases)
```bash
cd SystemTest/Optivem.Testing.SystemTest.SmokeTestRelease
dotnet test -p:Version=1.0.4
```

This allows flexible testing:
- **Without parameter**: Tests `$(VersionPrefix)` from Directory.Build.props (baseline version)
- **With `-p:Version=X.Y.Z`**: Tests that specific version from NuGet.org (useful for release verification)

## CI/CD Integration

This project is **excluded from the main solution** to prevent restore failures during regular CI builds (when the version doesn't exist on NuGet.org yet). It's only tested during the release-stage workflow with an explicit version parameter.

## Configuration

The `nuget.config` file is configured to:
- Use only NuGet.org as the package source
- NOT include GitHub Packages (unlike SmokeTestRc)
- Ensure tests validate public package availability

## CI/CD Integration

These tests can run:
- After manual verification that a release version is indexed on NuGet.org
- To validate that published releases work correctly
- Before creating GitHub releases
- As scheduled health checks for published packages
