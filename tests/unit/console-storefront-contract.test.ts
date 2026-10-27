// Anti-dérive : la console et sa maquette parlent EXACTEMENT le format du serveur de la vitrine.
// Source de vérité : OPERATIONS (src/features/storefront/presentation/operations.ts), d'où sort aussi l'OpenAPI.
// Ici, on ne compare pas la maquette à elle-même : chaque réponse qu'elle rend est validée contre le schéma de réponse
// du serveur, et chaque corps de requête que le client de la console construit l'est contre le schéma d'entrée.
import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import type { z } from "zod";
import { registerStorefrontMock } from "../../console/dev/mock-storefront";
import { createApiClient, type ApiResult } from "../../console/src/shared/api/client";
import type { MeDto } from "../../console/src/shared/api/contracts";
import { SECTIONS } from "../../console/src/app/permissions";
import { canWriteStorefront } from "../../console/src/storefront/access";
import { storefrontApi } from "../../console/src/storefront/api";
import { CTA_MAX, DURATION_MAX_DAYS, DISCOUNT_MAX, DISCOUNT_MIN, NAME_MAX, SUBTITLE_MAX, TITLE_MAX, newForm, validateForm } from "../../console/src/storefront/campaign-form";
import { HIGHLIGHT_MAX, validateHighlight } from "../../console/src/storefront/offers-model";
import { applePriceRequest, campaignUpdateRequest, endEarlierRequest, sortOrderRequest, webPriceRequest } from "../../console/src/storefront/request-bodies";
import { GLYPHS, LANGS, THEME_IDS, type CampaignDto, type ProductDto } from "../../console/src/storefront/types";
import { MAX_CAMPAIGN_DAYS, MAX_NAME_LENGTH, MAX_DISCOUNT_PERCENT, MIN_DISCOUNT_PERCENT } from "../../src/features/storefront/domain/campaign-rules";
import { LANGUAGES } from "../../src/features/storefront/domain/languages";
import { THEME_IDS as SERVER_THEME_IDS } from "../../src/features/storefront/domain/themes";
import { OPERATIONS, honoPath, type OperationSpec } from "../../src/features/storefront/presentation/operations";
import { campaignBody, campaignPatchBody, errorEnvelope } from "../../src/features/storefront/presentation/schemas";
import { ROLE_PERMISSIONS, type StaffRole } from "../../src/features/staff/domain/roles";

const BASE = "/api/backoffice";

function meFor(role: StaffRole): MeDto {
  return { email: `${role}@example.com`, role, roleLabel: role, permissions: ROLE_PERMISSIONS[role], mfa: true, mfaEnrolled: true, mfaRequired: true };
}

interface Exchange {
  readonly operation: OperationSpec;
  readonly status: number;
  readonly requestBody: unknown;
  readonly payload: unknown;
}

const templateToRegExp = (template: string): RegExp => new RegExp(`^${honoPath(template).replace(/:[A-Za-z]+/g, "[^/]+")}$`);

function operationOf(method: string, pathname: string): OperationSpec {
  const found = OPERATIONS.find((operation) => operation.method === method.toLowerCase() && templateToRegExp(operation.path).test(pathname));
  if (found === undefined) throw new Error(`Le client console appelle une route que le serveur n'a pas : ${method} ${pathname}`);
  return found;
}

// Un client de console branché sur la maquette ; chaque échange est gardé pour être validé.
function consoleFor(role: StaffRole): { readonly store: ReturnType<typeof storefrontApi>; readonly exchanges: Exchange[] } {
  const root = new Hono();
  const api = new Hono();
  registerStorefrontMock(api, () => meFor(role));
  root.route(BASE, api);
  const exchanges: Exchange[] = [];
  const client = createApiClient({
    getToken: () => "jeton-de-test",
    onUnauthorized: () => undefined,
    onMfaRequired: () => undefined,
    fetch: async (input, init) => {
      const url = new URL(input, "http://localhost");
      const response = await root.request(`${url.pathname}${url.search}`, init);
      const copy = response.clone();
      const operation = operationOf(init?.method ?? "GET", url.pathname);
      exchanges.push({ operation, status: response.status, requestBody: typeof init?.body === "string" ? (JSON.parse(init.body) as unknown) : undefined, payload: await copy.json() });
      return response;
    },
  });
  return { store: storefrontApi(client), exchanges };
}

