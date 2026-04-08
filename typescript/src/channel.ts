import { ChannelContext } from './ChannelContext.js';

type ChannelTestFn<TFixtures> = (fixtures: TFixtures) => Promise<void>;
type RegisterChannel<TFixtures> = (
    testName: string,
    testFn: ChannelTestFn<TFixtures>
) => void;

type DescribeBlock = (name: string, callback: () => void) => void;
type Hook = (callback: () => void | Promise<void>) => void;

export interface ChannelDescribeApi {
    describe: DescribeBlock;
    beforeEach: Hook;
    afterEach: Hook;
}

export function registerChannel<TFixtures>(
    registerTest: RegisterChannel<TFixtures>,
    channelTypes: string[],
    testName: string,
    testFn: ChannelTestFn<TFixtures>
): void {
    const channelEnv = process.env.CHANNEL;
    const channelsToRun =
        channelEnv != null && channelEnv !== ''
            ? channelTypes.filter((c) => c === channelEnv)
            : channelTypes;

    for (const channel of channelsToRun) {
        registerTest(`[${channel} Channel] ${testName}`, async (fixtures) => {
            try {
                ChannelContext.set(channel);
                await testFn(fixtures);
            } finally {
                ChannelContext.clear();
            }
        });
    }
}

export function defineChannel<TFixtures>(
    registerTest: RegisterChannel<TFixtures>,
    ...channelTypes: string[]
): (testName: string, testFn: ChannelTestFn<TFixtures>) => void {
    return (testName: string, testFn: ChannelTestFn<TFixtures>) => {
        registerChannel(registerTest, channelTypes, testName, testFn);
    };
}

/**
 * Module-level variable holding the channel currently being registered.
 * Set during describe-block registration in forChannels, so that helpers
 * like bindTestEach can filter test cases per channel at registration time.
 */
let _registrationChannel: string | null = null;

/**
 * Returns the channel type currently being registered inside a forChannels block,
 * or null if called outside of registration.
 */
export function getRegistrationChannel(): string | null {
    return _registrationChannel;
}

export function forChannels(
    channelApi: ChannelDescribeApi,
    ...channelTypes: string[]
): (block: () => void) => void {
    return (block: () => void) => {
        const channelEnv = process.env.CHANNEL;
        const channelsToRun =
            channelEnv != null && channelEnv !== ''
                ? channelTypes.filter((c) => c === channelEnv)
                : channelTypes;

        for (const channel of channelsToRun) {
            channelApi.describe(`[${channel} Channel]`, () => {
                channelApi.beforeEach(() => {
                    ChannelContext.set(channel);
                });
                channelApi.afterEach(() => {
                    ChannelContext.clear();
                });
                _registrationChannel = channel;
                block();
                _registrationChannel = null;
            });
        }
    };
}
