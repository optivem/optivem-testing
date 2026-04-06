# Optivem Testing (Java)

[![Maven Central](https://img.shields.io/maven-central/v/com.optivem/optivem-testing)](https://central.sonatype.com/artifact/com.optivem/optivem-testing)
[![License](https://img.shields.io/github/license/optivem/optivem-testing.svg)](LICENSE)

A testing library to support channel-based Acceptance Testing in Java.

## Installation

### Gradle

```gradle
dependencies {
    implementation 'com.optivem:optivem-testing:1.1.0'
}
```

### Maven

```xml
<dependency>
    <groupId>com.optivem</groupId>
    <artifactId>optivem-testing</artifactId>
    <version>1.1.0</version>
</dependency>
```

## Code Example

```java
import com.optivem.testing.Channel;

public class Example {
    public static void main(String[] args) {
        Channel channel = new Channel("test-channel");
        
        String name = channel.getName();
        System.out.println("Channel name: " + name);  // Output: test-channel
    }
}
```

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
