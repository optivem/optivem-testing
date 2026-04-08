# Plan: Add `also` channel filtering to `@DataSource` annotation

## Context

UI acceptance tests take much longer than API tests (e.g. 8m39s vs 17s). Currently, `@DataSource`/`@ChannelInlineData` creates a cartesian product with channels — every data row runs against every channel. This is wasteful because the same business logic is validated via API; UI only needs a representative subset.

**Ticket:** https://github.com/optivem/optivem-testing/issues/1

**Chosen design:** Add `also` attribute to the per-row data annotation (`@DataSource` in Java, `ChannelInlineData` in .NET, object property in TypeScript). The method-level `@Channel` declares the **base** channels that all rows run on. A row with `also` **adds** extra channels for that specific row. Fully backwards compatible — when omitted, the row runs on base channels only (current behavior).

### Example usage

**Java:**
```java
@TestTemplate
@Channel(ChannelType.API)
@DataSource(value = {"20.00", "5", "100.00"}, also = ChannelType.UI)   // API + UI
@DataSource({"10.00", "3", "30.00"})                                    // API only
@DataSource({"15.50", "4", "62.00"})                                    // API only

// Multiple additional channels
@DataSource(value = {"99.99", "1", "99.99"}, also = {ChannelType.UI, ChannelType.MOBILE})
```

**.NET:**
```csharp
[Theory]
[ChannelData(ChannelType.API)]
[ChannelInlineData("20.00", "5", "100.00", Also = new[] { ChannelType.UI })]   // API + UI
[ChannelInlineData("10.00", "3", "30.00")]                                      // API only
[ChannelInlineData("15.50", "4", "62.00")]                                      // API only
```

**TypeScript:**
```typescript
testEach([
    { unitPrice: '20.00', quantity: '5', basePrice: '100.00', also: ['UI'] },   // API + UI
    { unitPrice: '10.00', quantity: '3', basePrice: '30.00' },                   // API only
    { unitPrice: '15.50', quantity: '4', basePrice: '62.00' },                   // API only
])('should place order $unitPrice x $quantity = $basePrice', async ({ ... }) => { });
```

## Step 1: Revert stashed Design A changes

The current uncommitted changes implement the old `channels` (restrictive) design on `@DataSource`. Revert all files back to clean state, then implement fresh.

**Action:** `git checkout -- .` in `optivem-testing`

## Step 2: Java — Add `also` to `@DataSource` + update `ChannelExtension`

**Files to modify:**
- `java/core/src/main/java/com/optivem/testing/DataSource.java` — add `String[] also() default {}`
- `java/core/src/main/java/com/optivem/testing/extensions/ChannelExtension.java` — in the `@DataSource` processing section, for each data row: compute effective channels = base `@Channel` channels + `also` channels from the annotation. Generate invocations for the effective channels of each row.

**Logic:**
1. Read base channels from `@Channel` annotation (with existing system property filtering)
2. For each `@DataSource` annotation, read its `also` attribute
3. Effective channels for that row = base channels union also channels
4. Generate `ChannelInvocationContext` for each (effective channel, data row) pair

## Step 3: .NET — Add `Also` to `ChannelInlineDataAttribute` + update `ChannelDataAttribute`

**Files to modify:**
- `dotnet/Optivem.Testing/ChannelInlineDataAttribute.cs` — add `public string[]? Also { get; set; }` named property
- `dotnet/Optivem.Testing/ChannelDataAttribute.cs` — in `GetData()`, when processing `ChannelInlineData` rows: for each row, compute effective channels = base `_channels` + row's `Also`. Only yield test cases for effective channels.

## Step 4: TypeScript — Add `also` support to `bindTestEach` + `shopChannelTest`

**Files to modify:**
- `typescript/src/channel.ts` — expose `getRegistrationChannel()` (module-level variable set during `forChannels` block registration)
- `typescript/src/playwright/bindTestEach.ts` — for each test case, read `also` property. If current registration channel is NOT in base channels AND NOT in `also`, skip. Strip `also` from row data before passing to test.
- `typescript/src/index.ts` — export `getRegistrationChannel`
- `eshop-tests/typescript/system-test/src/shopChannelTest.ts` — when iterating data array, read `also` from each item. For that item, call `channelTest` with base channels + also channels.

## Step 5: Add tests for all 3 languages

**Java:** `java/core/src/test/java/com/optivem/testing/channels/ChannelExtensionTest.java`
- Test: `@Channel(CHANNEL_A)` with `@DataSource(value = "both", also = CHANNEL_B)` and `@DataSource("baseOnly")` — verify first row runs on both channels, second row only on CHANNEL_A
- Test: multiple `also` channels
- Test: without `also` — verify current cartesian product behavior unchanged

**.NET:** `dotnet/Optivem.Testing.Tests/ChannelDataAttributeTests.cs`
- Test: `[ChannelData("API")]` with `[ChannelInlineData("20.00", Also = new[] { "UI" })]` and `[ChannelInlineData("10.00")]` — verify first row gets API+UI, second gets API only
- Test: without `Also` — current behavior unchanged

**TypeScript:** Type-check with `npx tsc --noEmit`

## Step 6: Run tests to verify

- Java: `./gradlew :core:test` in `optivem-testing/java`
- .NET: `dotnet test Optivem.Testing.Tests` in `optivem-testing/dotnet`
- TypeScript: `npx tsc --noEmit` in `optivem-testing/typescript`

## Key design decisions

- `also` lives on `@DataSource` / `ChannelInlineData` (per-row) — because it's about which extra channels a specific row needs
- `@Channel` becomes the **base** channels (all rows get these)
- `also` is **additive** — it adds channels beyond the base, never restricts
- Supports single or multiple channels: `also = ChannelType.UI` or `also = {ChannelType.UI, ChannelType.MOBILE}`
- Self-documenting: each row shows its own channel behavior
- No positional dependency — reordering rows doesn't change behavior
- Fully backwards compatible — omitting `also` means the row runs on base channels only
