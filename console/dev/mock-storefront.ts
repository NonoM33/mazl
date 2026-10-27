// Maquette de /api/backoffice/storefront : mêmes formes que le serveur (src/features/storefront/presentation/schemas.ts), état en mémoire.
// tests/unit/console-storefront-contract.test.ts valide chaque réponse de cette maquette contre les schémas du serveur.
// Prix : ceux de docs/premium/APP-STORE-CONNECT.md pour la France, les États-Unis et le Royaume-Uni des abonnements ;
// Israël, Canada et les consommables hors France sont fictifs mais plausibles. Aucune donnée de membre.
//
// Pour voir les erreurs du serveur : un nom de campagne qui contient « erreur Apple » est refusé par Apple à la programmation
// (502 store_error) ; « sans clés » donne 503 store_not_configured.
import type { Hono } from "hono";
import { defaultTexts } from "../src/storefront/theme-texts";
import { parisLocalToIso } from "../src/storefront/paris-time";
import { THEMES, themeById } from "../src/storefront/themes";
import { campaignState } from "../src/storefront/campaign-state";
import { THEME_IDS, type ApplePlanDto, type CampaignDto, type CampaignInput, type LocalizedText, type PresetDto, type PricePointDto, type ProductDisplayDto, type ProductDto, type StorePriceDto, type ThemeId, type WebPriceDto } from "../src/storefront/types";
import type { MeDto } from "../src/shared/api/contracts";

const DAY = 86_400_000;
const HOUR = 3_600_000;

// ---------- Dates des fêtes (mêmes règles que docs/storefront/themes.json) ----------

const dayString = (ms: number): string => new Date(ms).toISOString().slice(0, 10);
const utcDay = (year: number, month: number, day: number): number => Date.UTC(year, month - 1, day);

function hebrewDay(year: number, month: RegExp, day: number): number {
  const formatter = new Intl.DateTimeFormat("en-u-ca-hebrew", { timeZone: "UTC", day: "numeric", month: "long" });
  for (let ms = utcDay(year, 1, 1); ms < utcDay(year + 1, 1, 1); ms += DAY) {
    const parts = formatter.formatToParts(ms);
    const m = parts.find((p) => p.type === "month")?.value ?? "";
    const d = Number(parts.find((p) => p.type === "day")?.value);
    if (d === day && month.test(m)) return ms;
  }
  throw new Error(`Date hébraïque introuvable en ${year}`);
}

function easter(year: number): number {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const dayOfMonth = ((h + l - 7 * m + 114) % 31) + 1;
  return utcDay(year, month, dayOfMonth);
}

const lastSunday = (year: number, month: number): number => {
  let ms = utcDay(year, month + 1, 0 + 1) - DAY;
  while (new Date(ms).getUTCDay() !== 0) ms -= DAY;
  return ms;
};

function nthWeekday(year: number, month: number, weekday: number, n: number): number {
  let ms = utcDay(year, month, 1);
  while (new Date(ms).getUTCDay() !== weekday) ms += DAY;
  return ms + (n - 1) * 7 * DAY;
}

interface Event {
  readonly first: number;
  readonly days: number;
}

function eventOf(themeId: ThemeId, year: number): Event {
  switch (themeId) {
    case "valentine": return { first: utcDay(year, 2, 14), days: 1 };
    case "tu_bav": return { first: hebrewDay(year, /^Av$/, 15), days: 1 };
    case "rosh_hashana": return { first: hebrewDay(year, /^Tishri$/, 1), days: 2 };
    case "hanukkah": return { first: hebrewDay(year, /^Kislev$/, 25), days: 8 };
    case "christmas": return { first: utcDay(year, 12, 25), days: 1 };
    case "new_year": return { first: utcDay(year, 1, 1), days: 1 };
    case "purim": return { first: hebrewDay(year, /^Adar( II)?$/, 14), days: 1 };
    case "passover": return { first: hebrewDay(year, /^Nisan$/, 15), days: 7 };
    case "mothers_day": {
      const pentecost = easter(year) + 49 * DAY;
      const lastMay = lastSunday(year, 5);
      return { first: lastMay === pentecost ? nthWeekday(year, 6, 0, 1) : lastMay, days: 1 };
    }
    case "summer": return { first: utcDay(year, 7, 1), days: 14 };
    case "black_friday": return { first: nthWeekday(year, 11, 5, 4), days: 4 };
  }
}

