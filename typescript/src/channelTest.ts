import { test as base } from '@playwright/test';

interface Closeable {
    close?: () => void | Promise<void>;
}

async function tryClose(obj: unknown): Promise<void> {
    if (obj != null && typeof (obj as Closeable).close === 'function') {
        await (obj as Closeable).close!();
    }
}

/**
 * Runs the same test for each specified channel type.
 *
 * Supports both simple smoke tests and E2E tests with multiple fixtures.
 *
 * Example usage for smoke tests:
 * ```typescript
 * channelTest([ChannelType.UI, ChannelType.API], shopDriverFactory, 'driver', {}, 'should be able to go to shop', async ({ driver }) => {
 *     const result = await driver.goToShop();
 *     expect(result).toBeSuccess();
 * });
 * ```
 *
 * Example usage for E2E tests with additional fixtures:
 * ```typescript
 * const additionalFixtures = {
 *     erpApiDriver: () => DriverFactory.createErpApiDriver(),
 *     taxApiDriver: () => DriverFactory.createTaxApiDriver()
 * };
 * channelTest([ChannelType.UI, ChannelType.API], shopDriverFactory, 'driver', additionalFixtures, 'should place order', async ({ driver, erpApiDriver }) => {
 *     await erpApiDriver.createProduct('SKU-123', '20.00');
 *     const result = await driver.placeOrder('SKU-123', '5', 'US');
 *     expect(result).toBeSuccess();
 * });
 * ```
 */
export function channelTest(
    channelTypes: string[],
    driverFactory: (channelType: string) => any,
    fixtureName: string,
    additionalFixtures: Record<string, () => any>,
    testName: string,
    testFn: (fixtures: any) => Promise<void>
) {
    // Create fixtures from the additional fixtures map
    const baseFixtures: any = {};
    for (const [name, factory] of Object.entries(additionalFixtures)) {
        baseFixtures[name] = async ({}, use: any) => {
            const driver = factory();
            await use(driver);
            await tryClose(driver);
        };
    }

    // Base test with all additional fixtures
    const testBase = base.extend<any>(baseFixtures);

    for (const channelType of channelTypes) {
        const testWithChannel = testBase.extend<any>({
            [fixtureName]: async ({}, use: any) => {
                const driver = driverFactory(channelType);
                await use(driver);
                await tryClose(driver);
            },
        });

        testWithChannel.describe(`[${channelType} Channel]`, () => {
            testWithChannel(testName, testFn);
        });
    }
}
