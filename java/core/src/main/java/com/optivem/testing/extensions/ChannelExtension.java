package com.optivem.testing.extensions;

import com.optivem.testing.Channel;
import com.optivem.testing.DataSource;
import com.optivem.testing.contexts.ChannelContext;
import org.junit.jupiter.api.extension.*;
import org.junit.jupiter.params.provider.*;

import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Stream;

/**
 * JUnit Jupiter extension that enables running tests across multiple channels.
 * When a test method is annotated with @Channel and @TestTemplate, this extension
 * creates separate test invocations for each specified channel (e.g., UI, API).
 * <p>
 * Also supports @DataSource, @ValueSource, @MethodSource, and @ArgumentsSource to combine channel types with test data.
 */
public class ChannelExtension implements TestTemplateInvocationContextProvider {

    /**
     * Creates a new ChannelExtension.
     */
    public ChannelExtension() {
        // Default constructor
    }

    @Override
    public boolean supportsTestTemplate(ExtensionContext context) {
        return context.getTestMethod()
                .map(method -> method.isAnnotationPresent(Channel.class))
                .orElse(false);
    }

    @Override
    public Stream<TestTemplateInvocationContext> provideTestTemplateInvocationContexts(ExtensionContext context) {
        Method testMethod = context.getRequiredTestMethod();
        Channel channelAnnotation = testMethod.getAnnotation(Channel.class);
        String[] channels = channelAnnotation.value();

        // Filter channels based on system property if set
        String channelFilter = System.getProperty("channel");
        if (channelFilter != null && !channelFilter.isEmpty()) {
            channels = Arrays.stream(channels)
                    .filter(channel -> channel.equalsIgnoreCase(channelFilter))
                    .toArray(String[]::new);
            
            // If no channels match the filter, return a disabled context instead of empty stream
            if (channels.length == 0) {
                String skipMessage = channelFilter + " channel was not specified";
                return Stream.of(new DisabledInvocationContext(testMethod.getName(), skipMessage));
            }
        }

        List<Object[]> dataRows = new ArrayList<>();

        // Check if the method has @ArgumentsSource annotation
        ArgumentsSource argumentsSourceAnnotation = testMethod.getAnnotation(ArgumentsSource.class);
        if (argumentsSourceAnnotation != null) {
            // Handle @ArgumentsSource - instantiate the provider class
            Class<? extends ArgumentsProvider> providerClass = argumentsSourceAnnotation.value();
            try {
                ArgumentsProvider provider = providerClass.getDeclaredConstructor().newInstance();
                provider.provideArguments(context).forEach(arg -> {
                    Object[] arguments = arg.get();
                    dataRows.add(arguments);
                });
            } catch (Exception e) {
                throw new RuntimeException("Failed to instantiate @ArgumentsSource provider: " + providerClass.getName(), e);
            }
        }
        // Check if the method has @MethodSource annotation
        else if (testMethod.isAnnotationPresent(MethodSource.class)) {
            MethodSource methodSourceAnnotation = testMethod.getAnnotation(MethodSource.class);
            // Handle @MethodSource - invoke the provider method
            String[] methodNames = methodSourceAnnotation.value();
            if (methodNames.length == 0) {
                // Default: use test method name
                methodNames = new String[]{testMethod.getName()};
            }

            for (String methodName : methodNames) {
                try {
                    Method providerMethod = context.getRequiredTestClass().getDeclaredMethod(methodName);
                    providerMethod.setAccessible(true);
                    Object result = providerMethod.invoke(null);

                    if (result instanceof Stream) {
                        ((Stream<?>) result).forEach(arg -> {
                            if (arg instanceof org.junit.jupiter.params.provider.Arguments) {
                                Object[] arguments = ((org.junit.jupiter.params.provider.Arguments) arg).get();
                                dataRows.add(arguments);
                            }
                        });
                    }
                } catch (Exception e) {
                    throw new RuntimeException("Failed to invoke @MethodSource provider: " + methodName, e);
                }
            }
        }
        // Check if the method has @ValueSource annotation
        else if (testMethod.isAnnotationPresent(ValueSource.class)) {
            ValueSource valueSourceAnnotation = testMethod.getAnnotation(ValueSource.class);
            extractValuesFromValueSource(valueSourceAnnotation, dataRows);
        }
        // Check if the method has @CsvSource annotation
        else if (testMethod.isAnnotationPresent(CsvSource.class)) {
            CsvSource csvSourceAnnotation = testMethod.getAnnotation(CsvSource.class);
            extractValuesFromCsvSource(csvSourceAnnotation, dataRows);
        }
        // Check if the method has @EnumSource annotation
        else if (testMethod.isAnnotationPresent(EnumSource.class)) {
            EnumSource enumSourceAnnotation = testMethod.getAnnotation(EnumSource.class);
            extractValuesFromEnumSource(enumSourceAnnotation, dataRows);
        }
        // Check if the method has @NullAndEmptySource annotation
        else if (testMethod.isAnnotationPresent(NullAndEmptySource.class)) {
            extractValuesFromNullAndEmptySource(testMethod, dataRows);
            // Also check for @ValueSource to combine
            if (testMethod.isAnnotationPresent(ValueSource.class)) {
                ValueSource valueSourceAnnotation = testMethod.getAnnotation(ValueSource.class);
                extractValuesFromValueSource(valueSourceAnnotation, dataRows);
            }
        }
        // Check if the method has @NullSource annotation
        else if (testMethod.isAnnotationPresent(NullSource.class)) {
            dataRows.add(new Object[]{null});
        }
        // Check if the method has @EmptySource annotation
        else if (testMethod.isAnnotationPresent(EmptySource.class)) {
            extractValuesFromEmptySource(testMethod, dataRows);
        } else {
            // Check if the method has DataSource annotations
            DataSource.Container containerAnnotation =
                    testMethod.getAnnotation(DataSource.Container.class);
            DataSource singleAnnotation =
                    testMethod.getAnnotation(DataSource.class);

            if (containerAnnotation != null) {
                // Multiple @DataSource annotations
                for (DataSource annotation : containerAnnotation.value()) {
                    dataRows.addAll(extractArgumentsFromAnnotation(annotation, context));
                }
            } else if (singleAnnotation != null) {
                // Single @DataSource annotation
                dataRows.addAll(extractArgumentsFromAnnotation(singleAnnotation, context));
            }
        }

        if (dataRows.isEmpty()) {
            // No data annotations, just run for each channel
            return Arrays.stream(channels)
                    .map(channel -> new ChannelInvocationContext(channel, null, testMethod));
        } else {
            // Combine channels with data rows
            List<TestTemplateInvocationContext> contexts = new ArrayList<>();
            for (String channel : channels) {
                for (Object[] dataRow : dataRows) {
                    contexts.add(new ChannelInvocationContext(channel, dataRow, testMethod));
                }
            }
            return contexts.stream();
        }
    }

