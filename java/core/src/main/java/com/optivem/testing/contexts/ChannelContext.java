package com.optivem.testing.contexts;

/**
 * Thread-local context holder for the current channel being tested.
 * Used by the ChannelExtension to set the channel for each test invocation,
 * and by DriverFactory to determine which driver implementation to create.
 */
public class ChannelContext {

    private static final ThreadLocal<String> channelThreadLocal = new ThreadLocal<>();

    /**
     * Creates a new ChannelContext.
     * This class only contains static methods, so direct instantiation is not typically needed.
     */
    public ChannelContext() {
        // Utility class with static methods
    }

    /**
     * Set the current channel for the current thread.
     * @param channel the channel name to set for the current thread
     */
    public static void set(String channel) {
        channelThreadLocal.set(channel);
    }

    /**
     * Get the current channel for the current thread.
     * @return the current channel name, or null if none is set
     */
    public static String get() {
        return channelThreadLocal.get();
    }

    /**
     * Clear the channel context for the current thread.
     */
    public static void clear() {
        channelThreadLocal.remove();
    }
}

