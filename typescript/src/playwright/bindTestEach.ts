import { getRegistrationChannel } from '../channel.js';

/**
 * Binds a `test.each`-style helper to a specific Playwright test object.
 * Merges Playwright fixture values with each test-case row so tests can destructure both.
 *
 * Supports optional per-row additional channels: if a test case object has an `also`
 * property (string or string[]), the row will also be registered for those channels
 * beyond the base channels from forChannels.
 *
 * Supports `alsoFirstRowChannels`: additional channels that only the first data row
 * should run on. All other rows run only on the base channels.
 *
 * Usage:
 * ```typescript
 * // Per-row also:
 * const testEach = bindTestEach(test, ['API']);
 * testEach([
 *     { unitPrice: '20.00', quantity: '5', basePrice: '100.00', also: ['UI'] },   // API + UI
 *     { unitPrice: '10.00', quantity: '3', basePrice: '30.00' },                   // API only
 * ])('should place order ...', async ({ scenario, unitPrice }) => { ... });
 *
 * // alsoFirstRow (first row gets extra channels automatically):
 * const testEach = bindTestEach(test, ['API'], ['UI']);
 * testEach([
 *     { unitPrice: '20.00', quantity: '5', basePrice: '100.00' },   // API + UI (first row)
 *     { unitPrice: '10.00', quantity: '3', basePrice: '30.00' },    // API only
 * ])('should place order ...', async ({ scenario, unitPrice }) => { ... });
 * ```
 */
export function bindTestEach(
    testObj: any,
    baseChannels?: string[],
    alsoFirstRowChannels?: string[],
) {
    return <TCase>(
        cases: ReadonlyArray<TCase>,
    ): ((name: string, fn: (args: any) => Promise<void>) => void) => {
        return (name: string, fn: (args: any) => Promise<void>): void => {
            const placeholderKeys = Array.from(name.matchAll(/\$(\w+)/g)).map((match) => match[1]);
            const uniquePlaceholderKeys = [...new Set(placeholderKeys)];

            cases.forEach((rawRow, rowIndex) => {
                let row: Record<string, unknown>;
                if (rawRow != null && typeof rawRow === 'object' && !Array.isArray(rawRow)) {
                    row = rawRow as Record<string, unknown>;
                } else if (uniquePlaceholderKeys.length === 1) {
                    row = { [uniquePlaceholderKeys[0]]: rawRow };
                } else if (uniquePlaceholderKeys.length === 0) {
                    row = { value: rawRow };
                } else {
                    throw new Error(
                        `bindTestEach: scalar rows require exactly one placeholder in test name, but got ${uniquePlaceholderKeys.length}`,
                    );
                }

                // Channel filtering: skip rows that shouldn't run on the current channel.
                const currentChannel = getRegistrationChannel();
                if (currentChannel != null && baseChannels != null) {
                    const rowAlso = row['also'];
                    const alsoList = typeof rowAlso === 'string' ? [rowAlso]
                        : Array.isArray(rowAlso) ? rowAlso as string[]
                        : [];
                    const isBaseChannel = baseChannels.includes(currentChannel);
                    const isAlsoChannel = alsoList.includes(currentChannel);
                    const isAlsoFirstRow = rowIndex === 0
                        && alsoFirstRowChannels?.includes(currentChannel) === true;
                    if (!isBaseChannel && !isAlsoChannel && !isAlsoFirstRow) {
                        return; // Skip this row for this channel
                    }
                }

                // Exclude 'also' from the row data passed to the test
                const { also: _also, ...dataRow } = row;

                const testName = name.replace(/\$(\w+)/g, (_: string, key: string) => {
                    const value = dataRow[key];
                    if (typeof value === 'string') return value;
                    if (typeof value === 'number') return value.toString();
                    return '';
                });
                // Inject each row property as a Playwright fixture so we
                // never need rest-property syntax in the test callback.
                const rowFixtures: Record<string, any> = {};
                for (const [key, value] of Object.entries(dataRow)) {
                    rowFixtures[key] = async ({}: any, use: any) => {
                        await use(value);
                    };
                }
                const extendedTest = testObj.extend(rowFixtures);
                extendedTest(testName, fn);
            });
        };
    };
}
