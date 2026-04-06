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
 * @deprecated Use {@link TimeDependent @TimeDependent} instead. This annotation is preserved
 *             for backward compatibility and may be removed in a future release.
 * @see TimeDependent
 */
@Deprecated(since = "1.0.4", forRemoval = true)
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Tag("time")
@Isolated("Time-dependent test")
public @interface Time {
    /**
     * The specific time value for this test (ISO-8601 format).
     * Used for documentation and potential future automation.
     * @return time value in ISO-8601 format, empty string if not specified
     */
    String value() default "";
}
