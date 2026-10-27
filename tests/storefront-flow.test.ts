import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { createTokenSigner, resolveStaffKey } from "../src/features/staff/domain/session-token";
import { buildOpenApi } from "../src/features/storefront/presentation/openapi";
import * as schemas from "../src/features/storefront/presentation/schemas";
import { campaignRequestExample } from "../src/features/storefront/presentation/examples";
import { BASE_URL, db, json, makeUser } from "./media-helpers";
import { FakeStripeClient } from "./support/fake-stripe-client";

// Needs the server (NODE_ENV=test: no Apple or Stripe adapter is wired into the storefront, so the
// stores answer "store_not_configured"), its database and the fake Stripe of the checkout.
const P = `${BASE_URL}/api/backoffice/storefront`;
const PUBLIC = `${BASE_URL}/api/storefront`;
const fake = new FakeStripeClient(process.env.FAKE_STRIPE_URL ?? "http://127.0.0.1:12113");
const WAIVER = { withdrawal_waiver: true, waiver_version: "2026-10-24" };
const PLUS_3M = "com.mazl.app.plus.3m";
const tag = `${Date.now()}`;

const signer = createTokenSigner(resolveStaffKey(process.env));
const staff = { admin: `storefront-admin-${tag}@example.com`, moderator: `storefront-moderator-${tag}@example.com` };
const bearer = (email: string) => ({ Authorization: `Bearer ${signer.signSession({ email, mfa: true })}`, "Content-Type": "application/json" });
const as = {
  anonymous: { "Content-Type": "application/json" } as Record<string, string>,
  moderator: bearer(staff.moderator),
  admin: bearer(staff.admin),
  // The non-production script access of the staff guard: a super-admin.
  superAdmin: { "x-admin-password": process.env.ADMIN_PASSWORD ?? "", "Content-Type": "application/json" },
};
type Who = keyof typeof as;

