package com.optivem.testing.channels;

import com.optivem.testing.Channel;
import com.optivem.testing.DataSource;
import com.optivem.testing.extensions.ChannelExtension;
import org.junit.jupiter.api.TestTemplate;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.provider.*;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for ChannelExtension to verify all argument sources work correctly
 * when combined with @Channel annotation.
 */
@ExtendWith(ChannelExtension.class)
public class ChannelExtensionTest {

    // Track test executions for verification
    private static final List<String> executedTests = new ArrayList<>();

    // ==========================================================================
    // @ValueSource Tests
    // ==========================================================================

    static Stream<Arguments> provideStringsForMethodSource() {
        return Stream.of(
                Arguments.of("apple"),
                Arguments.of("banana"),
                Arguments.of("cherry")
        );
    }

    static Stream<Arguments> provideMultipleArgumentsForMethodSource() {
        return Stream.of(
                Arguments.of("item1", 10, true),
                Arguments.of("item2", 20, false),
                Arguments.of("item3", 30, true)
        );
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(strings = {"hello", "world", "test"})
    void shouldSupportValueSourceWithStrings(String value) {
        assertNotNull(value, "Value should not be null");
        assertTrue(value.length() > 0, "Value should not be empty");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(ints = {1, 2, 3, 100})
    void shouldSupportValueSourceWithInts(int value) {
        assertTrue(value > 0, "Value should be positive");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(longs = {100L, 200L, 300L})
    void shouldSupportValueSourceWithLongs(long value) {
        assertTrue(value >= 100L, "Value should be >= 100");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(doubles = {1.5, 2.5, 3.5})
    void shouldSupportValueSourceWithDoubles(double value) {
        assertTrue(value > 1.0, "Value should be > 1.0");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(floats = {1.1f, 2.2f, 3.3f})
    void shouldSupportValueSourceWithFloats(float value) {
        assertTrue(value > 1.0f, "Value should be > 1.0f");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(shorts = {10, 20, 30})
    void shouldSupportValueSourceWithShorts(short value) {
        assertTrue(value >= 10, "Value should be >= 10");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(bytes = {1, 2, 3})
    void shouldSupportValueSourceWithBytes(byte value) {
        assertTrue(value > 0, "Value should be positive");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(chars = {'a', 'b', 'c'})
    void shouldSupportValueSourceWithChars(char value) {
        assertTrue(Character.isLetter(value), "Value should be a letter");
    }

    // ==========================================================================
    // @MethodSource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(booleans = {true, false})
    void shouldSupportValueSourceWithBooleans(boolean value) {
        // Just verify it runs - boolean is either true or false
        assertTrue(value || !value, "Value should be true or false");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ValueSource(classes = {String.class, Integer.class, List.class})
    void shouldSupportValueSourceWithClasses(Class<?> value) {
        assertNotNull(value, "Class should not be null");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @MethodSource("provideStringsForMethodSource")
    void shouldSupportMethodSourceWithSingleArgument(String fruit) {
        assertNotNull(fruit, "Fruit should not be null");
        assertTrue(fruit.length() > 0, "Fruit should not be empty");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @MethodSource("provideMultipleArgumentsForMethodSource")
    void shouldSupportMethodSourceWithMultipleArguments(String name, int quantity, boolean active) {
        assertNotNull(name, "Name should not be null");
        assertTrue(quantity > 0, "Quantity should be positive");
        // active can be true or false
    }

    // ==========================================================================
    // @ArgumentsSource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @ArgumentsSource(TestArgumentsProvider.class)
    void shouldSupportArgumentsSource(String name, int value) {
        assertNotNull(name, "Name should not be null");
        assertTrue(value >= 100, "Value should be >= 100");
    }

    // ==========================================================================
    // @CsvSource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @CsvSource({
            "apple, 1",
            "banana, 2",
            "cherry, 3"
    })
    void shouldSupportCsvSource(String fruit, String quantity) {
        assertNotNull(fruit, "Fruit should not be null");
        assertNotNull(quantity, "Quantity should not be null");
        int qty = Integer.parseInt(quantity);
        assertTrue(qty > 0, "Quantity should be positive");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @CsvSource({
            "John, Doe, 30",
            "Jane, Smith, 25",
            "Bob, Johnson, 40"
    })
    void shouldSupportCsvSourceWithMultipleColumns(String firstName, String lastName, String age) {
        assertNotNull(firstName, "First name should not be null");
        assertNotNull(lastName, "Last name should not be null");
        int ageValue = Integer.parseInt(age);
        assertTrue(ageValue > 0, "Age should be positive");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @CsvSource(value = {
            "apple:1:true",
            "banana:2:false",
            "cherry:3:true"
    }, delimiter = ':')
    void shouldSupportCsvSourceWithCustomDelimiter(String fruit, String quantity, String inStock) {
        assertNotNull(fruit, "Fruit should not be null");
        assertNotNull(quantity, "Quantity should not be null");
        assertNotNull(inStock, "InStock should not be null");
        int qty = Integer.parseInt(quantity);
        assertTrue(qty > 0, "Quantity should be positive");
    }

    // ==========================================================================
    // @EnumSource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @EnumSource(TestStatus.class)
    void shouldSupportEnumSource(TestStatus status) {
        assertNotNull(status, "Status should not be null");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @EnumSource(value = TestStatus.class, names = {"PENDING", "ACTIVE"})
    void shouldSupportEnumSourceWithNameFilter(TestStatus status) {
        assertNotNull(status, "Status should not be null");
        assertTrue(status == TestStatus.PENDING || status == TestStatus.ACTIVE,
                "Status should be PENDING or ACTIVE");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @EnumSource(value = TestStatus.class, names = {"CANCELLED"}, mode = EnumSource.Mode.EXCLUDE)
    void shouldSupportEnumSourceWithExcludeMode(TestStatus status) {
        assertNotNull(status, "Status should not be null");
        assertNotEquals(TestStatus.CANCELLED, status, "Status should not be CANCELLED");
    }

    // ==========================================================================
    // @NullSource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @NullSource
    void shouldSupportNullSource(String value) {
        assertNull(value, "Value should be null");
    }

    // ==========================================================================
    // @EmptySource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @EmptySource
    void shouldSupportEmptySourceForString(String value) {
        assertNotNull(value, "Value should not be null");
        assertTrue(value.isEmpty(), "Value should be empty");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @EmptySource
    void shouldSupportEmptySourceForList(List<String> value) {
        assertNotNull(value, "Value should not be null");
        assertTrue(value.isEmpty(), "Value should be empty");
    }

    // ==========================================================================
    // @NullAndEmptySource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @NullAndEmptySource
    void shouldSupportNullAndEmptySource(String value) {
        assertTrue(value == null || value.isEmpty(), "Value should be null or empty");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @NullAndEmptySource
    @ValueSource(strings = {"   ", "\t", "\n"})
    void shouldSupportNullAndEmptySourceCombinedWithValueSource(String value) {
        assertTrue(value == null || value.trim().isEmpty(), "Value should be null, empty, or blank");
    }

    // ==========================================================================
    // Custom @DataSource Tests
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @DataSource("singleValue")
    void shouldSupportDataSourceWithSingleValue(String value) {
        assertEquals("singleValue", value, "Value should match");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @DataSource({"value1", "100", "true"})
    void shouldSupportDataSourceWithMultipleValues(String name, String quantity, String active) {
        assertEquals("value1", name, "Name should match");
        assertEquals("100", quantity, "Quantity should match");
        assertEquals("true", active, "Active should match");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @DataSource("first")
    @DataSource("second")
    @DataSource("third")
    void shouldSupportMultipleDataSourceAnnotations(String value) {
        assertNotNull(value, "Value should not be null");
        assertTrue(value.equals("first") || value.equals("second") || value.equals("third"),
                "Value should be first, second, or third");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    @DataSource({"order-001", "Order order-001 does not exist."})
    @DataSource({"order-002", "Order order-002 does not exist."})
    @DataSource({"order-003", "Order order-003 does not exist."})
    void shouldSupportMultipleDataSourceAnnotationsWithMultipleValues(String orderNumber, String expectedError) {
        assertNotNull(orderNumber, "Order number should not be null");
        assertNotNull(expectedError, "Expected error should not be null");
        assertTrue(expectedError.contains(orderNumber), "Error message should contain order number");
    }

    // ==========================================================================
    // No Data Source Tests (just channels)
    // ==========================================================================

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A, TestChannel.CHANNEL_B})
    void shouldRunForEachChannelWithoutDataSource() {
        // This test should run twice - once for each channel
        assertTrue(true, "Test should run for each channel");
    }

    @TestTemplate
    @Channel({TestChannel.CHANNEL_A})
    void shouldRunForSingleChannel() {
        // This test should run once - for CHANNEL_A only
        assertTrue(true, "Test should run for single channel");
    }
}

