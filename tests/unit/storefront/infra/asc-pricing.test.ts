import { describe, expect, test } from "bun:test";
import {
  AscApiError,
  AscNetworkError,
  OfferCodeError,
  PriceChangeError,
  UnknownProductError,
  UnsupportedProductError,
} from "../../../../src/features/storefront/infra/app-store-connect";
import { APP, fixture, GROUP, FakeAsc, NOW, pricingWith, SUB, SUB_LOOKUP } from "./asc-fake";

interface Doc {
  data: Record<string, any>[];
  included?: Record<string, any>[];
  links?: Record<string, string>;
}
const doc = (name: string): Doc => fixture(name) as Doc;
const territoryOf = (r: Record<string, any>): string => r.relationships.territory.data.id;

function onlyTerritories(d: Doc, keep: string[]): Doc {
  return { ...d, data: d.data.filter((r) => keep.includes(territoryOf(r))), included: d.included?.filter((i) => i.type !== "territories" || keep.includes(i.id)) };
}

const PRICES_5 = `/v1/subscriptions/${SUB}/prices?include=subscriptionPricePoint,territory&limit=200&filter[territory]=FRA,USA,GBR,ISR,CAN`;
const PRICES_ALL = `/v1/subscriptions/${SUB}/prices?include=subscriptionPricePoint,territory&limit=200`;
const PRICES_FRA = `${PRICES_ALL}&filter[territory]=FRA`;
const POINTS_FRA = `/v1/subscriptions/${SUB}/pricePoints?filter[territory]=FRA&limit=200`;
const POINTS_FRA_NEXT = `/v1/subscriptions/${SUB}/pricePoints?filter[territory]=FRA&cursor=AMg&limit=200`;
const point = (page: string, price: string): string => doc(page).data.find((p) => p.attributes.customerPrice === price)!.id;
const eq = (id: string): string => `/v1/subscriptionPricePoints/${id}/equalizations?include=territory&limit=200`;

function withSubscription(fake: FakeAsc): FakeAsc {
  return fake.get(SUB_LOOKUP, doc("subscription-3m"));
}

