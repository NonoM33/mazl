import { beforeEach, describe, expect, test } from "bun:test";
import { CampaignService } from "../../../src/features/storefront/application/campaign-service";
import { CatalogService } from "../../../src/features/storefront/application/catalog-service";
import { buildPublicStorefront } from "../../../src/features/storefront/application/public-storefront";
import { campaignStatus, type CampaignInput } from "../../../src/features/storefront/domain/campaign";
import {
  CampaignNotEditableError,
  CampaignOverlapError,
  CampaignStateError,
  InvalidCampaignError,
  InvalidPriceChangeError,
  ProductNotFoundError,
  StoreCallError,
  StoreNotConfiguredError,
} from "../../../src/features/storefront/domain/errors";
import { appStoreNotConfigured, webPricingNotConfigured } from "../../../src/features/storefront/infra/not-configured";
import { FakeApple, FakeStripe, MemoryAudit, MemoryRepository } from "./fakes";

const D = (iso: string): Date => new Date(iso);
const PLUS_3M = "com.mazl.app.plus.3m";
const PLUS_12M = "com.mazl.app.plus.12m";
const BOOST_1 = "com.mazl.app.boost.1";
const ACTOR = "staff@example.com";
const NOW = D("2027-02-01T10:00:00Z");

const texts = { fr: { title: "Pour deux", subtitle: "Offrez-vous mazl+", cta: "J'en profite" }, en: { title: "For two", subtitle: "Treat yourself", cta: "Get it" } };

function input(overrides: Partial<CampaignInput> = {}): CampaignInput {
  return {
    themeId: "valentine",
    name: "Saint-Valentin 2027",
    startsAt: D("2027-02-06T23:00:00Z"),
    endsAt: D("2027-02-14T23:00:00Z"),
    texts,
    targets: [{ productId: PLUS_3M, discountPercent: 30 }],
    changeAppIcon: true,
    ...overrides,
  };
}

let repository: MemoryRepository;
let audit: MemoryAudit;
let apple: FakeApple;
let stripe: FakeStripe;
let clock: Date;
const env = { STRIPE_PRICE_PLUS_3M: "price_env_plus_3m", STRIPE_PRICE_PLUS_12M: "price_env_plus_12m" };

const deps = () => ({ repository, apple, web: stripe, audit, env, now: () => clock });
const catalog = () => new CatalogService(deps());
const campaigns = () => new CampaignService(deps());

beforeEach(() => {
  repository = new MemoryRepository();
  audit = new MemoryAudit();
  apple = new FakeApple();
  stripe = new FakeStripe();
  clock = NOW;
});

