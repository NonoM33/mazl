import { beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { CampaignService } from "../../../src/features/storefront/application/campaign-service";
import { CatalogService } from "../../../src/features/storefront/application/catalog-service";
import { appStoreNotConfigured, webPricingNotConfigured } from "../../../src/features/storefront/infra/not-configured";
import { honoPath, OPERATIONS, PUBLIC_PATH } from "../../../src/features/storefront/presentation/operations";
import { registerPublicStorefrontRoute, registerStorefrontAdminRoutes } from "../../../src/features/storefront/presentation/routes";
import * as schemas from "../../../src/features/storefront/presentation/schemas";
import { roleGrants, type StaffRole } from "../../../src/features/staff/domain/roles";
import type { RequirePermission, StaffVariables } from "../../../src/features/staff/application/ports";
import { FakeApple, FakeStripe, MemoryAudit, MemoryRepository } from "./fakes";
import { campaignRequestExample } from "../../../src/features/storefront/presentation/examples";

// The routes against in-memory services. Authentication is stood in for by a header carrying the role;
// what is tested is which permission each route asks for, with the real role table.
const requirePermission: RequirePermission = (permission) =>
  createMiddleware<{ Variables: StaffVariables }>(async (c, next) => {
    const role = c.req.header("x-role");
    if (role === undefined) return c.json({ success: false, error: "unauthorized", message: "Connexion requise." }, 401);
    if (!roleGrants(role as StaffRole, permission)) return c.json({ success: false, error: "forbidden", message: "Droits insuffisants." }, 403);
    c.set("staff", { email: "staff@example.com", role: role as StaffRole, mfa: true });
    await next();
  });

const NOW = new Date("2027-02-10T09:00:00Z");
let repository: MemoryRepository;
let app: Hono;
let apple: FakeApple;

function build(options: { configured: boolean; production?: boolean }): void {
  repository = new MemoryRepository();
  apple = new FakeApple();
  const audit = new MemoryAudit();
  const deps = {
    repository,
    apple: options.configured ? apple : appStoreNotConfigured,
    web: options.configured ? new FakeStripe() : webPricingNotConfigured,
    audit,
    env: { STRIPE_PRICE_PLUS_3M: "price_env_plus_3m" },
    now: () => NOW,
  };
  const admin = new Hono<{ Variables: StaffVariables }>();
  registerStorefrontAdminRoutes(admin, {
    requirePermission,
    catalog: new CatalogService(deps),
    campaigns: new CampaignService(deps),
    repository,
    now: () => NOW,
    exposeOpenApi: options.production !== true,
  });
  app = new Hono();
  app.route("/", admin);
  registerPublicStorefrontRoute(app, { repository, now: () => NOW });
}

const call = (role: StaffRole | null, method: string, path: string, body?: unknown) =>
  app.request(path, {
    method,
    headers: { ...(role === null ? {} : { "x-role": role }), "content-type": "application/json" },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
const json = async (response: Response) => (await response.json()) as Record<string, any>;

beforeEach(() => build({ configured: true }));

describe("registration", () => {
  test("every declared operation is a registered route, and no route is undeclared", () => {
    const registered = app.routes.map((r) => `${r.method.toLowerCase()} ${r.path}`).filter((key) => key.includes("storefront"));
    const declared = OPERATIONS.map((o) => `${o.method} ${honoPath(o.path)}`);
    expect([...new Set(registered)].sort()).toEqual([...declared].sort());
  });
});

describe("roles", () => {
  const P = "/api/backoffice/storefront";
  const reads: [string, string][] = [
    ["get", `${P}/products`],
    ["get", `${P}/campaigns`],
    ["get", `${P}/campaigns/presets?year=2027`],
    ["get", `${P}/products/com.mazl.app.plus.3m/apple-price-points`],
  ];
  const storeWrites: [string, string, unknown][] = [
    ["post", `${P}/products/com.mazl.app.plus.3m/apple-price`, { pricePointId: "pp", startDate: "2027-03-01" }],
    ["post", `${P}/products/com.mazl.app.plus.3m/web-price`, { amountCents: 2699, currency: "eur" }],
    ["post", `${P}/campaigns/1/publish`, undefined],
    ["post", `${P}/campaigns/1/cancel`, undefined],
  ];

  test("anonymous: 401 everywhere", async () => {
    for (const [method, path] of reads) expect((await call(null, method, path)).status).toBe(401);
    for (const [method, path, body] of storeWrites) expect((await call(null, method, path, body)).status).toBe(401);
    expect((await call(null, "post", `${P}/campaigns`, campaignRequestExample)).status).toBe(401);
    expect((await call(null, "patch", `${P}/products/com.mazl.app.plus.3m`, { visible: false })).status).toBe(401);
    expect((await call(null, "get", `${P}/openapi.json`)).status).toBe(401);
  });

  test("moderator, support, analyst, verifier: 403 on everything", async () => {
    for (const role of ["moderator", "support", "analyst", "verifier"] as const) {
      for (const [method, path] of reads) expect((await call(role, method, path)).status).toBe(403);
      for (const [method, path, body] of storeWrites) expect((await call(role, method, path, body)).status).toBe(403);
      expect((await call(role, "post", `${P}/campaigns`, campaignRequestExample)).status).toBe(403);
    }
  });

  test("admin reads and edits but cannot write to the stores", async () => {
    for (const [method, path] of reads) expect((await call("admin", method, path)).status).toBe(200);
    expect((await call("admin", "patch", `${P}/products/com.mazl.app.plus.3m`, { visible: false })).status).toBe(200);
    expect((await call("admin", "post", `${P}/campaigns`, campaignRequestExample)).status).toBe(201);
    for (const [method, path, body] of storeWrites) {
      const response = await call("admin", method, path, body);
      expect([response.status, (await json(response)).error]).toEqual([403, "forbidden"]);
    }
    expect(apple.calls).not.toContain("applyPriceChange");
    expect(apple.calls).not.toContain("createOfferCode");
  });

  test("super-admin writes to the stores", async () => {
    const created = await json(await call("super_admin", "post", `${P}/campaigns`, campaignRequestExample));
    const id = created.data.id as number;
    const published = await call("super_admin", "post", `${P}/campaigns/${String(id)}/publish`);
    expect(published.status).toBe(200);
    // The clock stands in the middle of the campaign: scheduled at the store, live for the member.
    expect((await json(published)).data.status).toBe("live");
    expect((await call("super_admin", "post", `${P}/campaigns/${String(id)}/cancel`)).status).toBe(200);
    const price = await json(await call("super_admin", "post", `${P}/products/com.mazl.app.plus.3m/apple-price`, { pricePointId: "pp", startDate: "2027-03-01" }));
    expect(price.data.dryRun).toBe(true); // dryRun is the default
    expect(apple.calls).not.toContain("applyPriceChange");
  });

  test("the public route needs no one", async () => {
    expect((await call(null, "get", PUBLIC_PATH)).status).toBe(200);
  });
});

describe("responses match the documented schemas", () => {
  const P = "/api/backoffice/storefront";
  const parse = (schema: { safeParse(v: unknown): { success: boolean; error?: unknown } }, value: unknown) => {
    const result = schema.safeParse(value);
    if (!result.success) throw new Error(JSON.stringify(result.error));
  };

  test("products, campaigns, presets, plan, public", async () => {
    parse(schemas.envelope(schemas.productListDto), await json(await call("admin", "get", `${P}/products`)));
    const created = await json(await call("admin", "post", `${P}/campaigns`, campaignRequestExample));
    parse(schemas.envelope(schemas.campaignDto), created);
    parse(schemas.envelope(schemas.campaignListDto), await json(await call("admin", "get", `${P}/campaigns?year=2027`)));
    parse(schemas.envelope(schemas.presetListDto), await json(await call("admin", "get", `${P}/campaigns/presets?year=2027`)));
    parse(schemas.envelope(schemas.pricePointsDto), await json(await call("admin", "get", `${P}/products/com.mazl.app.plus.3m/apple-price-points?territory=USA`)));
    parse(schemas.envelope(schemas.applePriceResultDto), await json(await call("super_admin", "post", `${P}/products/com.mazl.app.plus.3m/apple-price`, { pricePointId: "pp", startDate: "2027-03-01", dryRun: false })));
    parse(schemas.envelope(schemas.webPriceResultDto), await json(await call("super_admin", "post", `${P}/products/com.mazl.app.plus.3m/web-price`, { amountCents: 2699, currency: "eur" })));
    parse(schemas.envelope(schemas.productDisplayDto), await json(await call("admin", "patch", `${P}/products/com.mazl.app.plus.3m`, { featured: true })));
    await call("super_admin", "post", `${P}/campaigns/${String(created.data.id)}/publish`);
    const live = await call(null, "get", PUBLIC_PATH, undefined);
    parse(schemas.envelope(schemas.publicStorefrontDto), await json(live));
  });
});

describe("errors", () => {
  const P = "/api/backoffice/storefront";

  test("bad bodies are 400 invalid_body, never a 500", async () => {
    for (const body of [{}, { visible: "yes" }, { unknown: 1 }, { sortOrder: -1 }]) {
      const response = await call("admin", "patch", `${P}/products/com.mazl.app.plus.3m`, body);
      expect([response.status, (await json(response)).error]).toEqual([400, "invalid_body"]);
    }
    const garbage = await app.request(`${P}/campaigns`, { method: "POST", headers: { "x-role": "admin" }, body: "{not json" });
    expect(garbage.status).toBe(400);
    for (const bad of [{ ...campaignRequestExample, targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: 95 }] }, { ...campaignRequestExample, name: "" }, { ...campaignRequestExample, startsAt: "yesterday" }]) {
      expect((await call("admin", "post", `${P}/campaigns`, bad)).status).toBe(400);
    }
  });

  test("business rules: 400 invalid_campaign, 404, 409", async () => {
    const tooLong = { ...campaignRequestExample, endsAt: "2027-06-01T00:00:00+02:00" };
    expect(await json(await call("admin", "post", `${P}/campaigns`, tooLong))).toMatchObject({ success: false, error: "invalid_campaign" });
    expect((await call("admin", "patch", `${P}/products/com.mazl.app.nope`, { visible: false })).status).toBe(404);
    expect((await call("admin", "patch", `${P}/campaigns/999`, { name: "x" })).status).toBe(404);
    expect((await call("admin", "patch", `${P}/campaigns/abc`, { name: "x" })).status).toBe(404);
    expect((await call("super_admin", "post", `${P}/campaigns/999/publish`)).status).toBe(404);
    const created = await json(await call("admin", "post", `${P}/campaigns`, campaignRequestExample));
    await call("super_admin", "post", `${P}/campaigns/${String(created.data.id)}/publish`);
    const overlapping = await json(await call("admin", "post", `${P}/campaigns`, { ...campaignRequestExample, name: "Autre" }));
    const clash = await call("super_admin", "post", `${P}/campaigns/${String(overlapping.data.id)}/publish`);
    expect([clash.status, (await json(clash)).error]).toEqual([409, "campaign_overlap"]);
    const locked = await call("admin", "patch", `${P}/campaigns/${String(created.data.id)}`, { targets: [{ productId: "com.mazl.app.plus.1m", discountPercent: 10 }] });
    expect([locked.status, (await json(locked)).error]).toEqual([409, "campaign_not_editable"]);
  });

  test("invalid queries are 400 invalid_query", async () => {
    expect((await call("admin", "get", `${P}/campaigns?year=1999`)).status).toBe(400);
    expect((await call("admin", "get", `${P}/campaigns/presets`)).status).toBe(400);
    expect((await call("admin", "get", `${P}/products/com.mazl.app.plus.3m/apple-price-points?territory=fr`)).status).toBe(400);
  });

  test("stores not configured: 503 store_not_configured, the catalogue list still answers", async () => {
    build({ configured: false });
    const created = await json(await call("admin", "post", `${P}/campaigns`, campaignRequestExample));
    const publish = await call("super_admin", "post", `${P}/campaigns/${String(created.data.id)}/publish`);
    expect([publish.status, (await json(publish)).error]).toEqual([503, "store_not_configured"]);
    const price = await call("super_admin", "post", `${P}/products/com.mazl.app.plus.3m/web-price`, { amountCents: 2699, currency: "eur" });
    expect([price.status, (await json(price)).error]).toEqual([503, "store_not_configured"]);
    const list = await json(await call("admin", "get", `${P}/products`));
    expect(list.data.products[0].prices.apple).toEqual({ status: "unavailable", error: "store_not_configured" });
    expect((await call("admin", "get", `${P}/campaigns`)).status).toBe(200);
  });

  test("a store failure is 502 store_error without leaking more than a short message", async () => {
    apple.failOn = "create";
    const created = await json(await call("admin", "post", `${P}/campaigns`, campaignRequestExample));
    const publish = await call("super_admin", "post", `${P}/campaigns/${String(created.data.id)}/publish`);
    expect([publish.status, (await json(publish)).error]).toEqual([502, "store_error"]);
    const list = await json(await call("admin", "get", `${P}/campaigns`));
    expect(list.data.campaigns[0]).toMatchObject({ status: "draft", apple: { error: "apple: apple down" } });
  });
});

describe("public route", () => {
  test("cached for a minute, varies by language, French by default", async () => {
    const response = await call(null, "get", PUBLIC_PATH);
    expect(response.headers.get("cache-control")).toBe("public, max-age=60");
    expect(response.headers.get("vary")).toContain("Accept-Language");
    await repository.updateProduct("com.mazl.app.plus.3m", { highlight: { fr: "Le plus choisi", en: "Most popular" } }, "staff@example.com");
    const english = await app.request(PUBLIC_PATH, { headers: { "accept-language": "en-GB,en;q=0.9" } });
    const product = (await json(english)).data.products.find((p: { productId: string }) => p.productId === "com.mazl.app.plus.3m");
    expect(product.highlight).toBe("Most popular");
  });
});

describe("OpenAPI route", () => {
  test("served to the staff outside production, absent in production", async () => {
    const outside = await call("admin", "get", "/api/backoffice/storefront/openapi.json");
    expect(outside.status).toBe(200);
    expect((await json(outside)).openapi).toBe("3.1.0");
    build({ configured: true, production: true });
    const inProduction = await call("super_admin", "get", "/api/backoffice/storefront/openapi.json");
    expect([inProduction.status, (await json(inProduction)).error]).toEqual([404, "not_found"]);
  });
});