describe("currentPrices", () => {
  test("reads the subscription price of each territory, with its currency", async () => {
    const fake = withSubscription(new FakeAsc()).get(PRICES_5, doc("subscription-prices-5-territories"));
    const prices = await pricingWith(fake).currentPrices("com.mazl.app.plus.3m", ["FRA", "USA", "GBR", "ISR", "CAN"]);
    expect(prices).toEqual([
      { territory: "FRA", currency: "EUR", customerPrice: "44.99" },
      { territory: "USA", currency: "USD", customerPrice: "49.99" },
      { territory: "GBR", currency: "GBP", customerPrice: "39.99" },
      { territory: "ISR", currency: "ILS", customerPrice: "119.9" },
      { territory: "CAN", currency: "CAD", customerPrice: "49.99" },
    ]);
    expect(fake.unexpected).toEqual([]);
    for (const call of fake.calls) expect(call.headers.authorization).toMatch(/^Bearer [\w-]+\.[\w-]+\.[\w-]+$/);
  });

  test("the price in force is the latest one whose start date has passed", async () => {
    const base = onlyTerritories(doc("subscription-prices-5-territories"), ["FRA"]);
    const future = structuredClone(base.data[0]!);
    future.id = "future";
    future.attributes.startDate = "2026-12-01";
    future.relationships.subscriptionPricePoint.data.id = "pp-future";
    const past = structuredClone(base.data[0]!);
    past.id = "past";
    past.attributes.startDate = "2026-10-15";
    past.relationships.subscriptionPricePoint.data.id = "pp-past";
    const points = [
      { type: "subscriptionPricePoints", id: "pp-future", attributes: { customerPrice: "59.99", proceeds: "1", proceedsYear2: "1" } },
      { type: "subscriptionPricePoints", id: "pp-past", attributes: { customerPrice: "49.99", proceeds: "1", proceedsYear2: "1" } },
    ];
    const fake = withSubscription(new FakeAsc()).get(`${PRICES_ALL}&filter[territory]=FRA`, { data: [...base.data, future, past], included: [...base.included!, ...points] });
    const [price] = await pricingWith(fake).currentPrices("com.mazl.app.plus.3m", ["FRA"]);
    expect(price?.customerPrice).toBe("49.99"); // clock is 2026-11-01: past applies, future does not
  });

  test("a consumable reads the price schedule: manual prices win over automatic ones", async () => {
    const fake = new FakeAsc()
      .get(`/v1/subscriptionGroups/${GROUP}/subscriptions?filter[productId]=com.mazl.app.boost.1&limit=200`, doc("empty-list"))
      .get(`/v1/apps/${APP}/inAppPurchasesV2?filter[productId]=com.mazl.app.boost.1&limit=200`, doc("inapp-boost-1"))
      .get("/v1/inAppPurchasePriceSchedules/6826542320/automaticPrices?include=inAppPurchasePricePoint,territory&limit=200&filter[territory]=FRA,USA", doc("iap-automatic-prices"))
      .get("/v1/inAppPurchasePriceSchedules/6826542320/manualPrices?include=inAppPurchasePricePoint,territory&limit=200&filter[territory]=FRA,USA", doc("iap-manual-prices"));
    const prices = await pricingWith(fake).currentPrices("com.mazl.app.boost.1", ["FRA", "USA"]);
    expect([...prices].sort((a, b) => a.territory.localeCompare(b.territory))).toEqual([
      { territory: "FRA", currency: "EUR", customerPrice: "7.99" },
      { territory: "USA", currency: "USD", customerPrice: "6.99" },
    ]);
    expect(fake.unexpected).toEqual([]);
  });

  test("a consumable price outside its start/end window is ignored", async () => {
    const manual = structuredClone(doc("iap-manual-prices"));
    manual.data[0]!.attributes.endDate = "2026-10-31"; // ended yesterday
    const fake = new FakeAsc()
      .get(`/v1/subscriptionGroups/${GROUP}/subscriptions?filter[productId]=com.mazl.app.boost.1&limit=200`, doc("empty-list"))
      .get(`/v1/apps/${APP}/inAppPurchasesV2?filter[productId]=com.mazl.app.boost.1&limit=200`, doc("inapp-boost-1"))
      .get("/v1/inAppPurchasePriceSchedules/6826542320/automaticPrices?include=inAppPurchasePricePoint,territory&limit=200&filter[territory]=FRA", doc("empty-list"))
      .get("/v1/inAppPurchasePriceSchedules/6826542320/manualPrices?include=inAppPurchasePricePoint,territory&limit=200&filter[territory]=FRA", manual);
    expect(await pricingWith(fake).currentPrices("com.mazl.app.boost.1", ["FRA"])).toEqual([]);
  });

  test("an unknown product is a typed error", async () => {
    const fake = new FakeAsc()
      .get(`/v1/subscriptionGroups/${GROUP}/subscriptions?filter[productId]=com.mazl.app.nope&limit=200`, doc("empty-list"))
      .get(`/v1/apps/${APP}/inAppPurchasesV2?filter[productId]=com.mazl.app.nope&limit=200`, doc("empty-list"));
    await expect(pricingWith(fake).currentPrices("com.mazl.app.nope", ["FRA"])).rejects.toBeInstanceOf(UnknownProductError);
  });

  test("the product lookup is cached", async () => {
    const fake = withSubscription(new FakeAsc()).get(PRICES_5, doc("subscription-prices-5-territories"));
    const api = pricingWith(fake);
    await api.currentPrices("com.mazl.app.plus.3m", ["FRA", "USA", "GBR", "ISR", "CAN"]);
    await api.currentPrices("com.mazl.app.plus.3m", ["FRA", "USA", "GBR", "ISR", "CAN"]);
    expect(fake.calls.filter((c) => c.url === SUB_LOOKUP)).toHaveLength(1);
  });
});

