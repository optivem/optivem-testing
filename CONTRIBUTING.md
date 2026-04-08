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