describe("campaign publication", () => {
  test("creates the Apple code and the Stripe promotion, then schedules and audits", async () => {
    const draft = await campaigns().create(ACTOR, input());
    const published = await campaigns().publish(ACTOR, draft.id);
    expect(published.status).toBe("scheduled");
    expect(apple.created).toHaveLength(1);
    expect(apple.created[0]).toMatchObject({ productId: PLUS_3M, customCode: "VALENTIN27", discountPercent: 30, expiresOn: "2027-02-14" });
    expect(published.apple.codes).toEqual([{ productId: PLUS_3M, offerCodeId: "oc_1", customCodeId: "cc_1", customCode: "VALENTIN27" }]);
    // The Stripe promotion applies to the price in use (the environment's until the catalogue has one), until the end.
    expect(stripe.promotions).toHaveLength(1);
    expect(stripe.promotions[0]).toMatchObject({ percentOff: 30, prices: ["price_env_plus_3m"], redeemBy: D("2027-02-14T23:00:00Z") });
    expect(published.stripe.promotions).toHaveLength(1);
    expect(audit.entries.map((e) => e.action)).toEqual(["storefront.campaign.create", "storefront.campaign.publish"]);
    expect(audit.entries[1]).toMatchObject({ actor: ACTOR, targetType: "storefront_campaign", targetId: String(draft.id) });
  });

  test("a campaign with several subscriptions gets one code each; a pack only a web promotion", async () => {
    const draft = await campaigns().create(
      ACTOR,
      input({ targets: [{ productId: PLUS_3M, discountPercent: 30 }, { productId: PLUS_12M, discountPercent: 20 }, { productId: BOOST_1, discountPercent: 10 }] }),
    );
    await repository.setStripePriceId(BOOST_1, "price_boost_catalogue", ACTOR);
    const published = await campaigns().publish(ACTOR, draft.id);
    expect(published.apple.codes.map((c) => c.customCode)).toEqual(["VALENTIN27M3", "VALENTIN27M12"]);
    expect(apple.created.map((r) => r.productId)).toEqual([PLUS_3M, PLUS_12M]);
    // The boost pack has a catalogue price: promotion only on the web. Its environment variable is unset.
    expect(published.stripe.promotions.map((p) => p.productId)).toEqual([PLUS_3M, PLUS_12M, BOOST_1]);
  });

  test("a product with no web price gets no Stripe promotion", async () => {
    const draft = await campaigns().create(ACTOR, input({ targets: [{ productId: BOOST_1, discountPercent: 10 }] }));
    const published = await campaigns().publish(ACTOR, draft.id);
    expect(stripe.promotions).toHaveLength(0);
    expect(published.status).toBe("scheduled");
    expect(apple.created).toHaveLength(0);
  });

  test("an Apple failure leaves a draft with the error; the next attempt reuses what exists", async () => {
    const draft = await campaigns().create(ACTOR, input({ targets: [{ productId: PLUS_3M, discountPercent: 30 }, { productId: PLUS_12M, discountPercent: 20 }] }));
    apple.failAfterCreates = 1;
    await expect(campaigns().publish(ACTOR, draft.id)).rejects.toBeInstanceOf(StoreCallError);
    const afterFailure = await campaigns().get(draft.id);
    expect(afterFailure.status).toBe("draft");
    expect(afterFailure.apple.error).toContain("apple down");
    expect(afterFailure.apple.codes).toHaveLength(1);
    expect(stripe.calls).not.toContain("createPromotion");

    apple.failAfterCreates = Number.POSITIVE_INFINITY;
    const published = await campaigns().publish(ACTOR, draft.id);
    expect(published.status).toBe("scheduled");
    expect(apple.created.map((r) => r.productId)).toEqual([PLUS_3M, PLUS_12M]); // the first one was not created twice
    expect(published.apple.error).toBeNull();
    expect(published.apple.codes).toHaveLength(2);
  });

  test("a Stripe failure leaves a draft, keeps the Apple codes and the error", async () => {
    const draft = await campaigns().create(ACTOR, input());
    stripe.fail = true;
    await expect(campaigns().publish(ACTOR, draft.id)).rejects.toBeInstanceOf(StoreCallError);
    const after = await campaigns().get(draft.id);
    expect([after.status, after.stripe.error, after.apple.codes.length]).toEqual(["draft", "stripe: stripe down", 1]);
  });

  test("nothing is configured: store_not_configured, still a draft, nothing sent", async () => {
    const service = new CampaignService({ ...deps(), apple: appStoreNotConfigured, web: webPricingNotConfigured });
    const draft = await service.create(ACTOR, input());
    await expect(service.publish(ACTOR, draft.id)).rejects.toBeInstanceOf(StoreNotConfiguredError);
    expect((await service.get(draft.id)).status).toBe("draft");
  });

  test("two scheduled campaigns never overlap, and the Apple codes are not created for the loser", async () => {
    const first = await campaigns().create(ACTOR, input());
    await campaigns().publish(ACTOR, first.id);
    const second = await campaigns().create(ACTOR, input({ name: "Autre", startsAt: D("2027-02-10T00:00:00Z"), endsAt: D("2027-02-20T00:00:00Z") }));
    const before = apple.created.length;
    await expect(campaigns().publish(ACTOR, second.id)).rejects.toBeInstanceOf(CampaignOverlapError);
    expect(apple.created.length).toBe(before);
  });

  test("only a draft, not already over, is published", async () => {
    const draft = await campaigns().create(ACTOR, input());
    await campaigns().publish(ACTOR, draft.id);
    await expect(campaigns().publish(ACTOR, draft.id)).rejects.toBeInstanceOf(CampaignStateError);
    const old = await campaigns().create(ACTOR, input({ name: "Passée", startsAt: D("2027-01-01T00:00:00Z"), endsAt: D("2027-01-05T00:00:00Z") }));
    await expect(campaigns().publish(ACTOR, old.id)).rejects.toBeInstanceOf(InvalidCampaignError);
  });

  test("a code is never reused from a cancelled campaign of the same theme and year", async () => {
    const first = await campaigns().create(ACTOR, input());
    await campaigns().publish(ACTOR, first.id);
    await campaigns().cancel(ACTOR, first.id);
    const again = await campaigns().create(ACTOR, input({ name: "Seconde" }));
    const published = await campaigns().publish(ACTOR, again.id);
    expect(published.apple.codes[0]?.customCode).toBe("VALENTIN27B");
  });
});

