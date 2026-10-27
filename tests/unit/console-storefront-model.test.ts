import { describe, expect, test } from "bun:test";
import { defaultTargets, discountedAmount, formFromCampaign, newForm, parseDiscount, validateForm, type CampaignForm } from "../../console/src/storefront/campaign-form";
import { groupProducts, reorder, validateHighlight, applyOrder, emptyHighlight } from "../../console/src/storefront/offers-model";
import { changeLines, explainApplePlan, formatMoney, parseAmountToCents, planDirection, validateStartDate, validateWebPrice } from "../../console/src/storefront/price-change";
import { contrastRatio, paywallLines, readableOn, untilLabel } from "../../console/src/storefront/preview-model";
import { publishSummary } from "../../console/src/storefront/publish-summary";
import { storefrontErrorMessage } from "../../console/src/storefront/errors";
import { defaultTexts } from "../../console/src/storefront/theme-texts";
import { THEMES, isInverseTheme } from "../../console/src/storefront/themes";
import { LANGS, THEME_IDS, type ProductDto } from "../../console/src/storefront/types";
import themesFile from "../../docs/storefront/themes.json";

const product = (productId: string, kind: ProductDto["kind"], sortOrder: number): ProductDto => ({
  productId,
  kind,
  months: kind === "subscription" ? Number(/plus\.(\d+)m$/.exec(productId)?.[1]) : null,
  visible: true,
  sortOrder,
  featured: false,
  highlight: null,
  stripePriceId: null,
  effectiveStripePriceId: null,
  updatedAt: "2026-10-20T09:00:00.000Z",
  updatedBy: null,
  prices: { apple: { status: "ok", items: [] }, web: { status: "ok", items: [] } },
});
const PRODUCTS: readonly ProductDto[] = [
  product("com.mazl.app.plus.12m", "subscription", 0),
  product("com.mazl.app.plus.6m", "subscription", 1),
  product("com.mazl.app.plus.3m", "subscription", 2),
  product("com.mazl.app.plus.1m", "subscription", 3),
  product("com.mazl.app.boost.1", "credits", 4),
  product("com.mazl.app.superlikes.5", "credits", 5),
];

describe("thèmes", () => {
  test("les thèmes de la console sont exactement ceux de themes.json, dans le même ordre", () => {
    expect(THEMES.map((theme) => String(theme.id))).toEqual(themesFile.themes.map((theme) => theme.id));
    expect([...THEME_IDS].map(String).sort()).toEqual(themesFile.themes.map((theme) => theme.id).sort());
  });
  test("seules les fêtes juives commencent la veille au soir ; seul le Black Friday est en inverse", () => {
    expect(THEMES.filter((theme) => theme.hebrew).map((theme) => theme.id).sort()).toEqual(["hanukkah", "passover", "purim", "rosh_hashana", "tu_bav"]);
    expect(THEMES.filter((theme) => isInverseTheme(theme.id)).map((theme) => theme.id)).toEqual(["black_friday"]);
  });
  test("chaque thème a des textes complets dans les cinq langues", () => {
    for (const id of THEME_IDS) {
      const texts = defaultTexts(id);
      for (const lang of LANGS) {
        expect(texts[lang].title.length).toBeGreaterThan(0);
        expect(texts[lang].subtitle.length).toBeGreaterThan(0);
        expect(texts[lang].cta.length).toBeGreaterThan(0);
      }
    }
  });
});

