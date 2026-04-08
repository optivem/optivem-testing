package com.optivem.testing;

import java.lang.annotation.*;

/**
 * Repeatable annotation to provide inline test arguments that will be combined with channel types.
 * Each @DataSource annotation represents one row of test arguments that will be
 * executed against all specified channels.
 * <p>
 * Example with inline values:
 * <pre>
 * &#64;TestTemplate
 * &#64;Channel({ChannelType.UI, ChannelType.API})
 * &#64;DataSource("3.5")
 * &#64;DataSource("lala")
 * void shouldRejectOrderWithNonIntegerQuantity(String nonIntegerQuantity) {
 *     // This test will run 4 times: UI with "3.5", UI with "lala", API with "3.5", API with "lala"
 * }
 * </pre>
 * <p>
 * Example with multiple parameters:
 * <pre>
 * &#64;TestTemplate
 * &#64;Channel({ChannelType.UI, ChannelType.API})
 * &#64;DataSource({"SKU123", "5", "US"})
 * &#64;DataSource({"SKU456", "10", "UK"})
 * void testOrder(String sku, String quantity, String country) {
 *     // Each annotation provides all 3 parameters
 * }
 * </pre>
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Repeatable(DataSource.Container.class)
public @interface DataSource {
    /**
     * The test argument values for this row.
     * @return array of test argument values
     */
    String[] value();

    /**
     * Additional channels this data row should also run on, beyond the base channels
     * declared in the method-level @Channel annotation.
     * When empty (default), the row runs only on the base channels.
     * <p>
     * Example:
     * <pre>
     * &#64;TestTemplate
     * &#64;Channel(ChannelType.API)
     * &#64;DataSource(value = {"20.00", "5", "100.00"}, also = ChannelType.UI)   // API + UI
     * &#64;DataSource({"10.00", "3", "30.00"})                                    // API only
     * &#64;DataSource({"15.50", "4", "62.00"})                                    // API only
     * void shouldPlaceOrderWithCorrectBasePrice(String unitPrice, String quantity, String basePrice) {
     *     // First row runs on API and UI, remaining rows run on API only
     * }
     * </pre>
     * @return additional channel types this row should also run on, or empty for base channels only
     */
    String[] also() default {};

    /**
     * Container annotation for repeated @DataSource annotations.
     */
    @Target({ElementType.METHOD})
    @Retention(RetentionPolicy.RUNTIME)
    @interface Container {
        /**
         * Container for multiple DataSource annotations.
         * @return array of DataSource annotations
         */
        DataSource[] value();
    }
}