describe("campaign cancellation", () => {
  test("deactivates the Apple code and the Stripe promotion, then cancels", async () => {
    const draft = await campaigns().create(ACTOR, input());
    const published = await campaigns().publish(ACTOR, draft.id);
    const cancelled = await campaigns().cancel(ACTOR, draft.id);
    expect(cancelled.status).toBe("cancelled");
    expect(apple.deactivated).toEqual([published.apple.codes[0]!]);
    expect(stripe.deactivated).toEqual([{ couponId: published.stripe.promotions[0]!.couponId, promotionCodeId: published.stripe.promotions[0]!.promotionCodeId }]);
    expect(audit.entries.at(-1)?.action).toBe("storefront.campaign.cancel");
  });

  test("a store that refuses leaves the campaign as it was, with the error", async () => {
    const draft = await campaigns().create(ACTOR, input());
    await campaigns().publish(ACTOR, draft.id);
    apple.failOn = "deactivate";
    await expect(campaigns().cancel(ACTOR, draft.id)).rejects.toBeInstanceOf(StoreCallError);
    const after = await campaigns().get(draft.id);
    expect(after.status).toBe("scheduled");
    expect(after.apple.error).toContain("apple down");
    apple.failOn = null;
    expect((await campaigns().cancel(ACTOR, draft.id)).status).toBe("cancelled");
  });

  test("a draft with no code cancels without touching the stores, even unconfigured", async () => {
    const service = new CampaignService({ ...deps(), apple: appStoreNotConfigured, web: webPricingNotConfigured });
    const draft = await service.create(ACTOR, input());
    expect((await service.cancel(ACTOR, draft.id)).status).toBe("cancelled");
  });

  test("an ended or cancelled campaign cannot be cancelled", async () => {
    const draft = await campaigns().create(ACTOR, input());
    await campaigns().cancel(ACTOR, draft.id);
    await expect(campaigns().cancel(ACTOR, draft.id)).rejects.toBeInstanceOf(CampaignStateError);
  });
});

describe("edits", () => {
  test("a live campaign can end earlier but nothing else", async () => {
    const draft = await campaigns().create(ACTOR, input());
    await campaigns().publish(ACTOR, draft.id);
    clock = D("2027-02-10T00:00:00Z");
    const shortened = await campaigns().update(ACTOR, draft.id, { endsAt: D("2027-02-12T00:00:00Z") });
    expect(shortened.endsAt).toEqual(D("2027-02-12T00:00:00Z"));
    await expect(campaigns().update(ACTOR, draft.id, { name: "Autre" })).rejects.toBeInstanceOf(CampaignNotEditableError);
  });
});