describe("formulaire de campagne", () => {
  const base = (): CampaignForm => newForm("valentine", PRODUCTS, "Saint-Valentin 2027", "2027-02-06T23:00:00Z", "2027-02-14T23:00:00Z");
  test("une campagne prérécrite par thème est valide et cible les abonnements à 30 %", () => {
    const result = validateForm(base());
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.input.startsAt).toBe("2027-02-06T23:00:00.000Z");
    expect(result.input.targets.map((target) => target.productId)).toEqual(["com.mazl.app.plus.12m", "com.mazl.app.plus.6m", "com.mazl.app.plus.3m", "com.mazl.app.plus.1m"]);
    expect(result.input.targets.every((target) => target.discountPercent === 30)).toBe(true);
    expect(result.input.changeAppIcon).toBe(true);
  });
  test("le Black Friday propose 40 %", () => {
    expect(defaultTargets(PRODUCTS, "black_friday")[0]?.discountText).toBe("40");
  });
  test("remise : 5 à 90 %, entier", () => {
    expect(parseDiscount("30")).toBe(30);
    expect(parseDiscount(" 30 % ")).toBe(30);
    for (const bad of ["4", "91", "3.5", "", "abc", "-10", "1000"]) expect(parseDiscount(bad)).toBeNull();
  });
  test("fin avant début, durée au-delà de 45 jours, dates absentes", () => {
    const reversed = validateForm({ ...base(), startsLocal: "2027-02-14T00:00", endsLocal: "2027-02-07T00:00" });
    expect(reversed.ok ? "" : reversed.errors.range).toContain("après le début");
    const long = validateForm({ ...base(), startsLocal: "2027-02-01T00:00", endsLocal: "2027-03-20T00:00" });
    expect(long.ok ? "" : long.errors.range).toContain("45 jours");
    expect(validateForm({ ...base(), startsLocal: "2027-02-01T00:00", endsLocal: "2027-03-17T00:00" }).ok).toBe(true);
    const missing = validateForm({ ...base(), startsLocal: "", endsLocal: "" });
    expect(missing.ok ? "" : missing.errors.startsLocal).not.toBe("");
  });
  test("le français est obligatoire, une autre langue vide est omise de la requête, partielle est refusée", () => {
    const noFr = base();
    const frEmpty = validateForm({ ...noFr, texts: { ...noFr.texts, fr: { title: "", subtitle: "", cta: "" } } });
    expect(frEmpty.ok ? "" : frEmpty.errors.texts?.fr).toContain("obligatoire");
    const blankRu = validateForm({ ...noFr, texts: { ...noFr.texts, ru: { title: "", subtitle: "", cta: "" } } });
    expect(blankRu.ok && Object.keys(blankRu.input.texts).sort()).toEqual(["en", "es", "fr", "he"]);
    const partialEs = validateForm({ ...noFr, texts: { ...noFr.texts, es: { title: "Hola", subtitle: "", cta: "" } } });
    expect(partialEs.ok ? "" : partialEs.errors.texts?.es).toContain("trois textes");
  });
  test("remise invalide signalée sur le bon produit, nom obligatoire", () => {
    const form = base();
    const targets = form.targets.map((target) => (target.productId === "com.mazl.app.plus.3m" ? { ...target, discountText: "95" } : target));
    const result = validateForm({ ...form, name: "  ", targets });
    expect(result.ok).toBe(false);
    if (result.ok) return;
    expect(Object.keys(result.errors.targets ?? {})).toEqual(["com.mazl.app.plus.3m"]);
    expect(result.errors.name).toBeDefined();
  });
  test("réouverture d'une campagne : les remises enregistrées reviennent, les autres produits sont décochés", () => {
    const form = formFromCampaign(
      { id: 1, status: "draft", apple: { codes: [], error: null }, stripe: { promotions: [], error: null }, createdBy: "a@example.com", createdAt: "", updatedAt: "", themeId: "valentine", name: "N", startsAt: "2027-02-06T23:00:00Z", endsAt: "2027-02-14T23:00:00Z", texts: defaultTexts("valentine"), targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: 25 }], changeAppIcon: false },
      PRODUCTS,
    );
    expect(form.targets.filter((target) => target.enabled)).toEqual([{ productId: "com.mazl.app.plus.3m", enabled: true, discountText: "25" }]);
    expect(form.startsLocal).toBe("2027-02-07T00:00");
    expect(form.changeAppIcon).toBe(false);
  });
  test("prix remisé arrondi au centime", () => {
    expect(discountedAmount(44.99, 30)).toBe(31.49);
    expect(discountedAmount(19.99, 50)).toBe(10);
  });
});

