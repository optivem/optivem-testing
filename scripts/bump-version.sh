#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
VERSION_FILE="$REPO_ROOT/VERSION"

if [ ! -f "$VERSION_FILE" ]; then
  echo "ERROR: VERSION file not found at $VERSION_FILE"
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

if [ -z "$VERSION" ]; then
  echo "ERROR: VERSION file is empty"
  exit 1
fi

echo "Bumping version to $VERSION ..."

# .NET — Directory.Build.props
DOTNET_FILE="$REPO_ROOT/dotnet/Directory.Build.props"
sed -i "s|<VersionPrefix>.*</VersionPrefix>|<VersionPrefix>$VERSION</VersionPrefix>|" "$DOTNET_FILE"
echo "  Updated $DOTNET_FILE"

# Java — root build.gradle
JAVA_FILE="$REPO_ROOT/java/build.gradle"
sed -i "s|def baseVersion = '.*'|def baseVersion = '$VERSION'|" "$JAVA_FILE"
echo "  Updated $JAVA_FILE"

# TypeScript — package.json
TS_FILE="$REPO_ROOT/typescript/package.json"
sed -i "s|\"version\": \".*\"|\"version\": \"$VERSION\"|" "$TS_FILE"
echo "  Updated $TS_FILE"

echo "Done. All files updated to $VERSION"