describe("presets", () => {
  test("one per theme with the dates, flagging the existing and conflicting campaigns", async () => {
    const draft = await campaigns().create(ACTOR, input());
    await campaigns().publish(ACTOR, draft.id);
    const presets = await campaigns().presets(2027);
    expect(presets).toHaveLength(11);
    const valentine = presets.find((p) => p.themeId === "valentine")!;
    expect(valentine).toMatchObject({ eventStart: "2027-02-14", past: false, existing: [{ id: draft.id, status: "scheduled" }], conflicts: [{ id: draft.id }] });
    expect(presets.find((p) => p.themeId === "purim")).toMatchObject({ eventStart: "2027-03-23", existing: [], conflicts: [] });
    expect(presets.find((p) => p.themeId === "christmas")!.overlapsThemes).toContain("hanukkah"); // Hanukkah 2027 begins on 25 December
  });

  test("a year out of range is refused", async () => {
    await expect(campaigns().presets(1999)).rejects.toBeInstanceOf(InvalidCampaignError);
  });
});

describe("price writes", () => {
  test("the dry run writes nothing: no journal, no audit, Apple not asked to apply", async () => {
    const result = await catalog().changeApplePrice(ACTOR, PLUS_3M, { pricePointId: "pp_1", startDate: "2027-03-01", preserveCurrentPrice: true, dryRun: true });
    expect(result.dryRun).toBe(true);
    expect(result.plan.changes).toHaveLength(2);
    expect(apple.calls).toEqual(["planPriceChange"]);
    expect(repository.priceChanges).toHaveLength(0);
    expect(audit.entries).toHaveLength(0);
  });

  test("the real write plans again, applies, journals every country and audits", async () => {
    const result = await catalog().changeApplePrice(ACTOR, PLUS_3M, { pricePointId: "pp_1", startDate: "2027-03-01", preserveCurrentPrice: true, dryRun: false });
    expect(result.dryRun).toBe(false);
    expect(apple.calls).toEqual(["planPriceChange", "applyPriceChange"]);
    expect(repository.priceChanges.map((c) => [c.territory, c.oldPrice, c.newPrice, c.result, c.actor])).toEqual([
      ["FRA", "24.99", "26.99", "applied", ACTOR],
      ["USA", null, "28.99", "applied", ACTOR],
    ]);
    expect(audit.entries).toHaveLength(1);
    expect(audit.entries[0]).toMatchObject({ action: "storefront.price.apple", targetType: "storefront_product", targetId: PLUS_3M });
    expect(audit.entries[0]?.details).toMatchObject({ result: "applied", territories: 2, preserveCurrentPrice: true });
  });

  test("an Apple refusal is journaled as failed and audited, then raised", async () => {
    apple.failOn = "apply";
    await expect(catalog().changeApplePrice(ACTOR, PLUS_3M, { pricePointId: "pp_1", startDate: "2027-03-01", preserveCurrentPrice: false, dryRun: false })).rejects.toBeInstanceOf(StoreCallError);
    expect(repository.priceChanges.every((c) => c.result === "failed" && (c.error ?? "").includes("apple refused"))).toBe(true);
    expect(audit.entries[0]?.details).toMatchObject({ result: "failed" });
  });

  test("the start date is a real date from today to two years", async () => {
    const attempt = (startDate: string) => catalog().changeApplePrice(ACTOR, PLUS_3M, { pricePointId: "pp_1", startDate, preserveCurrentPrice: true, dryRun: true });
    await expect(attempt("2027-01-31")).rejects.toBeInstanceOf(InvalidPriceChangeError);
    await expect(attempt("2027-02-30")).rejects.toBeInstanceOf(InvalidPriceChangeError);
    await expect(attempt("not-a-date")).rejects.toBeInstanceOf(InvalidPriceChangeError);
    await expect(attempt("2030-01-01")).rejects.toBeInstanceOf(InvalidPriceChangeError);
    await expect(attempt("2027-02-01")).resolves.toMatchObject({ dryRun: true });
    expect(apple.calls.filter((c) => c === "planPriceChange")).toHaveLength(1); // the refusals never reached Apple
  });

  test("an unknown product is refused before any store call", async () => {
    await expect(catalog().changeApplePrice(ACTOR, "com.mazl.app.nope", { pricePointId: "x", startDate: "2027-03-01", preserveCurrentPrice: true, dryRun: false })).rejects.toBeInstanceOf(ProductNotFoundError);
    await expect(catalog().changeWebPrice(ACTOR, "com.mazl.app.nope", { amountCents: 999, currency: "eur" })).rejects.toBeInstanceOf(ProductNotFoundError);
    expect(apple.calls).toHaveLength(0);
    expect(stripe.calls).toHaveLength(0);
  });

  test("a new web price: created at Stripe (monthly period for a subscription), then adopted by the catalogue", async () => {
    const result = await catalog().changeWebPrice(ACTOR, PLUS_3M, { amountCents: 2699, currency: "EUR" });
    expect(stripe.prices).toEqual([{ productId: PLUS_3M, amountCents: 2699, currency: "eur", months: 3 }]);
    expect(result.previousPriceId).toBe("price_env_plus_3m");
    expect((await repository.getProduct(PLUS_3M))?.stripePriceId).toBe("price_new_1");
    expect(repository.priceChanges).toEqual([
      { actor: ACTOR, productId: PLUS_3M, platform: "web", territory: null, oldPrice: "24.99", newPrice: "26.99", currency: "EUR", effectiveDate: "2027-02-01", result: "applied", error: null },
    ]);
    expect(audit.entries[0]).toMatchObject({ action: "storefront.price.web", targetId: PLUS_3M });
    // Next time, the catalogue's price is the "previous" one.
    expect((await catalog().changeWebPrice(ACTOR, PLUS_3M, { amountCents: 2799, currency: "eur" })).previousPriceId).toBe("price_new_1");
  });

  test("a pack is a one-off price", async () => {
    await catalog().changeWebPrice(ACTOR, BOOST_1, { amountCents: 249, currency: "eur" });
    expect(stripe.prices[0]).toMatchObject({ productId: BOOST_1, months: null });
  });

  test("a Stripe failure leaves the catalogue untouched and is journaled", async () => {
    stripe.fail = true;
    await expect(catalog().changeWebPrice(ACTOR, PLUS_3M, { amountCents: 2699, currency: "eur" })).rejects.toBeInstanceOf(StoreCallError);
    expect((await repository.getProduct(PLUS_3M))?.stripePriceId).toBeNull();
    expect(repository.priceChanges[0]).toMatchObject({ result: "failed" });
  });

  test("amounts out of bounds never reach Stripe", async () => {
    for (const amountCents of [0, 49, 1_000_001, 12.5]) {
      await expect(catalog().changeWebPrice(ACTOR, PLUS_3M, { amountCents, currency: "eur" })).rejects.toBeInstanceOf(InvalidPriceChangeError);
    }
    expect(stripe.calls).toHaveLength(0);
  });
});

