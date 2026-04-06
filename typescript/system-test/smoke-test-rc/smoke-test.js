import { ChannelContext, bindChannels, bindTestEach } from "@optivem/optivem-testing";

// Smoke test: verify the published package can be loaded and key exports exist
if (typeof ChannelContext.set !== "function") {
  throw new Error("ChannelContext.set is not a function");
}

if (typeof bindChannels !== "function") {
  throw new Error("bindChannels is not a function");
}

if (typeof bindTestEach !== "function") {
  throw new Error("bindTestEach is not a function");
}

console.log("✅ Package loaded and key exports verified successfully");