const WINDOWS: Readonly<Record<ThemeId, readonly [number, number]>> = { valentine: [7, 0], tu_bav: [5, 0], rosh_hashana: [7, 0], hanukkah: [2, 0], christmas: [10, 1], new_year: [4, 2], purim: [3, 0], passover: [5, 0], mothers_day: [6, 0], summer: [0, 0], black_friday: [0, 0] };

function presetFor(themeId: ThemeId, year: number): PresetDto {
  const event = eventOf(themeId, year);
  const [before, after] = WINDOWS[themeId];
  const hebrew = themeById(themeId).hebrew;
  const start = event.first - (before + (hebrew ? 1 : 0)) * DAY;
  const endExclusive = event.first + (event.days - 1 + after + 1) * DAY;
  const theme = themeById(themeId);
  const startsAt = parisLocalToIso(`${dayString(start)}T00:00`) ?? "";
  const endsAt = parisLocalToIso(`${dayString(endExclusive)}T00:00`) ?? "";
  return {
    themeId,
    glyph: theme.glyph,
    accent: theme.accent,
    name: `${themeId} ${year}`,
    eventStart: dayString(event.first),
    eventEnd: dayString(event.first + (event.days - 1) * DAY),
    startsAt,
    endsAt,
    past: Date.parse(endsAt) <= Date.now(),
    existing: [],
    conflicts: [],
    overlapsThemes: [],
  };
}

// ---------- Catalogue ----------

const eur = (amount: string): StorePriceDto => ({ territory: "FRA", currency: "EUR", customerPrice: amount });
const prices = (fr: string, us: string, gb: string, il: string, ca: string): readonly StorePriceDto[] => [eur(fr), { territory: "USA", currency: "USD", customerPrice: us }, { territory: "GBR", currency: "GBP", customerPrice: gb }, { territory: "ISR", currency: "ILS", customerPrice: il }, { territory: "CAN", currency: "CAD", customerPrice: ca }];
const hl = (fr: string, en: string, he: string, es: string, ru: string): LocalizedText => ({ fr, en, he, es, ru });

interface ProductSeed {
  readonly productId: string;
  readonly kind: ProductDto["kind"];
  readonly months: number | null;
  readonly featured: boolean;
  readonly highlight: LocalizedText | null;
  readonly apple: readonly StorePriceDto[];
  readonly webCents: number | null;
}

const STAMP = "2026-10-20T09:00:00.000Z";

function productOf(seed: ProductSeed, sortOrder: number, visible = true): ProductDto {
  const priceId = seed.webCents === null ? null : `price_example_${seed.productId.split(".").slice(-2).join("")}`;
  const web: readonly WebPriceDto[] = seed.webCents === null || priceId === null ? [] : [{ priceId, amountCents: seed.webCents, currency: "EUR" }];
  return {
    productId: seed.productId,
    visible,
    sortOrder,
    featured: seed.featured,
    highlight: seed.highlight,
    stripePriceId: priceId,
    updatedAt: STAMP,
    updatedBy: null,
    kind: seed.kind,
    months: seed.months,
    effectiveStripePriceId: priceId,
    prices: { apple: { status: "ok", items: [...seed.apple] }, web: { status: "ok", items: [...web] } },
  };
}