describe("catalogue", () => {
  test("lists the products with the real prices; a store down degrades its block only", async () => {
    stripe.fail = true;
    const dead = new CatalogService({ ...deps(), web: { ...stripe, currentPrice: () => Promise.reject(new Error("down")) } as unknown as FakeStripe });
    const products = await dead.listProducts();
    expect(products).toHaveLength(8);
    const plus3 = products.find((p) => p.productId === PLUS_3M)!;
    expect(plus3.prices.apple).toMatchObject({ status: "ok" });
    expect(plus3.prices.web).toEqual({ status: "unavailable", error: "store_error" });
    expect(plus3).toMatchObject({ kind: "subscription", months: 3, effectiveStripePriceId: "price_env_plus_3m" });
  });

  test("with no adapter, the list still answers, with 'store_not_configured'", async () => {
    const service = new CatalogService({ ...deps(), apple: appStoreNotConfigured, web: webPricingNotConfigured });
    const products = await service.listProducts();
    expect(products[0]?.prices.apple).toEqual({ status: "unavailable", error: "store_not_configured" });
  });

  test("an edit is audited with the fields that changed", async () => {
    await catalog().updateProduct(ACTOR, PLUS_3M, { featured: false, highlight: { fr: "Populaire" } });
    expect(audit.entries[0]).toMatchObject({ action: "storefront.product.update", details: { fields: ["featured", "highlight"] } });
    expect((await repository.getProduct(PLUS_3M))?.highlight).toEqual({ fr: "Populaire" });
  });
});