describe("changement de prix Apple", () => {
  const plan = (from: string, to: string, preserve: boolean): Parameters<typeof explainApplePlan>[0] => ({ preserveCurrentPrice: preserve, startDate: "2027-03-01", changes: [{ territory: "FRA", from, to, pricePointId: "pp-FRA" }, { territory: "USA", from: "49.99", to: "54.99", pricePointId: "pp-USA" }] });
  test("sens du changement jugé sur la France", () => {
    expect(planDirection(plan("44.99", "49.99", true))).toBe("up");
    expect(planDirection(plan("44.99", "39.99", true))).toBe("down");
    expect(planDirection(plan("44.99", "44.99", true))).toBe("same");
  });
  test("pays par pays, avec le nom du pays et la devise", () => {
    const lines = changeLines(plan("44.99", "49.99", true).changes, (territory) => (territory === "FRA" ? "EUR" : "USD"));
    expect(lines[0]).toMatchObject({ country: "France", direction: "up" });
    expect(lines[0]?.before).toContain("44,99");
    expect(lines[1]?.after).toContain("54,99");
  });
  test("baisse : s'applique à tous au renouvellement ; propagation de quelques heures", () => {
    const text = explainApplePlan(plan("44.99", "39.99", true), true).join(" ");
    expect(text).toContain("baisse");
    expect(text).toContain("tous les abonnés");
    expect(text).toContain("renouvellement");
    expect(text).toContain("quelques heures");
  });
  test("hausse avec conservation : les abonnés actuels gardent leur prix", () => {
    const text = explainApplePlan(plan("44.99", "49.99", true), true).join(" ");
    expect(text).toContain("gardent leur prix");
    expect(text).not.toContain("l'accord");
  });
  test("hausse sans conservation : l'accord de chaque abonné est demandé", () => {
    const text = explainApplePlan(plan("44.99", "49.99", false), true).join(" ");
    expect(text).toContain("l'accord de chaque abonné");
  });
  test("sans changement, on le dit et on ne parle pas de propagation", () => {
    const lines = explainApplePlan(plan("44.99", "44.99", true), true);
    expect(lines.join(" ")).toContain("rien ne change");
    expect(lines.join(" ")).not.toContain("propagation");
  });
  test("date d'effet : pas dans le passé (jour de Paris)", () => {
    const now = new Date("2027-02-13T23:30:00Z"); // 14 février à Paris
    expect(validateStartDate("2027-02-13", now)).not.toBeNull();
    expect(validateStartDate("2027-02-14", now)).toBeNull();
    expect(validateStartDate("", now)).not.toBeNull();
    expect(validateStartDate("2027-02-30", now)).not.toBeNull();
  });
  test("montants en euros, dollars, shekels", () => {
    expect(formatMoney("44.99", "EUR")).toMatch(/^44,99\s€$/);
    expect(formatMoney("49.99", "USD")).toContain("49,99");
    expect(formatMoney("abc", "EUR")).toBe("—");
  });
});

describe("prix web", () => {
  test("montants saisis", () => {
    expect(parseAmountToCents("44,99")).toBe(4499);
    expect(parseAmountToCents("44.99")).toBe(4499);
    expect(parseAmountToCents(" 5 ")).toBe(500);
    expect(parseAmountToCents("19,9")).toBe(1990);
    for (const bad of ["0", "0,00", "-5", "4,999", "abc", "", "100000,01"]) expect(parseAmountToCents(bad)).toBeNull();
  });
  test("devise connue obligatoire", () => {
    expect(validateWebPrice("44,99", "EUR")).toEqual({ ok: true, amountCents: 4499 });
    expect(validateWebPrice("44,99", "XYZ").ok).toBe(false);
  });
});

