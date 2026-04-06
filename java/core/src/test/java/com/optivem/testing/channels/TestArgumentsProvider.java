package com.optivem.testing.channels;

import org.junit.jupiter.api.extension.ExtensionContext;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.ArgumentsProvider;

import java.util.stream.Stream;

/**
 * Custom ArgumentsProvider for testing @ArgumentsSource support.
 */
public class TestArgumentsProvider implements ArgumentsProvider {

    @Override
    public Stream<? extends Arguments> provideArguments(ExtensionContext context) {
        return Stream.of(
                Arguments.of("arg1", 100),
                Arguments.of("arg2", 200),
                Arguments.of("arg3", 300)
        );
    }
}