describe("Apple errors", () => {
  const body = { errors: [{ status: "429", code: "RATE_LIMIT_EXCEEDED", title: "Rate limit", detail: "Too many requests" }] };

  test("429 is an explicit error with the retry delay, and nothing is retried", async () => {
    const fake = new FakeAsc().get(SUB_LOOKUP, body, 429, { "retry-after": "30" });
    const error = await pricingWith(fake).currentPrices("com.mazl.app.plus.3m", ["FRA"]).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(AscApiError);
    const apple = error as AscApiError;
    expect([apple.status, apple.code, apple.detail, apple.rateLimited, apple.retryAfterSeconds]).toEqual([429, "RATE_LIMIT_EXCEEDED", "Too many requests", true, 30]);
    expect(fake.calls).toHaveLength(1);
  });

  test("500 carries status, code and detail and is not retried", async () => {
    const fake = new FakeAsc().get(SUB_LOOKUP, { errors: [{ status: "500", code: "UNEXPECTED_ERROR", title: "x", detail: "Boom" }] }, 500);
    const error = (await pricingWith(fake).currentPrices("com.mazl.app.plus.3m", ["FRA"]).catch((e: unknown) => e)) as AscApiError;
    expect([error.status, error.code, error.detail]).toEqual([500, "UNEXPECTED_ERROR", "Boom"]);
    expect(error.message).toContain("500");
    expect(fake.calls).toHaveLength(1);
  });

  test("an unreachable Apple is a typed network error", async () => {
    const api = pricingWith(Object.assign(new FakeAsc(), { fetch: async () => Promise.reject(new Error("offline")) }));
    await expect(api.currentPrices("com.mazl.app.plus.3m", ["FRA"])).rejects.toBeInstanceOf(AscNetworkError);
  });
});

describe("pricePoints", () => {
  test("follows links.next and returns every point with price and proceeds", async () => {
    const fake = withSubscription(new FakeAsc()).get(POINTS_FRA, doc("price-points-fra-page1")).get(POINTS_FRA_NEXT, doc("price-points-fra-page2"));
    const points = await pricingWith(fake).pricePoints("com.mazl.app.plus.3m", "FRA");
    expect(points).toHaveLength(doc("price-points-fra-page1").data.length + doc("price-points-fra-page2").data.length);
    const forty = points.find((p) => p.customerPrice === "44.99");
    expect(forty).toEqual({ id: point("price-points-fra-page2", "44.99"), territory: "FRA", customerPrice: "44.99", proceeds: "26.24" });
    expect(fake.unexpected).toEqual([]);
  });

  test("refuses a consumable", async () => {
    const fake = new FakeAsc()
      .get(`/v1/subscriptionGroups/${GROUP}/subscriptions?filter[productId]=com.mazl.app.boost.1&limit=200`, doc("empty-list"))
      .get(`/v1/apps/${APP}/inAppPurchasesV2?filter[productId]=com.mazl.app.boost.1&limit=200`, doc("inapp-boost-1"));
    await expect(pricingWith(fake).pricePoints("com.mazl.app.boost.1", "FRA")).rejects.toBeInstanceOf(UnsupportedProductError);
  });
});

describe("planPriceChange", () => {
  const BASE = "eyJzIjoiNjgyNjUzODc3OSIsInQiOiJGUkEiLCJwIjoiMTAzMjcifQ";
  const routes = (current: Doc = doc("subscription-prices-all-reduced")) =>
    withSubscription(new FakeAsc())
      .get(`/v1/subscriptionPricePoints/${BASE}?include=territory`, doc("price-point-fra-49-99"))
      .get(eq(BASE), doc("equalizations-of-fra-49-99"))
      .get(PRICES_ALL, current);

  test("lists one change per country against its current price, and writes nothing", async () => {
    const fake = routes();
    const plan = await pricingWith(fake).planPriceChange("com.mazl.app.plus.3m", BASE, "2026-12-01", true);
    expect(plan).toMatchObject({ productId: "com.mazl.app.plus.3m", startDate: "2026-12-01", preserveCurrentPrice: true });
    const byTerritory = Object.fromEntries(plan.changes.map((c) => [c.territory, `${c.from}->${c.to}`]));
    expect(byTerritory).toEqual({ FRA: "44.99->49.99", AFG: "39.99->44.99", AGO: "39.99->44.99", USA: "49.99->44.99", GBR: "39.99->44.99", ISR: "119.9->129.9", CAN: "49.99->59.99" });
    expect(plan.changes.find((c) => c.territory === "FRA")?.pricePointId).toBe(BASE);
    expect(fake.writes()).toEqual([]);
    expect(fake.unexpected).toEqual([]);
  });

  test("a country already on the target price point is left out; a country without price has from = null", async () => {
    const current = structuredClone(doc("subscription-prices-all-reduced"));
    const agoEq = doc("equalizations-of-fra-49-99").data.find((p) => territoryOf(p) === "AGO")!;
    current.data.find((p) => territoryOf(p) === "AGO")!.relationships.subscriptionPricePoint.data.id = agoEq.id;
    current.included!.push({ type: "subscriptionPricePoints", id: agoEq.id, attributes: agoEq.attributes });
    current.data = current.data.filter((p) => territoryOf(p) !== "ISR");
    const plan = await pricingWith(routes(current)).planPriceChange("com.mazl.app.plus.3m", BASE, "2026-12-01", false);
    expect(plan.changes.some((c) => c.territory === "AGO")).toBe(false);
    expect(plan.changes.find((c) => c.territory === "ISR")?.from).toBeNull();
    expect(plan.preserveCurrentPrice).toBe(false);
  });
});