// Un objet ne doit porter AUCUNE clé que le schéma ne connaît pas (les schémas de réponse laissent passer les clés en trop).
function expectExactly(schema: z.ZodType, value: unknown, where: string): void {
  const parsed = schema.safeParse(value);
  if (!parsed.success) throw new Error(`${where} : ${parsed.error.issues.map((issue) => `${issue.path.join(".")} ${issue.message}`).join(" ; ")}`);
  expect({ where, data: parsed.data }).toEqual({ where, data: value });
}

function checkExchange(exchange: Exchange): void {
  const { operation, status, requestBody, payload } = exchange;
  const where = `${operation.operationId} (${String(status)})`;
  const refused = status === 400 && (payload as { error?: string }).error === "invalid_body";
  // Un corps volontairement invalide (test des erreurs) n'a pas à passer le schéma d'entrée.
  if (requestBody !== undefined && !refused) {
    if (operation.body === undefined) throw new Error(`${where} : le client envoie un corps à une route qui n'en attend pas`);
    const parsed = operation.body.schema.safeParse(requestBody);
    if (!parsed.success) throw new Error(`${where} : corps de requête hors schéma : ${parsed.error.issues.map((issue) => `${issue.path.join(".")} ${issue.message}`).join(" ; ")}`);
  }
  if (status === operation.success.status) {
    expectExactly(operation.success.schema, (payload as { data: unknown }).data, where);
    expect((payload as { success: unknown }).success).toBe(true);
    return;
  }
  expectExactly(errorEnvelope, payload, `${where} (enveloppe d'erreur)`);
  const code = (payload as { error: string }).error;
  const documented = operation.errors.some((error) => error.status === status && error.code === code);
  if (!documented) throw new Error(`${where} : la maquette rend ${String(status)} ${code}, que l'OpenAPI de cette route ne documente pas`);
}

const ok = <T>(result: ApiResult<T>): T => {
  if (!result.ok) throw new Error(`échec inattendu ${String(result.status)} ${result.code} : ${result.message}`);
  return result.data;
};
const failed = <T>(result: ApiResult<T>): { status: number; code: string } => {
  if (result.ok) throw new Error("un échec était attendu");
  return { status: result.status, code: result.code };
};

