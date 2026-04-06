# System Tests

This directory contains system-level tests that verify the published packages work correctly.

## Test Modules

### Smoke Test RC

The `Optivem.Testing.SystemTest.SmokeTestRc` project tests the Release Candidate (RC) packages published to GitHub Packages.

#### Purpose

- Validates that the RC package can be resolved from GitHub Packages
- Verifies the package API works correctly when consumed as a NuGet dependency
- Runs smoke tests to ensure critical functionality is working
- Tests pre-release versions (e.g., 1.0.2-rc.1)

#### Running Locally

```bash
cd SystemTest/Optivem.Testing.SystemTest.SmokeTestRc
dotnet restore
dotnet test
```

#### CI/CD Integration

These tests run automatically:
- Every hour via scheduled workflow
- As part of the acceptance stage after RC packages are published
- Before promoting an RC to a stable release

### Smoke Test Release

The `Optivem.Testing.SystemTest.SmokeTestRelease` project tests the stable release packages published to NuGet.org.

#### Purpose

- Validates that the release package can be resolved from NuGet.org
- Verifies the package is accessible to public consumers
- Tests stable release versions (e.g., 1.0.2)
- Ensures no GitHub Packages authentication is required

#### Running Locally

```bash
cd SystemTest/Optivem.Testing.SystemTest.SmokeTestRelease
dotnet restore
dotnet test
```

#### CI/CD Integration

These tests can run:
- After manual verification that a release version is indexed on NuGet.org
- To validate that published releases work correctly
- Before creating GitHub releases
- As scheduled health checks for published packages

## Key Differences from Unit Tests

Unlike `Optivem.Testing.Tests` which uses project references, these test projects:
- Reference `Optivem.Testing` as a NuGet package (not a project reference)
- Consume published versions from package repositories
- Simulate how end-users will consume the package
- Run as part of the deployment pipeline validation