const products: ProductDto[] = [
  productOf({ productId: "com.mazl.app.plus.12m", kind: "subscription", months: 12, featured: false, highlight: hl("Le plus économique", "Best value", "הכי משתלם", "El más económico", "Самый выгодный"), apple: prices("99.99", "119.99", "89.99", "399.90", "149.99"), webCents: 9999 }, 0),
  productOf({ productId: "com.mazl.app.plus.6m", kind: "subscription", months: 6, featured: false, highlight: null, apple: prices("69.99", "79.99", "64.99", "249.90", "99.99"), webCents: 6999 }, 1),
  productOf({ productId: "com.mazl.app.plus.3m", kind: "subscription", months: 3, featured: true, highlight: hl("Le plus choisi", "Most popular", "הנבחר ביותר", "El más elegido", "Самый популярный"), apple: prices("44.99", "49.99", "39.99", "179.90", "64.99"), webCents: 4499 }, 2),
  productOf({ productId: "com.mazl.app.plus.1m", kind: "subscription", months: 1, featured: false, highlight: null, apple: prices("19.99", "19.99", "17.99", "69.90", "26.99"), webCents: 1999 }, 3),
  productOf({ productId: "com.mazl.app.boost.1", kind: "credits", months: null, featured: false, highlight: null, apple: prices("7.99", "6.99", "6.99", "29.90", "8.99"), webCents: 799 }, 4),
  productOf({ productId: "com.mazl.app.boost.3", kind: "credits", months: null, featured: false, highlight: null, apple: prices("19.99", "19.99", "17.99", "69.90", "26.99"), webCents: 1999 }, 5),
  productOf({ productId: "com.mazl.app.superlikes.5", kind: "credits", months: null, featured: false, highlight: null, apple: prices("4.99", "4.99", "4.49", "19.90", "6.49"), webCents: null }, 6),
  productOf({ productId: "com.mazl.app.superlikes.15", kind: "credits", months: null, featured: false, highlight: null, apple: prices("11.99", "11.99", "10.99", "49.90", "15.99"), webCents: null }, 7, false),
];

const displayOf = (product: ProductDto): ProductDisplayDto => ({
  productId: product.productId,
  visible: product.visible,
  sortOrder: product.sortOrder,
  featured: product.featured,
  highlight: product.highlight,
  stripePriceId: product.stripePriceId,
  updatedAt: product.updatedAt,
  updatedBy: product.updatedBy,
});

const TIERS = [0.99, 1.99, 2.99, 3.99, 4.99, 5.99, 6.99, 7.99, 8.99, 9.99, 11.99, 12.99, 14.99, 15.99, 17.99, 19.99, 21.99, 24.99, 29.99, 34.99, 39.99, 44.99, 49.99, 54.99, 59.99, 64.99, 69.99, 79.99, 89.99, 99.99, 109.99, 119.99, 129.99, 149.99];
const FACTORS: Readonly<Record<string, { readonly factor: number; readonly currency: string; readonly ending: number }>> = { FRA: { factor: 1, currency: "EUR", ending: 0.99 }, USA: { factor: 1.11, currency: "USD", ending: 0.99 }, GBR: { factor: 0.9, currency: "GBP", ending: 0.99 }, ISR: { factor: 4, currency: "ILS", ending: 0.9 }, CAN: { factor: 1.45, currency: "CAD", ending: 0.99 } };

const convert = (frAmount: number, territory: string): string => {
  const rule = FACTORS[territory] ?? { factor: 1, ending: 0.99 };
  const raw = frAmount * rule.factor;
  return (Math.max(0, Math.round(raw - rule.ending) + rule.ending)).toFixed(2);
};

// ---------- Campagnes ----------

/** Une campagne telle qu'elle est rangée : le serveur ne range que brouillon, programmée ou annulée ; « en cours » et « terminée » se calculent. */
type StoredCampaign = Omit<CampaignDto, "status"> & { status: "draft" | "scheduled" | "cancelled" };

const campaigns: StoredCampaign[] = [];
let nextId = 1;
const now = (): number => Date.now();
const viewOf = (campaign: StoredCampaign): CampaignDto => ({ ...campaign, status: campaignState(campaign, new Date(now())) });

const codeFor = (themeId: ThemeId, startsAt: string): string => `${themeId.replace(/_/g, "").toUpperCase().slice(0, 10)}${startsAt.slice(2, 4)}`;
const isSubscription = (productId: string): boolean => products.find((p) => p.productId === productId)?.kind === "subscription";
const soldOnWeb = (productId: string): boolean => products.find((p) => p.productId === productId)?.effectiveStripePriceId != null;