describe("applyPriceChange", () => {
  const plan = {
    productId: "com.mazl.app.plus.3m",
    startDate: "2026-12-01",
    preserveCurrentPrice: true,
    changes: [
      { territory: "FRA", from: "44.99", to: "49.99", pricePointId: "pp-fra" },
      { territory: "USA", from: "49.99", to: "44.99", pricePointId: "pp-usa" },
      { territory: "GBR", from: "39.99", to: "44.99", pricePointId: "pp-gbr" },
    ],
  };
  const expected = (territory: string, pp: string) => ({
    data: {
      type: "subscriptionPrices",
      attributes: { startDate: "2026-12-01", preserveCurrentPrice: true },
      relationships: {
        subscription: { data: { type: "subscriptions", id: SUB } },
        subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: pp } },
        territory: { data: { type: "territories", id: territory } },
      },
    },
  });

  test("posts one subscriptionPrices resource per country with the JSON:API relationships", async () => {
    const created = { data: { type: "subscriptionPrices", id: "new" } };
    const fake = withSubscription(new FakeAsc()).on("POST", "/v1/subscriptionPrices", created, 201);
    await pricingWith(fake).applyPriceChange(plan);
    expect(fake.writes().map((c) => c.body)).toEqual([expected("FRA", "pp-fra"), expected("USA", "pp-usa"), expected("GBR", "pp-gbr")]);
    expect(fake.writes().every((c) => c.headers["content-type"] === "application/json")).toBe(true);
  });

  test("reports every failed country without stopping at the first", async () => {
    const fake = withSubscription(new FakeAsc()).handle("POST", "/v1/subscriptionPrices", (call) => {
      const territory = (call.body as { data: { relationships: { territory: { data: { id: string } } } } }).data.relationships.territory.data.id;
      return territory === "USA" || territory === "GBR"
        ? { status: 409, body: { errors: [{ status: "409", code: "ENTITY_ERROR", detail: `no price for ${territory}` }] } }
        : { status: 201, body: { data: { type: "subscriptionPrices", id: "ok" } } };
    });
    const error = (await pricingWith(fake).applyPriceChange(plan).catch((e: unknown) => e)) as PriceChangeError;
    expect(error).toBeInstanceOf(PriceChangeError);
    expect(error.applied).toEqual(["FRA"]);
    expect(error.failures.map((f) => f.territory)).toEqual(["USA", "GBR"]);
    expect((error.failures[0]?.error as AscApiError).code).toBe("ENTITY_ERROR");
    expect(fake.writes()).toHaveLength(3);
  });
});

