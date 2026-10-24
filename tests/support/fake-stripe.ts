// A fake of the Stripe REST API that answers the REAL paths the SDK calls, with
// JSON shaped like the Stripe objects, and records the form-encoded parameters
// it receives. Used by the adapter unit tests and, as a standalone process
// (run-fake-stripe.ts), by the integration and end-to-end tests.
// Control routes under /__test let another process arrange the state.

export interface RecordedRequest {
  readonly method: string;
  readonly path: string;
  readonly params: Readonly<Record<string, string>>;
  readonly headers: Readonly<Record<string, string>>;
}

export interface FakePrice {
  readonly id: string;
  readonly unit_amount: number | null;
  readonly tax_behavior: "inclusive" | "exclusive" | "unspecified";
  readonly currency?: string;
}

export interface FakeSubscription {
  readonly id: string;
  readonly customer: string;
  readonly price: string;
  status: string;
  readonly current_period_end: number;
  readonly start_date?: number;
  readonly cancel_at_period_end?: boolean;
  readonly metadata?: Readonly<Record<string, string>>;
}

export const FAKE_PRICES: readonly FakePrice[] = [
  { id: "price_test_plus_1m", unit_amount: 999, tax_behavior: "inclusive" },
  { id: "price_test_plus_3m", unit_amount: 2499, tax_behavior: "inclusive" },
  { id: "price_test_plus_6m", unit_amount: 4499, tax_behavior: "inclusive" },
  { id: "price_test_plus_12m", unit_amount: 7999, tax_behavior: "inclusive" },
  { id: "price_test_boost_1", unit_amount: 199, tax_behavior: "inclusive" },
  { id: "price_test_boost_3", unit_amount: 499, tax_behavior: "inclusive" },
  { id: "price_test_superlikes_5", unit_amount: 399, tax_behavior: "inclusive" },
  { id: "price_test_superlikes_15", unit_amount: 999, tax_behavior: "inclusive" },
];

// The STRIPE_PRICE_* variables that point the server at FAKE_PRICES.
export const FAKE_PRICE_ENV: Readonly<Record<string, string>> = {
  STRIPE_PRICE_PLUS_1M: "price_test_plus_1m",
  STRIPE_PRICE_PLUS_3M: "price_test_plus_3m",
  STRIPE_PRICE_PLUS_6M: "price_test_plus_6m",
  STRIPE_PRICE_PLUS_12M: "price_test_plus_12m",
  STRIPE_PRICE_BOOST_1: "price_test_boost_1",
  STRIPE_PRICE_BOOST_3: "price_test_boost_3",
  STRIPE_PRICE_SUPERLIKES_5: "price_test_superlikes_5",
  STRIPE_PRICE_SUPERLIKES_15: "price_test_superlikes_15",
};

function stripeError(status: number, code: string, message: string): Response {
  return Response.json({ error: { type: "invalid_request_error", code, message } }, { status });
}

function priceObject(price: FakePrice): Record<string, unknown> {
  return {
    id: price.id,
    object: "price",
    active: true,
    currency: price.currency ?? "eur",
    unit_amount: price.unit_amount,
    tax_behavior: price.tax_behavior,
    type: "one_time",
  };
}

function subscriptionObject(sub: FakeSubscription): Record<string, unknown> {
  return {
    id: sub.id,
    object: "subscription",
    customer: sub.customer,
    status: sub.status,
    cancel_at_period_end: sub.cancel_at_period_end ?? false,
    start_date: sub.start_date ?? sub.current_period_end - 30 * 86400,
    metadata: sub.metadata ?? {},
    items: {
      object: "list",
      has_more: false,
      url: `/v1/subscription_items?subscription=${sub.id}`,
      data: [
        {
          id: `si_${sub.id}`,
          object: "subscription_item",
          current_period_start: sub.current_period_end - 30 * 86400,
          current_period_end: sub.current_period_end,
          quantity: 1,
          price: { id: sub.price, object: "price" },
        },
      ],
    },
  };
}