describe("la maquette de la console rend les formes du serveur", () => {
  test("parcours complet en super-administrateur : chaque réponse et chaque corps passent les schémas du serveur", async () => {
    const { store, exchanges } = consoleFor("super_admin");
    const year = new Date().getUTCFullYear();

    const catalog = ok(await store.products());
    const subscription = catalog.products.find((p) => p.kind === "subscription") as ProductDto;
    const credits = catalog.products.find((p) => p.kind === "credits") as ProductDto;

    ok(await store.patchProduct(subscription.productId, { visible: true, featured: true }));
    const highlight = validateHighlight({ fr: "Le plus choisi", en: "Most popular", he: "", es: "", ru: "" });
    if (!highlight.ok) throw new Error("accroche valide attendue");
    ok(await store.patchProduct(subscription.productId, { highlight: highlight.value }));
    ok(await store.patchProduct(credits.productId, sortOrderRequest(4)));
    ok(await store.patchProduct(credits.productId, { highlight: null }));

    const points = ok(await store.applePricePoints(subscription.productId, "FRA"));
    const target = points.pricePoints.find((point) => point.customerPrice === "49.99");
    if (target === undefined) throw new Error("palier introuvable");
    const day = new Date(Date.now() + 2 * 86_400_000).toISOString().slice(0, 10);
    const preview = ok(await store.applePrice(subscription.productId, applePriceRequest({ pricePointId: target.id, startDate: day, preserveCurrentPrice: true, dryRun: true })));
    expect(preview.dryRun).toBe(true);
    const applied = ok(await store.applePrice(subscription.productId, applePriceRequest({ pricePointId: target.id, startDate: day, preserveCurrentPrice: false, dryRun: false })));
    expect(applied.dryRun).toBe(false);
    ok(await store.webPrice(subscription.productId, webPriceRequest(5499, "EUR")));
    ok(await store.webPrice(credits.productId, webPriceRequest(899, "USD")));

    const presets = ok(await store.presets(year + 2));
    expect(presets.presets).toHaveLength(THEME_IDS.length);
    const list = ok(await store.campaigns(year));
    expect(list.campaigns.length).toBeGreaterThan(0);

    // Création depuis le formulaire de la console, brouillon, enregistrement, programmation, annulation.
    const preset = presets.presets[0];
    if (preset === undefined) throw new Error("aucune proposition");
    const form = newForm(preset.themeId, catalog.products, "Campagne d'essai", preset.startsAt, preset.endsAt);
    const checked = validateForm(form);
    if (!checked.ok) throw new Error(`formulaire invalide : ${JSON.stringify(checked.errors)}`);
    const created = ok(await store.createCampaign(checked.input));
    expect(created.status).toBe("draft");
    const saved = ok(await store.updateCampaign(created.id, campaignUpdateRequest("full", checked.input)));
    const published = ok(await store.publish(saved.id));
    expect(published.status).not.toBe("draft");
    expect(published.apple.codes.length).toBeGreaterThan(0);
    ok(await store.updateCampaign(published.id, campaignUpdateRequest("partial", checked.input)));
    ok(await store.cancel(published.id));

    // Campagne en cours : seule la fin s'avance.
    const live = ok(await store.campaigns(new Date().getUTCFullYear())).campaigns.find((c: CampaignDto) => c.status === "live");
    if (live === undefined) throw new Error("la maquette doit porter une campagne en cours");
    ok(await store.updateCampaign(live.id, endEarlierRequest(new Date(Date.now() + 86_400_000).toISOString())));

    expect(new Set(exchanges.map((e) => e.operation.operationId))).toEqual(new Set(OPERATIONS.filter((o) => o.permission !== null && o.operationId !== "storefrontOpenApi").map((o) => o.operationId)));
    for (const exchange of exchanges) checkExchange(exchange);
  });

  test("les erreurs de la maquette sont des enveloppes et des codes que l'OpenAPI du serveur documente", async () => {
    const { store, exchanges } = consoleFor("super_admin");
    const year = new Date().getUTCFullYear();
    const catalog = ok(await store.products());
    const drafts = ok(await store.campaigns(year)).campaigns;
    const scheduled = drafts.find((c) => c.status === "scheduled");
    const ended = ok(await store.campaigns(year)).campaigns.find((c) => c.status === "cancelled");
    if (scheduled === undefined || ended === undefined) throw new Error("campagnes de la maquette attendues");

    expect(failed(await store.patchProduct("com.mazl.app.inconnu", { visible: false })).code).toBe("product_not_found");
    expect(failed(await store.applePricePoints("com.mazl.app.inconnu", "FRA")).code).toBe("product_not_found");
    const subscription = catalog.products[0] as ProductDto;
    expect(failed(await store.applePrice(subscription.productId, applePriceRequest({ pricePointId: "pp-FRA-4999", startDate: "2020-01-01", preserveCurrentPrice: true, dryRun: true }))).code).toBe("invalid_price_change");
    expect(failed(await store.webPrice(subscription.productId, { amountCents: 1, currency: "EUR" })).code).toBe("invalid_body");
    expect(failed(await store.updateCampaign(9999, { name: "x" })).code).toBe("campaign_not_found");
    expect(failed(await store.publish(9999)).code).toBe("campaign_not_found");
    expect(failed(await store.updateCampaign(scheduled.id, { startsAt: scheduled.startsAt })).code).toBe("campaign_not_editable");
    expect(failed(await store.publish(scheduled.id)).code).toBe("campaign_wrong_state");
    expect(failed(await store.cancel(ended.id)).code).toBe("campaign_wrong_state");

    const preset = ok(await store.presets(year + 3)).presets[0];
    if (preset === undefined) throw new Error("aucune proposition");
    for (const [name, code, status] of [["erreur Apple", "store_error", 502], ["sans clés", "store_not_configured", 503]] as const) {
      const checked = validateForm(newForm(preset.themeId, catalog.products, `Essai ${name}`, preset.startsAt, preset.endsAt));
      if (!checked.ok) throw new Error("formulaire invalide");
      const draft = ok(await store.createCampaign(checked.input));
      expect(failed(await store.publish(draft.id))).toEqual({ status, code });
    }
    const first = validateForm(newForm(scheduled.themeId, catalog.products, "Recouvre", scheduled.startsAt, scheduled.endsAt));
    if (!first.ok) throw new Error("formulaire invalide");
    const clash = ok(await store.createCampaign(first.input));
    expect(failed(await store.publish(clash.id)).code).toBe("campaign_overlap");

    for (const exchange of exchanges) checkExchange(exchange);
  });

  test("les rôles : la maquette ouvre et ferme les mêmes routes que le serveur", async () => {
    for (const role of ["super_admin", "admin", "analyst"] as const) {
      const { store, exchanges } = consoleFor(role);
      const permissions = ROLE_PERMISSIONS[role];
      await store.products();
      await store.campaigns(2027);
      await store.presets(2027);
      await store.applePrice("com.mazl.app.plus.1m", applePriceRequest({ pricePointId: "pp-FRA-1999", startDate: "2099-01-01", preserveCurrentPrice: true, dryRun: true }));
      await store.webPrice("com.mazl.app.plus.1m", webPriceRequest(1999, "EUR"));
      await store.publish(1);
      await store.cancel(1);
      for (const exchange of exchanges) {
        const required = exchange.operation.permission;
        if (required === null) throw new Error("route publique inattendue");
        expect({ op: exchange.operation.operationId, role, allowed: exchange.status !== 403 }).toEqual({ op: exchange.operation.operationId, role, allowed: permissions.includes(required) });
      }
    }
  });
});

