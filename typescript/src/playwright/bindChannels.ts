import { forChannels as sharedForChannels } from '../channel.js';

/**
 * Binds channel helpers (forChannels) to a specific Playwright test object.
 *
 * Usage:
 * ```typescript
 * const test = base.extend<{ app: MyApp }>({ ... });
 * const { forChannels } = bindChannels(test);
 *
 * forChannels('UI', 'API')(() => {
 *     test('my test', async ({ app }) => { ... });
 * });
 * ```
 */
export function bindChannels(testObj: {
    describe: (name: string, callback: () => void) => void;
    beforeEach: (callback: () => void | Promise<void>) => void;
    afterEach: (callback: () => void | Promise<void>) => void;
}) {
    const forChannels = (...channelTypes: string[]): ((block: () => void) => void) => {
        return sharedForChannels(
            {
                describe: (name, callback) => testObj.describe(name, callback),
                beforeEach: (callback) => testObj.beforeEach(callback),
                afterEach: (callback) => testObj.afterEach(callback),
            },
            ...channelTypes,
        );
    };

    return { forChannels };
}
