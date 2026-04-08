# Optivem Testing (.NET)

[![NuGet](https://img.shields.io/nuget/v/Optivem.Testing.svg)](https://www.nuget.org/packages/Optivem.Testing/)
[![License](https://img.shields.io/github/license/optivem/optivem-testing.svg)](LICENSE)

**Optivem.Testing** is an xUnit extension for channel-based data-driven testing. It enables you to run the same tests across multiple channels (UI, API, etc.) with automatic Cartesian product generation, test isolation markers, and time-dependent test support.

## Features

- **Channel-Based Testing** - Run tests across multiple channels (UI, API, etc.)
- **Cartesian Product Generation** - Automatically combine channels with test data
- **Flexible Data Sources** - Supports inline data, class data, and member data
- **Test Isolation** - Mark tests that require isolation (`[Isolated]`)
- **Time-Dependent Tests** - Mark time-sensitive tests (`[Time]`)
- **.NET 8+** - Modern .NET support

## Installation

```bash
dotnet add package Optivem.Testing
```

## Quick Start

### Basic Channel Testing

Run the same test across multiple channels:

```csharp
[Theory]
[ChannelData("UI", "API")]
public void CreateOrder_ShouldSucceed(Channel channel)
{
    // Arrange
    var order = new Order { ProductId = "P1", Quantity = 1 };
    
    // Act
    var result = channel.Type == "UI" 
        ? CreateOrderViaUI(order) 
        : CreateOrderViaAPI(order);
    
    // Assert
    result.Success.ShouldBeTrue();
}
// Generates 2 tests: CreateOrder_ShouldSucceed(UI), CreateOrder_ShouldSucceed(API)
```

### Channel + Inline Data (Cartesian Product)

Combine channels with test data for comprehensive coverage:

```csharp
[Theory]
[ChannelData("UI", "API")]
[ChannelInlineData("", "Country must not be empty")]
[ChannelInlineData("   ", "Country must not be empty")]
[ChannelInlineData("123", "Country must contain only letters")]
public void CreateOrder_InvalidCountry_ShouldFail(
    Channel channel, 
    string country, 
    string expectedError)
{
    // Test implementation validates error message
}
// Generates 6 tests: 2 channels x 3 data rows
```

### Channel + Class Data

Use a class to provide test data:

```csharp
public class InvalidCountryData : IEnumerable<object[]>
{
    public IEnumerator<object[]> GetEnumerator()
    {
        yield return new object[] { "", "Country must not be empty" };
        yield return new object[] { "   ", "Country must not be empty" };
        yield return new object[] { "123", "Country must contain only letters" };
    }
    
    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}

[Theory]
[ChannelData("UI", "API")]
[ChannelClassData(typeof(InvalidCountryData))]
public void CreateOrder_InvalidCountry_ShouldFail(
    Channel channel, 
    string country, 
    string expectedError)
{
    // Test implementation
}
```

### Channel + Member Data

Use a method or property to provide test data:

```csharp
public static IEnumerable<object[]> GetInvalidCountries()
{
    yield return new object[] { "", "Country must not be empty" };
    yield return new object[] { "   ", "Country must not be empty" };
    yield return new object[] { "123", "Country must contain only letters" };
}

[Theory]
[ChannelData("UI", "API")]
[ChannelMemberData(nameof(GetInvalidCountries))]
public void CreateOrder_InvalidCountry_ShouldFail(
    Channel channel, 
    string country, 
    string expectedError)
{
    // Test implementation
}
```

### Channel + Inline Data with Additional Channels (`Also`)

Reduce UI test count by running only representative data rows on slow channels:

```csharp
[Theory]
[ChannelData("API")]
[ChannelInlineData("20.00", "5", "100.00", Also = new[] { "UI" })]   // API + UI
[ChannelInlineData("10.00", "3", "30.00")]                            // API only
[ChannelInlineData("15.50", "4", "62.00")]                            // API only
[ChannelInlineData("99.99", "1", "99.99")]                            // API only
public void PlaceOrder_ShouldCalculateCorrectBasePrice(
    Channel channel,
    string unitPrice,
    string quantity,
    string basePrice)
{
    // Test implementation
}
// Generates 5 tests: API×4 rows + UI×1 row (the one with Also)
// Without Also: would be 8 tests (2 channels × 4 rows)
```

The `Also` property accepts an array of additional channel names. When specified, that data row runs on the base channels **plus** the additional channels. When omitted, the row runs on base channels only. This is fully backwards compatible.

## Test Isolation

Mark tests that require isolation from other tests:

```csharp
[Fact]
[Isolated("Deletes all orders from database")]
public void ClearAllOrders_ShouldDeleteAllRecords()
{
    // This test modifies shared state
}
```

**Filter isolated tests:**

```bash
# Run ONLY isolated tests
dotnet test --filter "Category=isolated"

# Run all EXCEPT isolated tests
dotnet test --filter "Category!=isolated"
```

## Time-Dependent Tests

Mark tests that depend on specific times:

```csharp
[Fact]
[Time("2024-01-15T17:30:00Z")]
public void DiscountRate_ShouldBe15Percent_WhenAfter5pm()
{
    // Test implementation
}
```

**Filter time-dependent tests:**

```bash
# Run ONLY time-dependent tests
dotnet test --filter "Category=time"

# Run all EXCEPT time-dependent tests
dotnet test --filter "Category!=time"
```

## Best Practices

1. **Channel Naming** - Use consistent channel names across your test suite (e.g., "UI", "API", "CLI")
2. **Isolation** - Always mark tests with side effects using `[Isolated]`
3. **Test Data** - Use `ChannelClassData` or `ChannelMemberData` for complex test data
4. **Time Tests** - `[Time]` tests are automatically marked as `[Isolated]`

## Why Optivem.Testing?

- **Reduce Duplication** - Write test logic once, run across all channels
- **Better Coverage** - Cartesian products ensure comprehensive testing
- **Clear Intent** - Attributes make test requirements explicit
- **Type Safety** - `Channel` type prevents string typos
- **xUnit Compatible** - Works seamlessly with existing xUnit tests

## Requirements

- .NET 8.0 or higher
- xUnit 2.x

## License

[MIT License](LICENSE)

## Links

- [GitHub Repository](https://github.com/optivem/optivem-testing)
- [NuGet Package](https://www.nuget.org/packages/Optivem.Testing/)

---

Built by [Optivem](https://github.com/optivem)
