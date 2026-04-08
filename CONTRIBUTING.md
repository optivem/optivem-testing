# Contributing

## Version Bump

The version is defined in the `VERSION` file at the repo root. To bump the version across all three languages:

1. Edit `VERSION` with the new version (e.g., `1.2.0`)
2. Run the bump script:
   ```bash
   bash scripts/bump-version.sh
   ```

This updates:
- `dotnet/Directory.Build.props` (`<VersionPrefix>`)
- `java/build.gradle` (`baseVersion`)
- `typescript/package.json` (`"version"`)

## CI/CD Pipeline

The pipeline has three stages:

### Commit Stage (automatic)

Triggers on push to `main`. Builds the library, runs tests, and publishes an RC (e.g., `1.1.1-rc.12`) to GitHub Packages.

Each language has its own workflow:
- `.NET Commit Stage`
- `Java Commit Stage`
- `TypeScript Commit Stage`

### Acceptance Stage (automatic + manual)

Runs hourly on a schedule. Smoke-tests the latest RC from GitHub Packages across all three languages in parallel.

To trigger manually:

```bash
# All languages in parallel
gh workflow run acceptance-stage.yml

# Individual languages
gh workflow run dotnet-acceptance-stage.yml
gh workflow run java-acceptance-stage.yml
gh workflow run typescript-acceptance-stage.yml
```

### Release Stage (manual)

Promotes tested RC artifacts to public registries (NuGet, Maven Central, npm), then creates a git tag and GitHub Release.

To trigger:

```bash
# All languages (uses latest RC for each)
gh workflow run release-stage.yml

# With specific RC versions
gh workflow run release-stage.yml \
  -f dotnet_rc_version=1.1.1-rc.6 \
  -f java_rc_version=1.1.1-rc.12 \
  -f typescript_rc_version=1.1.1-rc.3

# Individual languages
gh workflow run dotnet-release-stage.yml
gh workflow run java-release-stage.yml
gh workflow run typescript-release-stage.yml
```
