/**
 * Binds a `test.each`-style helper to a specific Playwright test object.
 * Merges Playwright fixture values with each test-case row so tests can destructure both.
 *
 * Usage:
 * ```typescript
 * const testEach = bindTestEach(test);
 *
 * testEach([{ quantity: 1 }, { quantity: 5 }])(
 *     'should handle quantity=$quantity',
 *     async ({ scenario, quantity }) => { ... }
 * );
 * ```
 */
export function bindTestEach(
    testObj: any,
) {
    return <TCase>(
        cases: ReadonlyArray<TCase>,
    ): ((name: string, fn: (args: any) => Promise<void>) => void) => {
        return (name: string, fn: (args: any) => Promise<void>): void => {
            const placeholderKeys = Array.from(name.matchAll(/\$(\w+)/g)).map((match) => match[1]);
            const uniquePlaceholderKeys = [...new Set(placeholderKeys)];

            cases.forEach((rawRow) => {
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

                const testName = name.replace(/\$(\w+)/g, (_: string, key: string) => {
                    const value = row[key];
                    if (typeof value === 'string') return value;
                    if (typeof value === 'number') return value.toString();
                    return '';
                });
                // Inject each row property as a Playwright fixture so we
                // never need rest-property syntax in the test callback.
                const rowFixtures: Record<string, any> = {};
                for (const [key, value] of Object.entries(row)) {
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
