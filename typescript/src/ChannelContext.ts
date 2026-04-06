export class ChannelContext {
    private static channelThreadLocal: string | undefined;

    static set(channel: string): void {
        this.channelThreadLocal = channel;
    }

    static get(): string | undefined {
        return this.channelThreadLocal;
    }

    static clear(): void {
        this.channelThreadLocal = undefined;
    }
}