function scheduleArtifacts(campaign: StoredCampaign): Pick<StoredCampaign, "apple" | "stripe"> {
  const code = codeFor(campaign.themeId, campaign.startsAt);
  const subscriptions = campaign.targets.filter((target) => isSubscription(target.productId));
  return {
    apple: { codes: subscriptions.map((target, i) => ({ productId: target.productId, offerCodeId: `offer_example_${campaign.id}_${i}`, customCodeId: `code_example_${campaign.id}_${i}`, customCode: `${code}${i === 0 ? "" : i + 1}` })), error: null },
    stripe: { promotions: campaign.targets.filter((target) => soldOnWeb(target.productId)).map((target, i) => ({ productId: target.productId, couponId: `coupon_example_${campaign.id}_${i}`, promotionCodeId: `promo_example_${campaign.id}_${i}` })), error: null },
  };
}

function makeCampaign(themeId: ThemeId, input: Partial<CampaignInput> & { readonly startsAt: string; readonly endsAt: string }, status: StoredCampaign["status"], name?: string): StoredCampaign {
  const stamp = new Date(now() - 20 * DAY).toISOString();
  const campaign: StoredCampaign = {
    id: nextId,
    themeId,
    name: name ?? input.name ?? `${themeById(themeId).label} ${input.startsAt.slice(0, 4)}`,
    startsAt: input.startsAt,
    endsAt: input.endsAt,
    texts: input.texts ?? defaultTexts(themeId),
    targets: input.targets ?? ["com.mazl.app.plus.12m", "com.mazl.app.plus.6m", "com.mazl.app.plus.3m", "com.mazl.app.plus.1m"].map((productId) => ({ productId, discountPercent: themeId === "black_friday" ? 40 : 30 })),
    changeAppIcon: input.changeAppIcon ?? true,
    status,
    apple: { codes: [], error: null },
    stripe: { promotions: [], error: null },
    createdBy: "admin@example.com",
    createdAt: stamp,
    updatedAt: stamp,
  };
  nextId += 1;
  campaigns.push(campaign);
  if (status === "scheduled") Object.assign(campaign, scheduleArtifacts(campaign));
  return campaign;
}

function seed(): void {
  const year = new Date().getUTCFullYear();
  const take = (themeId: ThemeId, y: number, status: StoredCampaign["status"]): StoredCampaign => {
    const p = presetFor(themeId, y);
    return makeCampaign(themeId, { startsAt: p.startsAt, endsAt: p.endsAt }, status);
  };
  take("valentine", year, "scheduled");
  take("purim", year, "cancelled");
  take("mothers_day", year, "scheduled");
  take("summer", year, "scheduled");
  take("rosh_hashana", year, "scheduled");
  makeCampaign("black_friday", { startsAt: new Date(now() - 2 * DAY).toISOString(), endsAt: new Date(now() + 5 * DAY + 3 * HOUR).toISOString() }, "scheduled", "Black Friday (démarrage anticipé)");
  take("hanukkah", year, "scheduled");
  take("christmas", year, "draft");
  take("valentine", year + 1, "scheduled");
  take("mothers_day", year + 1, "draft");
}
seed();

// ---------- Routes ----------

type Guard = (c: never) => MeDto;
type Body = Record<string, unknown>;