    /**
     * Extracts arguments from a single @DataSource annotation.
     */
    private List<Object[]> extractArgumentsFromAnnotation(DataSource annotation, ExtensionContext context) {
        List<Object[]> results = new ArrayList<>();

        // Use inline values
        String[] values = annotation.value();
        Object[] row = new Object[values.length];
        for (int i = 0; i < values.length; i++) {
            row[i] = values[i];
        }
        results.add(row);

        return results;
    }

    /**
     * Extracts arguments from a @ValueSource annotation.
     * Supports strings, ints, longs, doubles, floats, shorts, bytes, chars, booleans, and classes.
     */
    private void extractValuesFromValueSource(ValueSource annotation, List<Object[]> dataRows) {
        // Check each type of value in @ValueSource
        if (annotation.strings().length > 0) {
            for (String value : annotation.strings()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.ints().length > 0) {
            for (int value : annotation.ints()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.longs().length > 0) {
            for (long value : annotation.longs()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.doubles().length > 0) {
            for (double value : annotation.doubles()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.floats().length > 0) {
            for (float value : annotation.floats()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.shorts().length > 0) {
            for (short value : annotation.shorts()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.bytes().length > 0) {
            for (byte value : annotation.bytes()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.chars().length > 0) {
            for (char value : annotation.chars()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.booleans().length > 0) {
            for (boolean value : annotation.booleans()) {
                dataRows.add(new Object[]{value});
            }
        } else if (annotation.classes().length > 0) {
            for (Class<?> value : annotation.classes()) {
                dataRows.add(new Object[]{value});
            }
        }
    }

    /**
     * Extracts arguments from a @CsvSource annotation.
     */
    private void extractValuesFromCsvSource(CsvSource annotation, List<Object[]> dataRows) {
        // Default delimiter is comma; annotation.delimiter() returns '\0' when using default
        String delimiter;
        if (annotation.delimiterString() != null && !annotation.delimiterString().isEmpty()) {
            delimiter = annotation.delimiterString();
        } else if (annotation.delimiter() != '\0') {
            delimiter = String.valueOf(annotation.delimiter());
        } else {
            delimiter = ","; // Default delimiter
        }

        String nullValue = annotation.nullValues().length > 0 ? annotation.nullValues()[0] : null;
        String emptyValue = annotation.emptyValue();

        for (String line : annotation.value()) {
            String[] parts = line.split(delimiter, -1);
            Object[] row = new Object[parts.length];
            for (int i = 0; i < parts.length; i++) {
                String part = parts[i].trim();
                if (nullValue != null && part.equals(nullValue)) {
                    row[i] = null;
                } else if (emptyValue != null && part.equals(emptyValue)) {
                    row[i] = "";
                } else {
                    row[i] = part;
                }
            }
            dataRows.add(row);
        }
    }

    /**
     * Extracts arguments from a @EnumSource annotation.
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    private void extractValuesFromEnumSource(EnumSource annotation, List<Object[]> dataRows) {
        Class<? extends Enum<?>> enumClass = annotation.value();
        Enum<?>[] enumConstants = enumClass.getEnumConstants();

        String[] names = annotation.names();
        EnumSource.Mode mode = annotation.mode();

        for (Enum<?> enumConstant : enumConstants) {
            boolean include = shouldIncludeEnum(enumConstant, names, mode);
            if (include) {
                dataRows.add(new Object[]{enumConstant});
            }
        }
    }

    /**
     * Determines if an enum constant should be included based on the filter names and mode.
     */
    private boolean shouldIncludeEnum(Enum<?> enumConstant, String[] names, EnumSource.Mode mode) {
        if (names.length == 0) {
            return true; // No filter, include all
        }

        boolean matchesName = false;
        for (String name : names) {
            if (mode == EnumSource.Mode.MATCH_ALL || mode == EnumSource.Mode.MATCH_ANY) {
                // Pattern matching modes
                if (enumConstant.name().matches(name)) {
                    matchesName = true;
                    break;
                }
            } else {
                // Exact name matching
                if (enumConstant.name().equals(name)) {
                    matchesName = true;
                    break;
                }
            }
        }

        return switch (mode) {
            case INCLUDE, MATCH_ANY, MATCH_ALL, MATCH_NONE -> matchesName;
            case EXCLUDE -> !matchesName;
        };
    }

    /**
     * Extracts empty values based on the parameter type for @EmptySource.
     */
    private void extractValuesFromEmptySource(Method testMethod, List<Object[]> dataRows) {
        Parameter[] parameters = testMethod.getParameters();
        if (parameters.length > 0) {
            Class<?> paramType = parameters[0].getType();
            Object emptyValue = getEmptyValueForType(paramType);
            dataRows.add(new Object[]{emptyValue});
        }
    }

    /**
     * Extracts null and empty values for @NullAndEmptySource.
     */
    private void extractValuesFromNullAndEmptySource(Method testMethod, List<Object[]> dataRows) {
        // Add null first
        dataRows.add(new Object[]{null});

        // Then add empty value based on parameter type
        Parameter[] parameters = testMethod.getParameters();
        if (parameters.length > 0) {
            Class<?> paramType = parameters[0].getType();
            Object emptyValue = getEmptyValueForType(paramType);
            dataRows.add(new Object[]{emptyValue});
        }
    }

    /**
     * Gets an empty value for a given type.
     */
    private Object getEmptyValueForType(Class<?> type) {
        if (type == String.class) {
            return "";
        } else if (type == List.class || type.isAssignableFrom(ArrayList.class)) {
            return new ArrayList<>();
        } else if (type.isArray()) {
            return java.lang.reflect.Array.newInstance(type.getComponentType(), 0);
        } else if (type == java.util.Set.class) {
            return new java.util.HashSet<>();
        } else if (type == java.util.Map.class) {
            return new java.util.HashMap<>();
        }
        // Default to empty string for unknown types
        return "";
    }

    /**
     * Inner class representing a single test invocation context for a specific channel.
     */
    private static class ChannelInvocationContext implements TestTemplateInvocationContext {

        private final String channel;
        private final Object[] testData;
        private final Method testMethod;

        public ChannelInvocationContext(String channel, Object[] testData, Method testMethod) {
            this.channel = channel;
            this.testData = testData;
            this.testMethod = testMethod;
        }

        @Override
        public String getDisplayName(int invocationIndex) {
            String methodName = testMethod.getName();
            if (testData == null || testData.length == 0) {
                return methodName + " [Channel: " + channel + "]";
            } else {
                StringBuilder sb = new StringBuilder(methodName + " [Channel: " + channel);

                java.lang.reflect.Parameter[] parameters = testMethod.getParameters();
                int displayCount = Math.min(parameters.length, testData.length);

                for (int i = 0; i < displayCount; i++) {
                    String paramName = parameters[i].getName();
                    String paramValue = formatParameterValue(testData[i]);
                    sb.append(", ").append(paramName).append(": ").append(paramValue);
                }
                sb.append("]");
                return sb.toString();
            }
        }

        /**
         * Format a parameter value for display, making empty/whitespace strings more readable.
         */
        private String formatParameterValue(Object value) {
            if (value == null) {
                return "<null>";
            }

            if (value instanceof String) {
                String str = (String) value;
                if (str.isEmpty()) {
                    return "<empty>";
                }
                if (str.trim().isEmpty()) {
                    return "<whitespace>";
                }
            }

            return String.valueOf(value);
        }

        @Override
        public List<Extension> getAdditionalExtensions() {
            List<Extension> extensions = new ArrayList<>();
            extensions.add(new ChannelSetupExtension(channel));

            // Add TestDataParameterResolver if we have test data
            // (either from @ChannelArgumentsSource or extracted from @MethodSource)
            if (testData != null && testData.length > 0) {
                extensions.add(new TestDataParameterResolver(testData));
            }

            return extensions;
        }
    }

    /**
     * Extension that sets up the channel context before each test invocation.
     */
    private static class ChannelSetupExtension implements
            org.junit.jupiter.api.extension.BeforeEachCallback,
            org.junit.jupiter.api.extension.AfterEachCallback {

        private final String channel;

        public ChannelSetupExtension(String channel) {
            this.channel = channel;
        }

        @Override
        public void beforeEach(ExtensionContext context) {
            ChannelContext.set(channel);
        }

        @Override
        public void afterEach(ExtensionContext context) {
            ChannelContext.clear();
        }
    }

    /**
     * Parameter resolver that provides test data values to test method parameters.
     */
    private static class TestDataParameterResolver implements ParameterResolver {

        private final Object[] testData;

        public TestDataParameterResolver(Object[] testData) {
            this.testData = testData;
        }

        @Override
        public boolean supportsParameter(ParameterContext parameterContext, ExtensionContext extensionContext) {
            // Support parameters that are not injected by other means (like @BeforeEach dependencies)
            int index = parameterContext.getIndex();
            return index < testData.length;
        }

        @Override
        public Object resolveParameter(ParameterContext parameterContext, ExtensionContext extensionContext) {
            int index = parameterContext.getIndex();
            if (index < testData.length) {
                Object value = testData[index];
                Class<?> targetType = parameterContext.getParameter().getType();

                // If value is already the correct type (from provider), return it directly
                if (value != null && targetType.isAssignableFrom(value.getClass())) {
                    return value;
                }

                // Otherwise, if it's a string, try to convert it
                if (value instanceof String) {
                    return convertParameter((String) value, targetType);
                }

                // Return as-is for other types
                return value;
            }
            throw new IllegalStateException("No test data available for parameter index " + index);
        }

        private Object convertParameter(String value, Class<?> targetType) {
            if (targetType == String.class) {
                return value;
            } else if (targetType == int.class || targetType == Integer.class) {
                return Integer.parseInt(value);
            } else if (targetType == long.class || targetType == Long.class) {
                return Long.parseLong(value);
            } else if (targetType == boolean.class || targetType == Boolean.class) {
                return Boolean.parseBoolean(value);
            } else if (targetType == double.class || targetType == Double.class) {
                return Double.parseDouble(value);
            }
            // Default: return as string
            return value;
        }
    }

    /**
     * A test invocation context that disables the test.
     */
    private static class DisabledInvocationContext implements TestTemplateInvocationContext {
        private final String methodName;
        private final String reason;

        public DisabledInvocationContext(String methodName, String reason) {
            this.methodName = methodName;
            this.reason = reason;
        }

        @Override
        public String getDisplayName(int invocationIndex) {
            return methodName + "() [Skipped: " + reason + "]";
        }

        @Override
        public List<Extension> getAdditionalExtensions() {
            return List.of(new DisableTestExtension(reason));
        }
    }

    /**
     * Extension that disables a test with a reason.
     */
    private static class DisableTestExtension implements org.junit.jupiter.api.extension.ExecutionCondition {
        private final String reason;

        public DisableTestExtension(String reason) {
            this.reason = reason;
        }

        @Override
        public org.junit.jupiter.api.extension.ConditionEvaluationResult evaluateExecutionCondition(ExtensionContext context) {
            return org.junit.jupiter.api.extension.ConditionEvaluationResult.disabled(reason);
        }
    }
}

