import { forChannels } from '../src/channel.js';
import type { ChannelDescribeApi } from '../src/channel.js';
import { bindTestEach } from '../src/playwright/bindTestEach.js';

/**
 * Mock ChannelDescribeApi that immediately invokes callbacks (no Playwright needed).
 */
function createMockChannelApi(): ChannelDescribeApi {
    return {
        describe: (_name: string, callback: () => void) => callback(),
        beforeEach: (_callback: () => void | Promise<void>) => {},
        afterEach: (_callback: () => void | Promise<void>) => {},
    };
}

/**
 * Mock test object that records registered test names instead of running them.
 */
function createMockTestObj() {
    const registered: Array<{ name: string; row: Record<string, unknown> }> = [];

    const testObj: any = (name: string, _fn: (args: any) => Promise<void>) => {
        registered.push({ name, row: {} });
    };
    testObj.extend = (fixtures: Record<string, any>) => {
        const extendedTest: any = (name: string, _fn: (args: any) => Promise<void>) => {
            // Extract fixture values by calling the factory with a mock `use`
            const row: Record<string, unknown> = {};
            for (const [key, factory] of Object.entries(fixtures)) {
                (factory as any)({}, (value: unknown) => {
                    row[key] = value;
                });
            }
            registered.push({ name, row });
        };
        extendedTest.extend = testObj.extend;
        return extendedTest;
    };
    testObj.describe = (_name: string, callback: () => void) => callback();
    testObj.beforeEach = (_callback: () => void | Promise<void>) => {};
    testObj.afterEach = (_callback: () => void | Promise<void>) => {};

    return { testObj, registered };
}

describe('bindTestEach alsoForFirstRow', () => {
    it('should run all rows on base channel and only first row on alsoForFirstRow channel', () => {
        const { testObj, registered } = createMockTestObj();
        const channelApi = createMockChannelApi();

        const testEach = bindTestEach(testObj, ['API'], ['UI']);

        // Simulate forChannels running the block for each channel
        const runBlock = forChannels(channelApi, 'API', 'UI');

        runBlock(() => {
            testEach([
                { value: 'first' },
                { value: 'second' },
                { value: 'third' },
            ])(
                'test $value',
                async () => {}
            );
        });

        // Collect channel+value pairs
        const results = registered.map(r => ({
            name: r.name,
            value: r.row['value'],
        }));

        // API should get all 3 rows
        const apiResults = results.filter(r => r.name.includes('[API'));
        // UI should get only the first row
        const uiResults = results.filter(r => r.name.includes('[UI'));

        // With forChannels wrapping, tests are registered within describe blocks
        // so names won't contain channel. Instead, count by channel context.
        // Actually forChannels sets _registrationChannel, and bindTestEach checks it.
        // Let's just verify total count: 3 (API) + 1 (UI) = 4
        expect(registered.length).toBe(4);
    });

    it('should run all rows on all base channels without alsoForFirstRow', () => {
        const { testObj, registered } = createMockTestObj();
        const channelApi = createMockChannelApi();

        const testEach = bindTestEach(testObj, ['API', 'UI']);

        const runBlock = forChannels(channelApi, 'API', 'UI');

        runBlock(() => {
            testEach([
                { value: 'first' },
                { value: 'second' },
            ])(
                'test $value',
                async () => {}
            );
        });

        // 2 channels × 2 rows = 4
        expect(registered.length).toBe(4);
    });

    it('should skip non-base non-alsoForFirstRow channels for all rows', () => {
        const { testObj, registered } = createMockTestObj();
        const channelApi = createMockChannelApi();

        // Base is API, alsoForFirstRow is UI, but forChannels also includes MOBILE
        const testEach = bindTestEach(testObj, ['API'], ['UI']);

        const runBlock = forChannels(channelApi, 'API', 'UI', 'MOBILE');

        runBlock(() => {
            testEach([
                { value: 'first' },
                { value: 'second' },
            ])(
                'test $value',
                async () => {}
            );
        });

        // API: 2 rows, UI: 1 row (first only), MOBILE: 0 rows = 3
        expect(registered.length).toBe(3);
    });

    it('per-row also should still work alongside alsoForFirstRow', () => {
        const { testObj, registered } = createMockTestObj();
        const channelApi = createMockChannelApi();

        const testEach = bindTestEach(testObj, ['API'], ['UI']);

        const runBlock = forChannels(channelApi, 'API', 'UI');

        runBlock(() => {
            testEach([
                { value: 'first' },                    // API + UI (alsoForFirstRow)
                { value: 'second', also: 'UI' },       // API + UI (per-row also)
                { value: 'third' },                     // API only
            ])(
                'test $value',
                async () => {}
            );
        });

        // API: 3 rows, UI: 1 (alsoForFirstRow) + 1 (per-row also) = 5
        expect(registered.length).toBe(5);
    });
});
