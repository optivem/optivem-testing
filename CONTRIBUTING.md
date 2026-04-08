# Contributing

## Version Bump

The version is defined in the `VERSION` file at the repo root. To bump the version across all three languages:

1. Edit `VERSION` with the new version (e.g., `1.2.0`)
2. Run the bump script:
   ```bash
   bash scripts/bump-version.sh
   ```

This updates:
- `java/build.gradle` (`baseVersion`)
- `dotnet/Directory.Build.props` (`<VersionPrefix>`)
- `typescript/package.json` (`"version"`)

## Release Checklist

```bash
# 1. Bump version, commit, and push (triggers commit stages automatically)
echo "1.2.0" > VERSION
bash scripts/bump-version.sh
# commit & push

# 2. Watch commit stages
gh run watch $(gh run list -w "java-commit-stage.yml" -L 1 --json databaseId -q '.[0].databaseId')
gh run watch $(gh run list -w "dotnet-commit-stage.yml" -L 1 --json databaseId -q '.[0].databaseId')
gh run watch $(gh run list -w "typescript-commit-stage.yml" -L 1 --json databaseId -q '.[0].databaseId')

# 3. Trigger acceptance and watch
gh workflow run acceptance-stage.yml
sleep 5
gh run watch $(gh run list -w "acceptance-stage.yml" -L 1 --json databaseId -q '.[0].databaseId')

# 4. Trigger release and watch
gh workflow run release-stage.yml
sleep 5
gh run watch $(gh run list -w "release-stage.yml" -L 1 --json databaseId -q '.[0].databaseId')
```

## CI/CD Pipeline

The pipeline has three stages:

### Commit Stage (automatic)

Triggers on push to `main`. Builds the library, runs tests, and publishes an RC (e.g., `1.1.1-rc.12`) to GitHub Packages.

Each language has its own workflow:
- `Java Commit Stage`
- `.NET Commit Stage`
- `TypeScript Commit Stage`

### Acceptance Stage (automatic + manual)

Runs hourly on a schedule. Smoke-tests the latest RC from GitHub Packages across all three languages in parallel.

To trigger and watch:

```bash
gh workflow run acceptance-stage.yml
sleep 5
gh run watch $(gh run list -w "acceptance-stage.yml" -L 1 --json databaseId -q '.[0].databaseId')

# Individual languages
gh workflow run java-acceptance-stage.yml
gh workflow run dotnet-acceptance-stage.yml
gh workflow run typescript-acceptance-stage.yml
```

### Release Stage (manual)

Promotes tested RC artifacts to public registries (NuGet, Maven Central, npm), then creates a git tag and GitHub Release.

By default, it picks the latest RC for each language. Each language has its own RC counter (e.g., Java at `rc.12`, .NET at `rc.6`, TypeScript at `rc.3`) since their commit stages run independently. The base version is always the same — the release stage strips the `-rc.N` suffix and publishes all three as the same version. You only need to specify RC versions explicitly if you want to release a specific earlier RC (e.g., if the latest one is broken).

To trigger and watch:

```bash
# All languages (uses latest RC for each — recommended)
gh workflow run release-stage.yml
sleep 5
gh run watch $(gh run list -w "release-stage.yml" -L 1 --json databaseId -q '.[0].databaseId')

# With specific RC versions (only if needed)
gh workflow run release-stage.yml \
  -f java_rc_version=1.1.1-rc.12 \
  -f dotnet_rc_version=1.1.1-rc.6 \
  -f typescript_rc_version=1.1.1-rc.3

# Individual languages
gh workflow run java-release-stage.yml
gh workflow run dotnet-release-stage.yml
gh workflow run typescript-release-stage.yml
```
