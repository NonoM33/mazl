import type { FakePrice, FakeSubscription, RecordedRequest } from "./fake-stripe";

// Drives a fake Stripe running in another process (run-fake-stripe.ts).
export class FakeStripeClient {
  constructor(private readonly baseUrl: string) {}

  private async post(path: string, body: object): Promise<void> {
    const response = await fetch(`${this.baseUrl}${path}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
    if (!response.ok) throw new Error(`fake Stripe ${path} answered ${response.status}`);
  }

  setSubscription(subscription: FakeSubscription): Promise<void> {
    return this.post("/__test/subscription", subscription);
  }

  setPrice(price: FakePrice): Promise<void> {
    return this.post("/__test/price", price);
  }

  async requests(): Promise<RecordedRequest[]> {
    return (await (await fetch(`${this.baseUrl}/__test/requests`)).json()) as RecordedRequest[];
  }
}
