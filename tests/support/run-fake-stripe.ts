import { FakeStripe } from "./fake-stripe";

// Standalone fake Stripe for the integration tests: FAKE_STRIPE_PORT (default 12113).
const port = Number(process.env.FAKE_STRIPE_PORT ?? 12113);
const fake = new FakeStripe().start(port);
console.log(`fake Stripe listening on ${fake.url}`);
