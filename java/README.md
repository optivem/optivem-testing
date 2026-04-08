# Optivem Testing (Java)

[![Maven Central](https://img.shields.io/maven-central/v/com.optivem/optivem-testing)](https://central.sonatype.com/artifact/com.optivem/optivem-testing)
[![License](https://img.shields.io/github/license/optivem/optivem-testing.svg)](LICENSE)

A testing library to support channel-based Acceptance Testing in Java.

## Installation

### Gradle

```gradle
dependencies {
    implementation 'com.optivem:optivem-testing:1.1.1'
}
```

### Maven

```xml
<dependency>
    <groupId>com.optivem</groupId>
    <artifactId>optivem-testing</artifactId>
    <version>1.1.1</version>
</dependency>
```

## Usage

### Basic Channel Testing

Run the same test across multiple channels:

```java
@TestTemplate
@Channel({ChannelType.UI, ChannelType.API})
void shouldCreateOrder() {
    // Runs twice: once for UI, once for API
}
```

### Channel + DataSource (Cartesian Product)

Combine channels with test data:

```java
@TestTemplate
@Channel({ChannelType.UI, ChannelType.API})
@DataSource({"20.00", "5", "100.00"})
@DataSource({"10.00", "3", "30.00"})
void shouldPlaceOrder(String unitPrice, String quantity, String basePrice) {
    // Generates 4 tests: 2 channels × 2 data rows
}
```

### Channel + DataSource with Additional Channels (`also`)

Reduce UI test count by running only representative data rows on slow channels:

```java
@TestTemplate
@Channel(ChannelType.API)
@DataSource(value = {"20.00", "5", "100.00"}, also = ChannelType.UI)   // API + UI
@DataSource({"10.00", "3", "30.00"})                                    // API only
@DataSource({"15.50", "4", "62.00"})                                    // API only
@DataSource({"99.99", "1", "99.99"})                                    // API only
void shouldPlaceOrderWithCorrectBasePrice(String unitPrice, String quantity, String basePrice) {
    // Generates 5 tests: API×4 rows + UI×1 row (the one with also)
    // Without also: would be 8 tests (2 channels × 4 rows)
}
```

The `also` attribute accepts one or more additional channel names. When specified, that data row runs on the base channels **plus** the additional channels. When omitted, the row runs on base channels only. This is fully backwards compatible.

## Requirements

- Java 21 or higher
- Gradle 9.1.0 (included via wrapper)

## License

[MIT License](LICENSE)

## Links

- [GitHub Repository](https://github.com/optivem/optivem-testing)
- [Maven Central](https://central.sonatype.com/artifact/com.optivem/optivem-testing)

---

Built by [Optivem](https://github.com/optivem)