export function registerStorefrontMock(api: Hono, meOf: Guard): void {
  const base = "/storefront";
  const ok = <T,>(data: T): { success: true; data: T } => ({ success: true, data });
  const fail = (error: string, message?: string): { success: false; error: string; message?: string } => (message === undefined ? { success: false, error } : { success: false, error, message });
  // Mêmes permissions que le serveur : lire et régler l'affichage = storefront.manage ; écrire chez Apple et Stripe = storefront.stores.
  const canManage = (c: never): boolean => meOf(c).permissions.includes("storefront.manage");
  const canWriteStores = (c: never): boolean => meOf(c).permissions.includes("storefront.stores");
  const json = async (c: { req: { json: () => Promise<unknown> } }): Promise<Body> => {
    try {
      const body = await c.req.json();
      return typeof body === "object" && body !== null ? (body as Body) : {};
    } catch {
      return {};
    }
  };
  const productById = (id: string): ProductDto | undefined => products.find((p) => p.productId === id);
  const replaceProduct = (next: ProductDto): void => {
    const index = products.findIndex((p) => p.productId === next.productId);
    if (index >= 0) products[index] = next;
  };
  const stamped = (): string => new Date().toISOString();

  api.get(`${base}/products`, (c) => (canManage(c as never) ? c.json(ok({ products: [...products].sort((a, b) => a.sortOrder - b.sortOrder) })) : c.json(fail("forbidden"), 403)));

  api.patch(`${base}/products/:id`, async (c) => {
    if (!canManage(c as never)) return c.json(fail("forbidden"), 403);
    const product = productById(c.req.param("id"));
    if (product === undefined) return c.json(fail("product_not_found"), 404);
    const body = await json(c);
    const next: ProductDto = {
      ...product,
      ...(typeof body["visible"] === "boolean" ? { visible: body["visible"] } : {}),
      ...(typeof body["featured"] === "boolean" ? { featured: body["featured"] } : {}),
      ...(typeof body["sortOrder"] === "number" ? { sortOrder: body["sortOrder"] } : {}),
      ...("highlight" in body ? { highlight: body["highlight"] as LocalizedText | null } : {}),
      updatedAt: stamped(),
      updatedBy: meOf(c as never).email,
    };
    replaceProduct(next);
    return c.json(ok(displayOf(next)));
  });

  api.get(`${base}/products/:id/apple-price-points`, (c) => {
    if (!canManage(c as never)) return c.json(fail("forbidden"), 403);
    const productId = c.req.param("id");
    if (productById(productId) === undefined) return c.json(fail("product_not_found"), 404);
    const territory = c.req.query("territory") ?? "FRA";
    const points: PricePointDto[] = TIERS.map((tier) => ({ id: `pp-${territory}-${Math.round(tier * 100)}`, territory, customerPrice: tier.toFixed(2), proceeds: (tier * 0.85).toFixed(2) }));
    return c.json(ok({ productId, territory, pricePoints: points }));
  });

  api.post(`${base}/products/:id/apple-price`, async (c) => {
    if (!canWriteStores(c as never)) return c.json(fail("forbidden", "Changer un prix est réservé aux super-administrateurs."), 403);
    const product = productById(c.req.param("id"));
    if (product === undefined) return c.json(fail("product_not_found"), 404);
    const body = await json(c);
    const match = /^pp-FRA-(\d+)$/.exec(String(body["pricePointId"] ?? ""));
    const startDate = String(body["startDate"] ?? "");
    if (match === null) return c.json(fail("store_error", "apple: price point not found"), 502);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(startDate) || startDate < new Date().toISOString().slice(0, 10)) return c.json(fail("invalid_price_change", "startDate cannot be in the past"), 400);
    const newFrance = Number(match[1]) / 100;
    const current = product.prices.apple.status === "ok" ? product.prices.apple.items : [];
    const changes: ApplePlanDto["changes"] = current.map((price) => ({ territory: price.territory, from: price.customerPrice, to: price.territory === "FRA" ? newFrance.toFixed(2) : convert(newFrance, price.territory), pricePointId: `pp-${price.territory}-${Math.round((price.territory === "FRA" ? newFrance : Number(convert(newFrance, price.territory))) * 100)}` }));
    const dryRun = body["dryRun"] !== false; // vrai par défaut, comme le serveur
    if (!dryRun) {
      replaceProduct({ ...product, prices: { ...product.prices, apple: { status: "ok", items: current.map((price) => ({ ...price, customerPrice: changes.find((change) => change.territory === price.territory)?.to ?? price.customerPrice })) } } });
    }
    return c.json(ok({ dryRun, plan: { productId: product.productId, startDate, preserveCurrentPrice: body["preserveCurrentPrice"] !== false, changes } }));
  });

  api.post(`${base}/products/:id/web-price`, async (c) => {
    if (!canWriteStores(c as never)) return c.json(fail("forbidden", "Changer un prix est réservé aux super-administrateurs."), 403);
    const product = productById(c.req.param("id"));
    if (product === undefined) return c.json(fail("product_not_found"), 404);
    const body = await json(c);
    const cents = body["amountCents"];
    const currency = body["currency"];
    if (typeof cents !== "number" || !Number.isInteger(cents) || cents < 50 || cents > 1_000_000 || typeof currency !== "string" || !/^[A-Za-z]{3}$/.test(currency)) return c.json(fail("invalid_body", "amountCents ou currency invalide"), 400);
    const price: WebPriceDto = { priceId: `price_example_${Math.random().toString(36).slice(2, 10)}`, amountCents: cents, currency: currency.toUpperCase() };
    const next: ProductDto = { ...product, stripePriceId: price.priceId, effectiveStripePriceId: price.priceId, prices: { ...product.prices, web: { status: "ok", items: [price] } }, updatedAt: stamped(), updatedBy: meOf(c as never).email };
    replaceProduct(next);
    return c.json(ok({ price, previousPriceId: product.effectiveStripePriceId, product: displayOf(next) }));
  });

  const overlapsRange = (a: { readonly startsAt: string; readonly endsAt: string }, b: { readonly startsAt: string; readonly endsAt: string }): boolean => Date.parse(a.startsAt) < Date.parse(b.endsAt) && Date.parse(b.startsAt) < Date.parse(a.endsAt);

  api.get(`${base}/campaigns/presets`, (c) => {
    if (!canManage(c as never)) return c.json(fail("forbidden"), 403);
    const rawYear = c.req.query("year");
    if (rawYear === undefined || !/^\d{4}$/.test(rawYear)) return c.json(fail("invalid_query", "year: de 2020 à 2100"), 400);
    const year = Number(rawYear);
    const presets = THEMES.map((theme) => presetFor(theme.id, year));
    const full = presets.map((preset): PresetDto => {
      const overlapping = campaigns.filter((campaign) => campaign.status !== "cancelled" && overlapsRange(campaign, preset));
      return {
        ...preset,
        existing: overlapping.filter((campaign) => campaign.themeId === preset.themeId).map((campaign) => ({ id: campaign.id, name: campaign.name, status: viewOf(campaign).status })),
        conflicts: overlapping.filter((campaign) => campaign.status === "scheduled").map((campaign) => ({ id: campaign.id, name: campaign.name })),
        overlapsThemes: presets.filter((other) => other.themeId !== preset.themeId && overlapsRange(preset, other)).map((other) => other.themeId),
      };
    });
    return c.json(ok({ year, presets: full.sort((a, b) => Date.parse(a.startsAt) - Date.parse(b.startsAt)) }));
  });

  api.get(`${base}/campaigns`, (c) => {
    if (!canManage(c as never)) return c.json(fail("forbidden"), 403);
    const rawYear = c.req.query("year");
    const year = rawYear === undefined ? null : Number(rawYear);
    if (year !== null && !(Number.isInteger(year) && year >= 2020 && year <= 2100)) return c.json(fail("invalid_query", "year: de 2020 à 2100"), 400);
    const from = year === null ? -Infinity : Date.UTC(year, 0, 1) - HOUR;
    const to = year === null ? Infinity : Date.UTC(year + 1, 0, 1) - HOUR;
    return c.json(ok({ campaigns: campaigns.filter((campaign) => Date.parse(campaign.startsAt) < to && Date.parse(campaign.endsAt) > from).map(viewOf) }));
  });

  const validate = (input: Partial<CampaignInput>): string | null => {
    if (input.themeId !== undefined && !(THEME_IDS as readonly string[]).includes(input.themeId)) return "Thème inconnu.";
    if (input.startsAt !== undefined && input.endsAt !== undefined) {
      const length = Date.parse(input.endsAt) - Date.parse(input.startsAt);
      if (!(length > 0)) return "La fin doit être après le début.";
      if (length > 45 * DAY) return "Une campagne dure 45 jours au plus.";
    }
    for (const target of input.targets ?? []) {
      if (productById(target.productId) === undefined) return `Produit inconnu : ${target.productId}.`;
      if (!Number.isInteger(target.discountPercent) || target.discountPercent < 5 || target.discountPercent > 90) return "Remise entre 5 et 90 %.";
    }
    return null;
  };

  api.post(`${base}/campaigns`, async (c) => {
    if (!canManage(c as never)) return c.json(fail("forbidden"), 403);
    const body = (await json(c)) as unknown as CampaignInput;
    const problem = validate(body);
    if (problem !== null || typeof body.name !== "string" || body.name.trim() === "") return c.json(fail("invalid_campaign", problem ?? "Nom obligatoire."), 400);
    const created = makeCampaign(body.themeId, body, "draft");
    Object.assign(created, { createdBy: meOf(c as never).email, createdAt: stamped(), updatedAt: stamped() });
    return c.json(ok(viewOf(created)), 201);
  });

  const indexOf = (id: string): number => campaigns.findIndex((campaign) => campaign.id === Number(id));

  api.patch(`${base}/campaigns/:id`, async (c) => {
    if (!canManage(c as never)) return c.json(fail("forbidden"), 403);
    const index = indexOf(c.req.param("id"));
    const current = campaigns[index];
    if (current === undefined) return c.json(fail("campaign_not_found"), 404);
    const body = (await json(c)) as Partial<CampaignInput>;
    const shown = viewOf(current).status;
    const keys = Object.keys(body);
    const endsEarlier = shown === "live" && keys.length === 1 && keys[0] === "endsAt" && Date.parse(body.endsAt ?? "") < Date.parse(current.endsAt);
    const contentOnly = shown === "scheduled" && keys.every((key) => ["name", "texts", "changeAppIcon"].includes(key));
    if (shown !== "draft" && !endsEarlier && !contentOnly) return c.json(fail("campaign_not_editable", `A ${shown} campaign cannot be edited that way`), 409);
    const next: StoredCampaign = { ...current, ...body, updatedAt: stamped() };
    const problem = validate(next);
    if (problem !== null) return c.json(fail("invalid_campaign", problem), 400);
    campaigns[index] = next;
    return c.json(ok(viewOf(next)));
  });

  api.post(`${base}/campaigns/:id/publish`, (c) => {
    if (!canWriteStores(c as never)) return c.json(fail("forbidden", "Programmer une campagne est réservé aux super-administrateurs."), 403);
    const index = indexOf(c.req.param("id"));
    const current = campaigns[index];
    if (current === undefined) return c.json(fail("campaign_not_found"), 404);
    if (current.status !== "draft") return c.json(fail("campaign_wrong_state", `Only a draft can be published (this one is ${viewOf(current).status})`), 409);
    if (current.name.includes("sans clés")) return c.json(fail("store_not_configured", "The apple store is not configured on this server"), 503);
    if (current.name.includes("erreur Apple")) {
      const reason = "ENTITY_ERROR.ATTRIBUTE.INVALID: the offer code is not valid for this subscription";
      campaigns[index] = { ...current, apple: { codes: current.apple.codes, error: reason } };
      return c.json(fail("store_error", `apple: ${reason}`), 502);
    }
    const clash = campaigns.find((other) => other.id !== current.id && other.status === "scheduled" && overlapsRange(current, other));
    if (clash !== undefined) return c.json(fail("campaign_overlap", `Chevauche « ${clash.name} ».`), 409);
    const next: StoredCampaign = { ...current, status: "scheduled", ...scheduleArtifacts(current), updatedAt: stamped() };
    campaigns[index] = next;
    return c.json(ok(viewOf(next)));
  });

  api.post(`${base}/campaigns/:id/cancel`, (c) => {
    if (!canWriteStores(c as never)) return c.json(fail("forbidden", "Annuler une campagne est réservé aux super-administrateurs."), 403);
    const index = indexOf(c.req.param("id"));
    const current = campaigns[index];
    if (current === undefined) return c.json(fail("campaign_not_found"), 404);
    const shown = viewOf(current).status;
    if (shown === "ended" || shown === "cancelled") return c.json(fail("campaign_wrong_state", `A ${shown} campaign cannot be cancelled`), 409);
    const next: StoredCampaign = { ...current, status: "cancelled", updatedAt: stamped() };
    campaigns[index] = next;
    return c.json(ok(viewOf(next)));
  });
}
