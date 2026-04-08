package com.optivem.testing;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation to specify which channels (UI, API, etc.) a test should run against.
 * Used in combination with ChannelExtension to create test instances for each channel.
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface Channel {
    /**
     * Array of channel types this test should run against.
     * For example: {ChannelType.UI, ChannelType.API}
     * @return array of channel names
     */
    String[] value();

    /**
     * Additional channels that only the first data row should run on.
     * All other rows run only on the base channels from {@link #value()}.
     * <p>
     * Example:
     * <pre>
     * &#64;TestTemplate
     * &#64;Channel(value = ChannelType.API, alsoForFirstRow = ChannelType.UI)
     * &#64;ValueSource(strings = {"3.5", "lala"})
     * void test(String value) {
     *     // "3.5" runs on API + UI, "lala" runs on API only
     * }
     * </pre>
     * @return additional channel types for the first data row only
     */
    String[] alsoForFirstRow() default {};
}