describe("offer codes", () => {
  const REDUCED = point("price-points-fra-page1", "31.49");
  const request = { productId: "com.mazl.app.plus.3m", name: "Saint-Valentin 2027", customCode: "VALENTIN27", discountPercent: 30, expiresOn: "2027-02-14" };
  const included = (territory: string, id: string) => ({
    type: "subscriptionOfferCodePrices",
    id: `\${price-${territory}}`,
    relationships: {
      subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id } },
      territory: { data: { type: "territories", id: territory } },
    },
  });

  function readRoutes(): FakeAsc {
    return withSubscription(new FakeAsc())
      .get(PRICES_FRA, onlyTerritories(doc("subscription-prices-all-reduced"), ["FRA"]))
      .get(POINTS_FRA, doc("price-points-fra-page1"))
      .get(POINTS_FRA_NEXT, doc("price-points-fra-page2"))
      .get(eq(REDUCED), doc("equalizations-of-fra-49-99"));
  }

  const equalized = doc("equalizations-of-fra-49-99").data.map((r) => included(territoryOf(r), r.id));
  const offerBody = (eligibility: string) => ({
    data: {
      type: "subscriptionOfferCodes",
      attributes: {
        name: "Saint-Valentin 2027",
        customerEligibilities: ["NEW", "EXISTING", "EXPIRED"],
        offerEligibility: eligibility,
        duration: "THREE_MONTHS",
        offerMode: "PAY_AS_YOU_GO",
        numberOfPeriods: 1,
        autoRenewEnabled: true,
      },
      relationships: {
        subscription: { data: { type: "subscriptions", id: SUB } },
        prices: { data: [included("FRA", REDUCED), ...equalized].map((p) => ({ type: "subscriptionOfferCodePrices", id: p.id })) },
      },
    },
    included: [included("FRA", REDUCED), ...equalized],
  });
  const customCodeBody = {
    data: {
      type: "subscriptionOfferCodeCustomCodes",
      attributes: { customCode: "VALENTIN27", numberOfCodes: 100000, expirationDate: "2027-02-14" },
      relationships: { offerCode: { data: { type: "subscriptionOfferCodes", id: "offer-1" } } },
    },
  };

  test("creates the offer at the price point closest to -30 % in FRA, equalized elsewhere, then the custom code", async () => {
    const fake = readRoutes()
      .on("POST", "/v1/subscriptionOfferCodes", { data: { type: "subscriptionOfferCodes", id: "offer-1" } }, 201)
      .on("POST", "/v1/subscriptionOfferCodeCustomCodes", { data: { type: "subscriptionOfferCodeCustomCodes", id: "custom-1", attributes: { customCode: "VALENTIN27" } } }, 201);
    const code = await pricingWith(fake).createOfferCode(request);
    expect(code).toEqual({ productId: "com.mazl.app.plus.3m", offerCodeId: "offer-1", customCodeId: "custom-1", customCode: "VALENTIN27" });
    expect(fake.writes().map((c) => [c.method, c.url, c.body])).toEqual([
      ["POST", "/v1/subscriptionOfferCodes", offerBody("STACK_WITH_INTRO_OFFERS")],
      ["POST", "/v1/subscriptionOfferCodeCustomCodes", customCodeBody],
    ]);
    expect(fake.unexpected).toEqual([]);
  });

  test("falls back to REPLACE_INTRO_OFFERS only when Apple refuses the eligibility", async () => {
    const refusal = { errors: [{ status: "409", code: "ENTITY_ERROR.ATTRIBUTE.INVALID", title: "invalid", detail: "not allowed", source: { pointer: "/data/attributes/offerEligibility" } }] };
    const posts: string[] = [];
    const fake = readRoutes()
      .handle("POST", "/v1/subscriptionOfferCodes", (call) => {
        posts.push((call.body as { data: { attributes: { offerEligibility: string } } }).data.attributes.offerEligibility);
        return posts.length === 1 ? { status: 409, body: refusal } : { status: 201, body: { data: { type: "subscriptionOfferCodes", id: "offer-1" } } };
      })
      .on("POST", "/v1/subscriptionOfferCodeCustomCodes", { data: { type: "subscriptionOfferCodeCustomCodes", id: "custom-1" } }, 201);
    const code = await pricingWith(fake).createOfferCode(request);
    expect(posts).toEqual(["STACK_WITH_INTRO_OFFERS", "REPLACE_INTRO_OFFERS"]);
    expect(code.offerCodeId).toBe("offer-1");
  });

  test("any other Apple refusal is not retried", async () => {
    const fake = readRoutes().on("POST", "/v1/subscriptionOfferCodes", { errors: [{ status: "409", code: "ENTITY_ERROR", detail: "other" }] }, 409);
    await expect(pricingWith(fake).createOfferCode(request)).rejects.toBeInstanceOf(AscApiError);
    expect(fake.writes()).toHaveLength(1);
  });

  test("a custom code Apple refuses leaves no live offer behind and reports Apple's error", async () => {
    const fake = readRoutes()
      .on("POST", "/v1/subscriptionOfferCodes", { data: { type: "subscriptionOfferCodes", id: "offer-1" } }, 201)
      .on("POST", "/v1/subscriptionOfferCodeCustomCodes", { errors: [{ status: "409", code: "ENTITY_ERROR.ATTRIBUTE.INVALID", detail: "code taken" }] }, 409)
      .on("PATCH", "/v1/subscriptionOfferCodes/offer-1", { data: { type: "subscriptionOfferCodes", id: "offer-1" } });
    const error = (await pricingWith(fake).createOfferCode(request).catch((e: unknown) => e)) as AscApiError;
    expect(error).toBeInstanceOf(AscApiError);
    expect(error.detail).toBe("code taken");
    expect(fake.writes().at(-1)).toMatchObject({ method: "PATCH", url: "/v1/subscriptionOfferCodes/offer-1", body: { data: { type: "subscriptionOfferCodes", id: "offer-1", attributes: { active: false } } } });
  });

  test("honours the number of codes the caller allows", async () => {
    const fake = readRoutes()
      .on("POST", "/v1/subscriptionOfferCodes", { data: { type: "subscriptionOfferCodes", id: "offer-1" } }, 201)
      .on("POST", "/v1/subscriptionOfferCodeCustomCodes", { data: { type: "subscriptionOfferCodeCustomCodes", id: "custom-1" } }, 201);
    await pricingWith(fake, { numberOfCodes: 500 }).createOfferCode(request);
    expect((fake.writes()[1]?.body as { data: { attributes: { numberOfCodes: number } } }).data.attributes.numberOfCodes).toBe(500);
  });

  test.each([
    ["discount of 0", { discountPercent: 0 }],
    ["discount of 100", { discountPercent: 100 }],
    ["lower-case code", { customCode: "valentin27" }],
    ["too short code", { customCode: "AB" }],
    ["bad date", { expiresOn: "14/02/2027" }],
    ["empty name", { name: "" }],
  ])("rejects %s before any call", async (_label, patch) => {
    const fake = new FakeAsc();
    await expect(pricingWith(fake).createOfferCode({ ...request, ...patch })).rejects.toBeInstanceOf(OfferCodeError);
    expect(fake.calls).toEqual([]);
  });

  test("deactivates the custom code then the offer", async () => {
    const fake = new FakeAsc().on("PATCH", "/v1/subscriptionOfferCodeCustomCodes/custom-1", { data: { type: "subscriptionOfferCodeCustomCodes", id: "custom-1" } }).on("PATCH", "/v1/subscriptionOfferCodes/offer-1", { data: { type: "subscriptionOfferCodes", id: "offer-1" } });
    await pricingWith(fake).deactivateOfferCode({ productId: "com.mazl.app.plus.3m", offerCodeId: "offer-1", customCodeId: "custom-1", customCode: "VALENTIN27" });
    expect(fake.writes().map((c) => [c.method, c.url, c.body])).toEqual([
      ["PATCH", "/v1/subscriptionOfferCodeCustomCodes/custom-1", { data: { type: "subscriptionOfferCodeCustomCodes", id: "custom-1", attributes: { active: false } } }],
      ["PATCH", "/v1/subscriptionOfferCodes/offer-1", { data: { type: "subscriptionOfferCodes", id: "offer-1", attributes: { active: false } } }],
    ]);
  });

  test("still tries the offer when the custom code cannot be deactivated, then reports", async () => {
    const fake = new FakeAsc().on("PATCH", "/v1/subscriptionOfferCodeCustomCodes/custom-1", { errors: [{ status: "404", code: "NOT_FOUND", detail: "gone" }] }, 404).on("PATCH", "/v1/subscriptionOfferCodes/offer-1", { data: { type: "subscriptionOfferCodes", id: "offer-1" } });
    await expect(pricingWith(fake).deactivateOfferCode({ productId: "com.mazl.app.plus.3m", offerCodeId: "offer-1", customCodeId: "custom-1", customCode: "VALENTIN27" })).rejects.toBeInstanceOf(OfferCodeError);
    expect(fake.writes()).toHaveLength(2);
  });
});

test("the fake clock is the one the price selection uses", () => {
  expect(new Date(NOW).toISOString().slice(0, 10)).toBe("2026-11-01");
});