export class FakeStripe {
  readonly requests: RecordedRequest[] = [];
  readonly prices = new Map<string, FakePrice>(FAKE_PRICES.map((price) => [price.id, price]));
  readonly subscriptions = new Map<string, FakeSubscription>();
  private server: ReturnType<typeof Bun.serve> | undefined;
  private counter = 0;

  get url(): string {
    if (this.server === undefined) throw new Error("fake Stripe is not started");
    return `http://127.0.0.1:${this.server.port}`;
  }

  start(port = 0): this {
    this.server = Bun.serve({ port, hostname: "127.0.0.1", fetch: (request) => this.handle(request) });
    return this;
  }

  stop(): void {
    void this.server?.stop(true);
  }

  requestsTo(method: string, path: string): RecordedRequest[] {
    return this.requests.filter((request) => request.method === method && request.path === path);
  }

  private nextId(prefix: string): string {
    // Unique across runs, like Stripe's ids: a counter restarting at 1 would
    // collide with customers stored by a previous run in the same database.
    this.counter += 1;
    return `${prefix}_fake_${this.counter}_${crypto.randomUUID().slice(0, 8)}`;
  }

  private async handle(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const params: Record<string, string> = Object.fromEntries(url.searchParams);
    if (request.method !== "GET" && request.method !== "DELETE" && request.headers.get("content-type")?.includes("form") === true) {
      Object.assign(params, Object.fromEntries(new URLSearchParams(await request.text())));
    }
    if (url.pathname.startsWith("/__test/")) return await this.control(request, url);
    this.requests.push({ method: request.method, path: url.pathname, params, headers: Object.fromEntries(request.headers) });
    return this.route(request.method, url.pathname, params);
  }

  private route(method: string, path: string, params: Record<string, string>): Response {
    if (method === "POST" && path === "/v1/customers") {
      return Response.json({ id: this.nextId("cus"), object: "customer", email: params.email ?? null, metadata: { user_id: params["metadata[user_id]"] ?? "" } });
    }
    if (method === "POST" && path === "/v1/checkout/sessions") {
      const id = this.nextId("cs_test");
      return Response.json({
        id,
        object: "checkout.session",
        mode: params.mode,
        customer: params.customer,
        client_reference_id: params.client_reference_id,
        url: `https://checkout.stripe.test/c/pay/${id}`,
      });
    }
    if (method === "POST" && path === "/v1/billing_portal/sessions") {
      const id = this.nextId("bps");
      return Response.json({ id, object: "billing_portal.session", customer: params.customer, return_url: params.return_url, url: `https://billing.stripe.test/p/session/${id}` });
    }
    return this.routeById(method, path);
  }

  private routeById(method: string, path: string): Response {
    const [, , resource, id] = path.split("/");
    if (id === undefined) return stripeError(404, "resource_missing", `Unrecognized request URL (${method} ${path})`);
    if (resource === "prices" && method === "GET") {
      const price = this.prices.get(id);
      return price === undefined ? stripeError(404, "resource_missing", `No such price: '${id}'`) : Response.json(priceObject(price));
    }
    if (resource === "subscriptions") return this.routeSubscription(method, id);
    return stripeError(404, "resource_missing", `Unrecognized request URL (${method} ${path})`);
  }

  private routeSubscription(method: string, id: string): Response {
    const sub = this.subscriptions.get(id);
    if (sub === undefined) return stripeError(404, "resource_missing", `No such subscription: '${id}'`);
    if (method === "DELETE") sub.status = "canceled";
    else if (method !== "GET") return stripeError(405, "method_not_allowed", method);
    return Response.json(subscriptionObject(sub));
  }

  private async control(request: Request, url: URL): Promise<Response> {
    if (url.pathname === "/__test/requests") return Response.json(this.requests);
    const body = (await request.json()) as Record<string, unknown>;
    if (url.pathname === "/__test/subscription") {
      const sub = body as unknown as FakeSubscription;
      this.subscriptions.set(sub.id, sub);
    } else if (url.pathname === "/__test/price") {
      const price = body as unknown as FakePrice;
      this.prices.set(price.id, price);
    } else {
      return new Response("unknown control route", { status: 404 });
    }
    return Response.json({ ok: true });
  }
}
