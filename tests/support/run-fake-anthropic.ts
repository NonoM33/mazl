// Standalone fake Anthropic for the integration tests: FAKE_ANTHROPIC_PORT.
import { createFakeAnthropic } from "./fake-anthropic";

const { server } = createFakeAnthropic(Number(process.env.FAKE_ANTHROPIC_PORT ?? 12115));
console.log(`fake Anthropic listening on ${server.url}`);