describe("tableau des offres", () => {
  test("deux groupes triés par ordre", () => {
    const shuffled = [PRODUCTS[3], PRODUCTS[5], PRODUCTS[0], PRODUCTS[4], PRODUCTS[2], PRODUCTS[1]] as ProductDto[];
    const [subscriptions, consumables] = groupProducts(shuffled);
    expect(subscriptions?.products.map((p) => p.sortOrder)).toEqual([0, 1, 2, 3]);
    expect(consumables?.products.map((p) => p.productId)).toEqual(["com.mazl.app.boost.1", "com.mazl.app.superlikes.5"]);
  });
  test("monter le 3 mois d'un cran n'envoie que les deux produits qui changent de place", () => {
    const group = PRODUCTS.slice(0, 4);
    expect(reorder(group, "com.mazl.app.plus.3m", 1)).toEqual([
      { productId: "com.mazl.app.plus.3m", sortOrder: 1 },
      { productId: "com.mazl.app.plus.6m", sortOrder: 2 },
    ]);
  });
  test("le groupe garde ses emplacements d'ordre (l'autre groupe n'est pas touché)", () => {
    const consumables = PRODUCTS.slice(4);
    expect(reorder(consumables, "com.mazl.app.superlikes.5", 0)).toEqual([
      { productId: "com.mazl.app.superlikes.5", sortOrder: 4 },
      { productId: "com.mazl.app.boost.1", sortOrder: 5 },
    ]);
  });
  test("déplacements impossibles ou sans effet", () => {
    const group = PRODUCTS.slice(0, 4);
    expect(reorder(group, "com.mazl.app.plus.12m", 0)).toEqual([]);
    expect(reorder(group, "com.mazl.app.plus.12m", -1)).toEqual([]);
    expect(reorder(group, "com.mazl.app.plus.12m", 4)).toEqual([]);
    expect(reorder(group, "inconnu", 1)).toEqual([]);
  });
  test("application locale des changements", () => {
    const patches = reorder(PRODUCTS.slice(0, 4), "com.mazl.app.plus.1m", 0);
    const after = applyOrder(PRODUCTS, patches);
    expect(groupProducts(after)[0]?.products.map((p) => p.productId)[0]).toBe("com.mazl.app.plus.1m");
  });
  test("accroche : vide partout = aucune ; français obligatoire ; 40 caractères", () => {
    expect(validateHighlight(emptyHighlight())).toEqual({ ok: true, value: null });
    expect(validateHighlight({ ...emptyHighlight(), en: "Most popular" }).ok).toBe(false);
    expect(validateHighlight({ ...emptyHighlight(), fr: "x".repeat(41) }).ok).toBe(false);
    const ok = validateHighlight({ ...emptyHighlight(), fr: "Le plus choisi", en: "Most popular" });
    expect(ok.ok && ok.value).toEqual({ fr: "Le plus choisi", en: "Most popular", he: "Le plus choisi", es: "Le plus choisi", ru: "Le plus choisi" });
  });
});

describe("erreurs du serveur", () => {
  test("chevauchement et boutique non configurée sont dits en clair", () => {
    expect(storefrontErrorMessage({ code: "campaign_overlap", message: "overlap", status: 409 })).toContain("chevaucher");
    expect(storefrontErrorMessage({ code: "store_not_configured", message: "", status: 503 })).toContain("clés manquantes");
  });
  test("une erreur Apple garde le détail renvoyé", () => {
    const text = storefrontErrorMessage({ code: "store_error", message: "apple: ENTITY_ERROR: offer code already exists", status: 502 });
    expect(text).toContain("Apple ou Stripe a refusé");
    expect(text).toContain("offer code already exists");
  });
  test("un code inconnu renvoie le message du serveur", () => {
    expect(storefrontErrorMessage({ code: "boom", message: "Quelque chose a cassé.", status: 500 })).toBe("Quelque chose a cassé.");
  });
});

describe("aperçu de l'écran mazl+", () => {
  const priced = (productId: string, months: number, amount: string, sortOrder: number, extra: Partial<ProductDto> = {}): ProductDto => ({
    ...product(productId, "subscription", sortOrder),
    months,
    prices: { apple: { status: "ok" as const, items: [{ territory: "FRA", currency: "EUR", customerPrice: amount }] }, web: { status: "ok" as const, items: [] } },
    ...extra,
  });
  const offers = [priced("com.mazl.app.plus.3m", 3, "44.99", 1, { featured: true, highlight: { fr: "Le plus choisi", en: "Most popular", he: "הנבחר ביותר", es: "El más elegido", ru: "Самый популярный" } }), priced("com.mazl.app.plus.12m", 12, "99.99", 0), priced("com.mazl.app.plus.1m", 1, "19.99", 2, { visible: false })];

  test("seules les offres visibles, dans l'ordre du serveur ; le prix reste celui d'Apple, le badge nomme l'offre", () => {
    const lines = paywallLines(offers, [{ productId: "com.mazl.app.plus.3m", discountPercent: 30 }], "fr");
    expect(lines.map((line) => line.productId)).toEqual(["com.mazl.app.plus.12m", "com.mazl.app.plus.3m"]);
    expect(lines[0]).toMatchObject({ badge: null });
    // Like the app: the full Apple price, and a badge that names the offer (the code brings the reduction).
    expect(lines[1]?.badge).toBe("Offre -30 %");
    expect(lines[1]?.price).toContain("44,99");
    expect(lines[1]?.price).not.toContain("31,49");
    expect(lines[1]?.highlight).toBe("Le plus choisi");
  });
  test("accroche et nom dans la langue de l'aperçu", () => {
    const lines = paywallLines(offers, [], "en");
    expect(lines[1]?.highlight).toBe("Most popular");
    expect(lines[1]?.name).toBe("mazl+ 3 months");
    expect(paywallLines(offers, [], "he")[1]?.name).toBe("mazl+ 3 חודשים");
  });
  test("« jusqu'au 14 février » : la fin à minuit pile du 15 désigne le 14", () => {
    expect(untilLabel("2027-02-14T23:00:00Z", "fr")).toBe("jusqu'au 14 février");
    expect(untilLabel("2027-02-14T23:00:00Z", "es")).toBe("hasta el 14 de febrero");
    expect(untilLabel("2027-02-14T23:00:00Z", "en")).toContain("14");
  });
  test("texte lisible sur chaque accent de thème (contraste d'au moins 3 : seuil des grands textes)", () => {
    for (const theme of THEMES) {
      expect(contrastRatio(theme.accent, readableOn(theme.accent))).toBeGreaterThanOrEqual(3);
    }
    expect(readableOn("#E8A400")).toBe("#0B0B0F");
    expect(readableOn("#2747F5")).toBe("#FFFFFF");
  });
});