describe("public storefront", () => {
  test("no campaign: the products in order, no icon, nothing next", async () => {
    await repository.updateProduct(PLUS_3M, { highlight: { fr: "Le plus choisi", en: "Most popular" } }, ACTOR);
    const view = await buildPublicStorefront(repository, NOW, "fr");
    expect(view.campaign).toBeNull();
    expect(view.appIcon).toBeNull();
    expect(view.nextChangeAt).toBeNull();
    expect(view.serverTime).toBe("2027-02-01T10:00:00.000Z");
    expect(view.products.map((p) => p.productId)).toEqual(["com.mazl.app.plus.1m", PLUS_3M, "com.mazl.app.plus.6m", PLUS_12M, "com.mazl.app.boost.1", "com.mazl.app.boost.3", "com.mazl.app.superlikes.5", "com.mazl.app.superlikes.15"]);
    expect(view.products.find((p) => p.productId === PLUS_3M)).toMatchObject({ featured: true, highlight: "Le plus choisi" });
    expect((await buildPublicStorefront(repository, NOW, "en")).products.find((p) => p.productId === PLUS_3M)?.highlight).toBe("Most popular");
    expect((await buildPublicStorefront(repository, NOW, "ru")).products.find((p) => p.productId === PLUS_3M)?.highlight).toBe("Le plus choisi");
  });

  test("a scheduled campaign: next change is its start; live: the campaign, the icon, the end", async () => {
    const draft = await campaigns().create(ACTOR, input());
    await campaigns().publish(ACTOR, draft.id);
    const before = await buildPublicStorefront(repository, NOW, "fr");
    expect(before.campaign).toBeNull();
    expect(before.nextChangeAt).toBe("2027-02-07T00:00:00+01:00");

    const live = await buildPublicStorefront(repository, D("2027-02-10T09:00:00Z"), "en");
    expect(live.campaign).toMatchObject({
      id: draft.id,
      themeId: "valentine",
      accent: "#E5484D",
      glyph: "heart",
      title: "For two",
      cta: "Get it",
      targets: [{ productId: PLUS_3M, discountPercent: 30, iosOfferCode: "VALENTIN27", webPromotion: true }],
    });
    expect(live.appIcon).toBe("AppIcon-valentine");
    expect(live.nextChangeAt).toBe("2027-02-15T00:00:00+01:00");

    const after = await buildPublicStorefront(repository, D("2027-02-15T00:00:00Z"), "fr");
    expect([after.campaign, after.appIcon, after.nextChangeAt]).toEqual([null, null, null]);
  });

  test("no icon when the campaign does not change it; no offer code until Apple created it; a missing language falls back to French", async () => {
    const draft = await campaigns().create(ACTOR, input({ changeAppIcon: false }));
    await repository.saveCampaignState(draft.id, { status: "scheduled" }); // as if Apple had not created anything
    const live = await buildPublicStorefront(repository, D("2027-02-10T09:00:00Z"), "ru");
    expect(live.appIcon).toBeNull();
    expect(live.campaign?.title).toBe("Pour deux");
    expect(live.campaign?.targets[0]).toEqual({ productId: PLUS_3M, discountPercent: 30, webPromotion: false });
  });

  test("a cancelled or draft campaign never shows", async () => {
    const draft = await campaigns().create(ACTOR, input());
    expect((await buildPublicStorefront(repository, D("2027-02-10T09:00:00Z"), "fr")).campaign).toBeNull();
    await campaigns().cancel(ACTOR, draft.id);
    expect((await buildPublicStorefront(repository, D("2027-02-10T09:00:00Z"), "fr")).campaign).toBeNull();
    expect(campaignStatus((await campaigns().get(draft.id)), D("2027-02-10T09:00:00Z"))).toBe("cancelled");
  });
});
