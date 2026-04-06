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
}

