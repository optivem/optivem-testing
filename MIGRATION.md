# Migration Plan: Monorepo Merge + @DataSource Channel Filtering

## Context
Three separate repos (optivem-testing-java, optivem-testing-dotnet, optivem-testing-typescript) merged into this monorepo to maintain consistency with the academy's monorepo pattern.

## Completed
- [x] Created optivem-testing monorepo
- [x] Copied files from all 3 repos into java/, dotnet/, typescript/ folders
- [x] Merged GitHub Actions workflows with language prefixes and path filters
- [x] Merged custom actions into shared .github/actions/
- [x] Updated workflow names, concurrency groups, and working directories
- [x] Bumped versions: Java 1.0.4→1.0.5, .NET 1.0.6→1.0.7, TypeScript 1.0.12→1.0.13
- [x] Updated .NET repo URLs to point to new monorepo
- [x] Initial commit and push

## TODO
- [ ] Verify CI passes for all 3 languages (commit stage workflows)
- [ ] Trigger release for each language (Java 1.0.5, .NET 1.0.7, TypeScript 1.0.13)
- [ ] Archive old repos (optivem-testing-java, optivem-testing-dotnet, optivem-testing-typescript)
- [ ] Update consumers (eshop-tests, starter) to reference new repo
- [ ] Create GitHub issue for @DataSource channel filtering feature

## Previous Repos
- https://github.com/optivem/optivem-testing-java (latest: v1.0.4)
- https://github.com/optivem/optivem-testing-dotnet (latest: v1.0.6)
- https://github.com/optivem/optivem-testing-typescript (latest: v1.0.12)