describe("la console lit les droits comme le serveur les donne", () => {
  const permissionOf = (operationId: string): string | null => OPERATIONS.find((operation) => operation.operationId === operationId)?.permission ?? null;

  test("les écrans Offres et Campagnes demandent la permission des routes de lecture", () => {
    const wanted = permissionOf("storefrontListProducts");
    expect(wanted).toBe("storefront.manage");
    expect(permissionOf("storefrontListCampaigns")).toBe(wanted);
    expect(SECTIONS.filter((section) => section.id === "offres" || section.id === "campagnes").map((section) => section.permission)).toEqual([wanted, wanted]);
  });
  test("écrire chez Apple et Stripe se décide sur la permission que le serveur exige, pas sur le nom du rôle", () => {
    const writes = ["storefrontApplePrice", "storefrontWebPrice", "storefrontPublishCampaign", "storefrontCancelCampaign"].map(permissionOf);
    expect(new Set(writes)).toEqual(new Set(["storefront.stores"]));
    expect(canWriteStorefront(meFor("super_admin"))).toBe(true);
    expect(canWriteStorefront(meFor("admin"))).toBe(false);
    expect(canWriteStorefront({ permissions: ["storefront.stores"] })).toBe(true);
  });
});

describe("les constantes de la console sont celles du serveur", () => {
  test("thèmes, langues, bornes", () => {
    expect([...THEME_IDS]).toEqual([...SERVER_THEME_IDS]);
    expect([...LANGS]).toEqual([...LANGUAGES]);
    expect(NAME_MAX).toBe(MAX_NAME_LENGTH);
    expect(DISCOUNT_MIN).toBe(MIN_DISCOUNT_PERCENT);
    expect(DISCOUNT_MAX).toBe(MAX_DISCOUNT_PERCENT);
    expect(DURATION_MAX_DAYS).toBe(MAX_CAMPAIGN_DAYS);
    expect(GLYPHS.length).toBeGreaterThan(0);
  });
  test("longueurs de texte : la console refuse avant le serveur, jamais après", () => {
    const text = (length: number): string => "a".repeat(length);
    const bodyWith = (title: number, subtitle: number, cta: number): unknown => ({
      themeId: "valentine",
      name: "Essai",
      startsAt: "2027-02-06T23:00:00Z",
      endsAt: "2027-02-14T23:00:00Z",
      texts: { fr: { title: text(title), subtitle: text(subtitle), cta: text(cta) } },
      targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: 30 }],
    });
    expect(campaignBody.safeParse(bodyWith(TITLE_MAX, SUBTITLE_MAX, CTA_MAX)).success).toBe(true);
    expect(campaignBody.safeParse(bodyWith(TITLE_MAX + 1, SUBTITLE_MAX, CTA_MAX)).success).toBe(false);
    expect(campaignBody.safeParse(bodyWith(TITLE_MAX, SUBTITLE_MAX + 1, CTA_MAX)).success).toBe(false);
    expect(campaignBody.safeParse(bodyWith(TITLE_MAX, SUBTITLE_MAX, CTA_MAX + 1)).success).toBe(false);
    expect(campaignPatchBody.safeParse({ name: "x" }).success).toBe(true);
  });
  test("accroche : la limite de la console tient dans celle du serveur", () => {
    const op = OPERATIONS.find((operation) => operation.operationId === "storefrontUpdateProduct");
    const body = { highlight: { fr: "a".repeat(HIGHLIGHT_MAX) } };
    expect(op?.body?.schema.safeParse(body).success).toBe(true);
  });
});