describe("ce que « Programmer » crée", () => {
  const webPriced: ProductDto["prices"] = { apple: { status: "ok", items: [] }, web: { status: "ok", items: [{ priceId: "price_example", amountCents: 4499, currency: "EUR" }] } };
  const catalog: readonly ProductDto[] = [
    { ...product("com.mazl.app.plus.3m", "subscription", 0), prices: webPriced },
    { ...product("com.mazl.app.plus.1m", "subscription", 1), prices: webPriced },
    product("com.mazl.app.boost.1", "credits", 2),
  ];
  const campaign = { themeId: "valentine" as const, startsAt: "2027-02-06T23:00:00Z", endsAt: "2027-02-14T23:00:00Z", changeAppIcon: true };
  test("un code d'offre Apple par abonnement, un coupon Stripe par remise distincte, jamais un changement du prix de base", () => {
    const summary = publishSummary({ ...campaign, targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: 30 }, { productId: "com.mazl.app.plus.1m", discountPercent: 30 }] }, catalog);
    expect(summary.apple).toHaveLength(2);
    expect(summary.apple[0]).toContain("code d'offre à −30 %");
    expect(summary.apple[0]).toContain("jusqu'au 14 février");
    expect(summary.apple[0]).toContain("prix de base ne bouge pas");
    expect(summary.stripe).toHaveLength(1);
    expect(summary.stripe[0]).toContain("mazl+ 3 mois, mazl+ 1 mois");
  });
  test("deux remises différentes = deux coupons", () => {
    const summary = publishSummary({ ...campaign, targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: 30 }, { productId: "com.mazl.app.plus.1m", discountPercent: 20 }] }, catalog);
    expect(summary.stripe).toHaveLength(2);
  });
  test("un consommable passe par le calendrier de prix, sans Stripe s'il n'est pas vendu sur le web", () => {
    const summary = publishSummary({ ...campaign, targets: [{ productId: "com.mazl.app.boost.1", discountPercent: 25 }] }, catalog);
    expect(summary.apple[0]).toContain("calendrier de prix d'Apple");
    expect(summary.stripe).toEqual(["Rien ne sera créé chez Stripe."]);
  });
  test("sans remise : rien chez Apple ni Stripe ; l'icône est annoncée avec l'alerte iOS, ou son absence", () => {
    const none = publishSummary({ ...campaign, targets: [], changeAppIcon: false }, catalog);
    expect(none.apple).toEqual(["Aucune remise ciblée : rien ne sera créé chez Apple."]);
    expect(none.app[1]).toBe("L'icône de l'app ne change pas.");
    const icon = publishSummary({ ...campaign, targets: [] }, catalog);
    expect(icon.app[1]).toContain("AppIcon-valentine");
    expect(icon.app[1]).toContain("alerte");
    expect(icon.app[0]).toContain("7 févr. 2027");
  });
});
