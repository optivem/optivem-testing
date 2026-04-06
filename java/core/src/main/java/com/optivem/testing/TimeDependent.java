package com.optivem.testing;

import org.junit.jupiter.api.Tag;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation to mark tests that depend on specific time values.
 * These tests require isolation from other tests and controlled time setup.
 * 
 * <p>This annotation automatically includes {@link Isolated @Isolated} since time-dependent
 * tests require isolation from other tests.
 * 
 * <p>Example usage:
 * <pre>
 * &#64;TimeDependent("2024-01-15T17:30:00Z")
 * void discountRateShouldBe15percentWhenTimeAfter5pm() {
 *     // Test implementation
 * }
 * </pre>
 * 
 * <h2>Filtering Tests</h2>
 * 
 * <h3>Run ONLY time-dependent tests:</h3>
 * <pre>
 * gradlew :system-test:acceptance-test:test -DincludeTags=time-dependent
 * </pre>
 * 
 * <h3>Run all tests EXCEPT time-dependent tests:</h3>
 * <pre>
 * gradlew :system-test:acceptance-test:test -DexcludeTags=time-dependent
 * </pre>
 * 
 * <p>For backward compatibility, the tag {@code time} is also applied so that
 * {@code -DincludeTags=time} and {@code -DexcludeTags=time} continue to work.
 * 
 * <h3>IDE Support:</h3>
 * Most IDEs that support JUnit 5 will recognize this tag automatically.
 */
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Tag("time-dependent")
@Tag("time")
@Isolated("Time-dependent test")
public @interface TimeDependent {
    /**
     * The specific time value for this test (ISO-8601 format).
     * Used for documentation and potential future automation.
     * @return time value in ISO-8601 format, empty string if not specified
     */
    String value() default "";
}