const send = (who: Who, method: string, path: string, body?: unknown) =>
  fetch(`${P}${path}`, { method, headers: as[who], ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
const read = async (response: Response) => (await response.json()) as Record<string, any>;
const parse = (schema: { safeParse(value: unknown): { success: boolean; error?: unknown } }, value: unknown): void => {
  const result = schema.safeParse(value);
  if (!result.success) throw new Error(`response does not match its documented schema: ${JSON.stringify(result.error)}`);
};

const createdCampaigns: number[] = [];
let originalPlus3m: { visible: boolean; featured: boolean; sort_order: number; highlight: unknown };

beforeAll(async () => {
  await db`INSERT INTO staff_members (email, role) VALUES (${staff.admin}, 'admin'), (${staff.moderator}, 'moderator') ON CONFLICT DO NOTHING`;
  const [row] = await db<{ visible: boolean; featured: boolean; sort_order: number; highlight: unknown }[]>`
    SELECT visible, featured, sort_order, highlight FROM storefront_products WHERE product_id = ${PLUS_3M}`;
  if (row === undefined) throw new Error("storefront_products was not seeded");
  originalPlus3m = row;
});

afterAll(async () => {
  await db`UPDATE storefront_products SET stripe_price_id = NULL, visible = ${originalPlus3m.visible}, featured = ${originalPlus3m.featured},
           sort_order = ${originalPlus3m.sort_order}, highlight = ${originalPlus3m.highlight === null ? null : db.json(originalPlus3m.highlight as never)} WHERE product_id = ${PLUS_3M}`;
  if (createdCampaigns.length > 0) await db`DELETE FROM storefront_campaigns WHERE id = ANY(${createdCampaigns})`;
  await db`DELETE FROM staff_members WHERE email IN (${staff.admin}, ${staff.moderator})`;
});

describe("the schema", () => {
  test("the catalogue starts with the eight products of the web offers, in order", async () => {
    const rows = await db<{ product_id: string }[]>`SELECT product_id FROM storefront_products ORDER BY sort_order`;
    expect(rows.map((r) => r.product_id)).toEqual([
      "com.mazl.app.plus.1m", PLUS_3M, "com.mazl.app.plus.6m", "com.mazl.app.plus.12m",
      "com.mazl.app.boost.1", "com.mazl.app.boost.3", "com.mazl.app.superlikes.5", "com.mazl.app.superlikes.15",
    ]);
  });
});

describe("who can call what", () => {
  const reads = ["/products", "/campaigns", "/campaigns/presets?year=2027", `/products/${PLUS_3M}/apple-price-points`, "/openapi.json"];
  const storeWrites: [string, unknown][] = [
    [`/products/${PLUS_3M}/apple-price`, { pricePointId: "pp", startDate: "2099-01-01" }],
    [`/products/${PLUS_3M}/web-price`, { amountCents: 2699, currency: "eur" }],
    ["/campaigns/1/publish", undefined],
    ["/campaigns/1/cancel", undefined],
  ];

  test("anonymous: 401 on every staff route; the public route is open", async () => {
    for (const path of reads) expect((await send("anonymous", "GET", path)).status).toBe(401);
    for (const [path, body] of storeWrites) expect((await send("anonymous", "POST", path, body)).status).toBe(401);
    expect((await send("anonymous", "POST", "/campaigns", campaignRequestExample)).status).toBe(401);
    expect((await send("anonymous", "PATCH", `/products/${PLUS_3M}`, { visible: true })).status).toBe(401);
    expect((await fetch(PUBLIC)).status).toBe(200);
  });

  test("a forged or member token is no staff session", async () => {
    const member = await makeUser("storefront-member");
    const response = await fetch(`${P}/products`, { headers: { Authorization: `Bearer ${member.token}` } });
    expect(response.status).toBe(401);
  });

  test("a moderator reaches nothing", async () => {
    for (const path of reads) expect((await send("moderator", "GET", path)).status).toBe(403);
    expect((await send("moderator", "POST", "/campaigns", campaignRequestExample)).status).toBe(403);
  });

  test("an admin reads and edits, but the store writes are 403 forbidden", async () => {
    for (const path of reads.filter((p) => !p.includes("apple-price-points"))) expect((await send("admin", "GET", path)).status).toBe(200);
    for (const [path, body] of storeWrites) {
      const response = await send("admin", "POST", path, body);
      expect([response.status, (await read(response)).error]).toEqual([403, "forbidden"]);
    }
  });

  test("a super-admin passes the guard of the store writes (the stores are not configured here)", async () => {
    const price = await send("superAdmin", "POST", `/products/${PLUS_3M}/web-price`, { amountCents: 2699, currency: "eur" });
    expect([price.status, (await read(price)).error]).toEqual([503, "store_not_configured"]);
    const points = await send("superAdmin", "GET", `/products/${PLUS_3M}/apple-price-points`);
    expect([points.status, (await read(points)).error]).toEqual([503, "store_not_configured"]);
  });
});

describe("catalogue", () => {
  test("the list answers although no store is wired, and matches its documented schema", async () => {
    const body = await read(await send("admin", "GET", "/products"));
    parse(schemas.envelope(schemas.productListDto), body);
    const plus3 = body.data.products.find((p: { productId: string }) => p.productId === PLUS_3M);
    expect(plus3.prices.apple).toEqual({ status: "unavailable", error: "store_not_configured" });
    // The Stripe price in use is the environment's until the catalogue has its own.
    expect(plus3.effectiveStripePriceId).toBe("price_test_plus_3m");
    expect(plus3.stripePriceId).toBeNull();
  });

  test("an edit reaches the public vitrine, in the asked language, and is audited with its author", async () => {
    const edit = await send("admin", "PATCH", `/products/${PLUS_3M}`, { featured: true, sortOrder: 0, highlight: { fr: "Le plus choisi", en: "Most popular" } });
    expect(edit.status).toBe(200);
    parse(schemas.envelope(schemas.productDisplayDto), await read(edit));
    const fr = await read(await fetch(PUBLIC));
    parse(schemas.envelope(schemas.publicStorefrontDto), fr);
    expect(fr.data.products.find((p: { productId: string }) => p.productId === PLUS_3M)).toMatchObject({ featured: true, highlight: "Le plus choisi", visible: true });
    const en = await read(await fetch(PUBLIC, { headers: { "Accept-Language": "en-GB,en;q=0.8" } }));
    expect(en.data.products.find((p: { productId: string }) => p.productId === PLUS_3M).highlight).toBe("Most popular");
    const [entry] = await db<{ actor: string; target_id: string }[]>`
      SELECT actor, target_id FROM audit_log WHERE action = 'storefront.product.update' AND actor = ${staff.admin} ORDER BY id DESC LIMIT 1`;
    expect(entry).toEqual({ actor: staff.admin, target_id: PLUS_3M });
  });

  test("the public response is cached for a minute and carries no price", async () => {
    const response = await fetch(PUBLIC);
    expect(response.headers.get("cache-control")).toBe("public, max-age=60");
    expect(JSON.stringify(await response.json())).not.toMatch(/amount|price/i);
  });

  test("bad input is a 400 and an unknown product a 404, never a 500", async () => {
    expect((await send("admin", "PATCH", `/products/${PLUS_3M}`, { visible: "yes" })).status).toBe(400);
    expect((await send("admin", "PATCH", `/products/${PLUS_3M}`, {})).status).toBe(400);
    expect((await send("admin", "PATCH", "/products/com.mazl.app.nope", { visible: true })).status).toBe(404);
  });
});

describe("campaigns", () => {
  test("create, list, presets, and a publication that cannot reach the stores stays a draft", async () => {
    const created = await send("admin", "POST", "/campaigns", { ...campaignRequestExample, name: `Test ${tag}`, startsAt: "2031-02-07T00:00:00+01:00", endsAt: "2031-02-15T00:00:00+01:00" });
    expect(created.status).toBe(201);
    const body = await read(created);
    parse(schemas.envelope(schemas.campaignDto), body);
    createdCampaigns.push(body.data.id);
    expect(body.data).toMatchObject({ status: "draft", themeId: "valentine", createdBy: staff.admin, endsAt: "2031-02-14T23:00:00.000Z" });

    const list = await read(await send("admin", "GET", "/campaigns?year=2031"));
    parse(schemas.envelope(schemas.campaignListDto), list);
    expect(list.data.campaigns.map((c: { id: number }) => c.id)).toContain(body.data.id);

    const presets = await read(await send("admin", "GET", "/campaigns/presets?year=2031"));
    parse(schemas.envelope(schemas.presetListDto), presets);
    expect(presets.data.presets).toHaveLength(11);
    expect(presets.data.presets.find((p: { themeId: string }) => p.themeId === "valentine").existing.map((e: { id: number }) => e.id)).toContain(body.data.id);

    const publish = await send("superAdmin", "POST", `/campaigns/${String(body.data.id)}/publish`);
    expect([publish.status, (await read(publish)).error]).toEqual([503, "store_not_configured"]);
    const after = await read(await send("admin", "GET", "/campaigns?year=2031"));
    expect(after.data.campaigns.find((c: { id: number }) => c.id === body.data.id).status).toBe("draft");

    const edited = await send("admin", "PATCH", `/campaigns/${String(body.data.id)}`, { name: `Renommée ${tag}`, targets: [{ productId: PLUS_3M, discountPercent: 25 }] });
    expect((await read(edited)).data).toMatchObject({ name: `Renommée ${tag}`, targets: [{ productId: PLUS_3M, discountPercent: 25 }] });

    // A draft that created nothing at the stores cancels without them.
    const cancelled = await send("superAdmin", "POST", `/campaigns/${String(body.data.id)}/cancel`);
    expect((await read(cancelled)).data.status).toBe("cancelled");
    expect((await send("superAdmin", "POST", `/campaigns/${String(body.data.id)}/cancel`)).status).toBe(409);
  });

  test("the rules answer with their own codes", async () => {
    const tooLong = await send("admin", "POST", "/campaigns", { ...campaignRequestExample, endsAt: "2027-06-01T00:00:00+02:00" });
    expect([tooLong.status, (await read(tooLong)).error]).toEqual([400, "invalid_campaign"]);
    expect((await send("admin", "POST", "/campaigns", { ...campaignRequestExample, targets: [{ productId: PLUS_3M, discountPercent: 91 }] })).status).toBe(400);
    expect((await send("admin", "PATCH", "/campaigns/2147483000", { name: "x" })).status).toBe(404);
    expect((await send("superAdmin", "POST", "/campaigns/2147483000/publish")).status).toBe(404);
    expect((await send("admin", "GET", "/campaigns?year=abc")).status).toBe(400);
  });

  test("two scheduled campaigns cannot overlap (the database refuses the second one)", async () => {
    const insert = async (name: string, starts: string, ends: string) => {
      const [row] = await db<{ id: number }[]>`
        INSERT INTO storefront_campaigns (theme_id, name, starts_at, ends_at, texts, targets, status, created_by)
        VALUES ('christmas', ${name}, ${starts}, ${ends}, ${db.json(campaignRequestExample.texts)}, ${db.json(campaignRequestExample.targets)}, 'draft', ${staff.admin})
        RETURNING id`;
      createdCampaigns.push(row?.id ?? 0);
      return row?.id ?? 0;
    };
    const first = await insert(`A ${tag}`, "2032-12-15T00:00:00Z", "2032-12-27T00:00:00Z");
    const second = await insert(`B ${tag}`, "2032-12-20T00:00:00Z", "2032-12-30T00:00:00Z");
    // Stands for a campaign a successful publication scheduled (no store can be reached from this server).
    await db`UPDATE storefront_campaigns SET status = 'scheduled' WHERE id = ${first}`;
    const clash = await send("superAdmin", "POST", `/campaigns/${String(second)}/publish`);
    // Overlap is checked before any store call.
    expect([clash.status, (await read(clash)).error]).toEqual([409, "campaign_overlap"]);
  });
});

describe("the web checkout follows the catalogue and the live campaign", () => {
  const post = (token: string, body: unknown) =>
    fetch(`${BASE_URL}/api/billing/checkout`, { method: "POST", headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: JSON.stringify(body) });
  const lastSessionFor = async (userId: number) => (await fake.requests()).filter((r) => r.path === "/v1/checkout/sessions" && r.params.client_reference_id === String(userId)).at(-1);
  let liveId = 0;

  test("without any decision, the environment's price and no discount", async () => {
    const user = await makeUser("sf-plain");
    expect((await post(user.token, { offer: "plus_3m", ...WAIVER })).status).toBe(200);
    const session = await lastSessionFor(user.id);
    expect(session?.params["line_items[0][price]"]).toBe("price_test_plus_3m");
    expect(Object.keys(session?.params ?? {}).some((key) => key.startsWith("discounts"))).toBe(false);
  });

  test("a price set in the catalogue replaces the environment variable", async () => {
    await db`UPDATE storefront_products SET stripe_price_id = 'price_test_plus_6m' WHERE product_id = ${PLUS_3M}`;
    const user = await makeUser("sf-catalogue");
    expect((await post(user.token, { offer: "plus_3m", ...WAIVER })).status).toBe(200);
    expect((await lastSessionFor(user.id))?.params["line_items[0][price]"]).toBe("price_test_plus_6m");
    // Only the product it was set on.
    const other = await makeUser("sf-other");
    expect((await post(other.token, { offer: "plus_6m", ...WAIVER })).status).toBe(200);
    expect((await lastSessionFor(other.id))?.params["line_items[0][price]"]).toBe("price_test_plus_6m");
    const [raw] = await db<{ stripe_price_id: string | null }[]>`SELECT stripe_price_id FROM storefront_products WHERE product_id = 'com.mazl.app.plus.6m'`;
    expect(raw?.stripe_price_id).toBeNull();
    await db`UPDATE storefront_products SET stripe_price_id = NULL WHERE product_id = ${PLUS_3M}`;
  });

  test("the live campaign's promotion code is applied to the product it targets, and only to it", async () => {
    const [row] = await db<{ id: number }[]>`
      INSERT INTO storefront_campaigns (theme_id, name, starts_at, ends_at, texts, targets, status, apple, stripe, created_by)
      VALUES ('valentine', ${`Live ${tag}`}, now() - interval '1 hour', now() + interval '1 day', ${db.json(campaignRequestExample.texts)},
              ${db.json([{ productId: PLUS_3M, discountPercent: 30 }])}, 'scheduled',
              ${db.json({ codes: [{ productId: PLUS_3M, offerCodeId: "offer_code_example_1", customCodeId: "custom_code_example_1", customCode: "VALENTIN27" }], error: null })},
              ${db.json({ promotions: [{ productId: PLUS_3M, couponId: "coupon_example_1", promotionCodeId: "promo_example_live" }], error: null })}, ${staff.admin})
      RETURNING id`;
    liveId = row?.id ?? 0;
    createdCampaigns.push(liveId);

    const targeted = await makeUser("sf-promo");
    expect((await post(targeted.token, { offer: "plus_3m", ...WAIVER })).status).toBe(200);
    expect((await lastSessionFor(targeted.id))?.params["discounts[0][promotion_code]"]).toBe("promo_example_live");

    const untouched = await makeUser("sf-nopromo");
    expect((await post(untouched.token, { offer: "boost_1", ...WAIVER })).status).toBe(200);
    expect(Object.keys((await lastSessionFor(untouched.id))?.params ?? {}).some((key) => key.startsWith("discounts"))).toBe(false);
  });

  test("the public vitrine shows that campaign, its icon and the next change; it stops with the campaign", async () => {
    const live = await read(await fetch(PUBLIC, { headers: { "Accept-Language": "en" } }));
    parse(schemas.envelope(schemas.publicStorefrontDto), live);
    expect(live.data.campaign).toMatchObject({
      id: liveId, themeId: "valentine", glyph: "heart", accent: "#E5484D", title: "For two",
      targets: [{ productId: PLUS_3M, discountPercent: 30, iosOfferCode: "VALENTIN27", webPromotion: true }],
    });
    expect(live.data.appIcon).toBe("AppIcon-valentine");
    // The campaign ends in a day: the instant is written with the Paris offset.
    expect(live.data.nextChangeAt).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+0[12]:00$/);
    await db`UPDATE storefront_campaigns SET status = 'cancelled' WHERE id = ${liveId}`;
    const over = await read(await fetch(PUBLIC));
    expect([over.data.campaign, over.data.appIcon]).toEqual([null, null]);
    const user = await makeUser("sf-after");
    expect((await post(user.token, { offer: "plus_3m", ...WAIVER })).status).toBe(200);
    expect(Object.keys((await lastSessionFor(user.id))?.params ?? {}).some((key) => key.startsWith("discounts"))).toBe(false);
  });
});

describe("the OpenAPI document", () => {
  test("is served to the staff outside production and is the committed one", async () => {
    const response = await send("admin", "GET", "/openapi.json");
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual(JSON.parse(JSON.stringify(buildOpenApi())));
  });
});
