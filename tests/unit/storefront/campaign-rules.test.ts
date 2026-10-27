import { describe, expect, test } from "bun:test";
import { campaignStatus, type Campaign, type CampaignInput } from "../../../src/features/storefront/domain/campaign";
import { applyEdit, assertNoOverlap, assertValidCampaign, campaignProblems } from "../../../src/features/storefront/domain/campaign-rules";
import { CampaignNotEditableError, CampaignOverlapError, InvalidCampaignError } from "../../../src/features/storefront/domain/errors";
import { generateOfferCode, isValidOfferCode } from "../../../src/features/storefront/domain/offer-code";
import { negotiateLanguage } from "../../../src/features/storefront/domain/languages";
import { THEME_IDS } from "../../../src/features/storefront/domain/themes";

const D = (iso: string): Date => new Date(iso);
const text = { title: "Saint-Valentin", subtitle: "Offrez-vous mazl+", cta: "J'en profite" };

function input(overrides: Partial<CampaignInput> = {}): CampaignInput {
  return {
    themeId: "valentine",
    name: "Saint-Valentin 2027",
    startsAt: D("2027-02-06T23:00:00Z"),
    endsAt: D("2027-02-14T23:00:00Z"),
    texts: { fr: text },
    targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: 30 }],
    changeAppIcon: true,
    ...overrides,
  };
}

function campaign(overrides: Partial<Campaign> = {}): Campaign {
  return {
    ...input(),
    id: 1,
    status: "scheduled",
    apple: { codes: [], error: null },
    stripe: { promotions: [], error: null },
    createdBy: "staff@example.com",
    createdAt: D("2027-01-01T00:00:00Z"),
    updatedAt: D("2027-01-01T00:00:00Z"),
    ...overrides,
  };
}

describe("validation", () => {
  test("a valid campaign has no problem", () => {
    expect(campaignProblems(input())).toEqual([]);
  });

  test("endsAt must be after startsAt", () => {
    expect(campaignProblems(input({ endsAt: D("2027-02-06T23:00:00Z") }))).toContain("endsAt must be after startsAt");
    expect(campaignProblems(input({ endsAt: D("2027-02-01T00:00:00Z") }))).toContain("endsAt must be after startsAt");
  });

  test("45 days is the limit", () => {
    const start = D("2027-02-01T00:00:00Z");
    expect(campaignProblems(input({ startsAt: start, endsAt: new Date(start.getTime() + 45 * 86_400_000) }))).toEqual([]);
    expect(campaignProblems(input({ startsAt: start, endsAt: new Date(start.getTime() + 45 * 86_400_000 + 1) }))).toContain("a campaign lasts 45 days at most");
  });

  test("the discount is an integer from 5 to 90", () => {
    for (const bad of [4, 91, 0, 12.5, -10]) {
      expect(campaignProblems(input({ targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: bad }] })).length).toBe(1);
    }
    for (const good of [5, 30, 90]) {
      expect(campaignProblems(input({ targets: [{ productId: "com.mazl.app.plus.3m", discountPercent: good }] }))).toEqual([]);
    }
  });

  test("targets: at least one, known, no duplicate", () => {
    expect(campaignProblems(input({ targets: [] }))).toContain("a campaign targets at least one product");
    expect(campaignProblems(input({ targets: [{ productId: "com.mazl.app.nope", discountPercent: 20 }] }))).toContain("unknown product com.mazl.app.nope");
    const twice = { productId: "com.mazl.app.plus.3m", discountPercent: 20 };
    expect(campaignProblems(input({ targets: [twice, twice] }))).toContain("product com.mazl.app.plus.3m is targeted twice");
  });

  test("texts: French is complete, lengths are bounded", () => {
    expect(campaignProblems(input({ texts: { fr: { ...text, title: "  " } } }))).toContain("texts.fr.title is empty");
    expect(campaignProblems(input({ texts: { fr: { ...text, cta: "x".repeat(31) } } }))).toContain("texts.fr.cta is longer than 30 characters");
    expect(campaignProblems(input({ texts: { fr: text, en: { ...text, subtitle: "" } } }))).toContain("texts.en.subtitle is empty");
  });

  test("assertValidCampaign throws the typed error with every problem", () => {
    expect(() => assertValidCampaign(input({ name: "", targets: [] }))).toThrow(InvalidCampaignError);
  });
});

describe("overlap", () => {
  const scheduled = campaign({ id: 7, startsAt: D("2027-02-10T00:00:00Z"), endsAt: D("2027-02-20T00:00:00Z") });

  test("two scheduled campaigns never overlap", () => {
    expect(() => assertNoOverlap({ id: null, startsAt: D("2027-02-15T00:00:00Z"), endsAt: D("2027-02-25T00:00:00Z") }, [scheduled])).toThrow(CampaignOverlapError);
    expect(() => assertNoOverlap({ id: null, startsAt: D("2027-02-01T00:00:00Z"), endsAt: D("2027-02-11T00:00:00Z") }, [scheduled])).toThrow(CampaignOverlapError);
  });

  test("back to back is not an overlap, nor is a draft, a cancelled campaign, or itself", () => {
    expect(() => assertNoOverlap({ id: null, startsAt: D("2027-02-20T00:00:00Z"), endsAt: D("2027-02-25T00:00:00Z") }, [scheduled])).not.toThrow();
    expect(() => assertNoOverlap({ id: null, startsAt: D("2027-02-12T00:00:00Z"), endsAt: D("2027-02-14T00:00:00Z") }, [{ ...scheduled, status: "draft" }])).not.toThrow();
    expect(() => assertNoOverlap({ id: null, startsAt: D("2027-02-12T00:00:00Z"), endsAt: D("2027-02-14T00:00:00Z") }, [{ ...scheduled, status: "cancelled" }])).not.toThrow();
    expect(() => assertNoOverlap({ id: 7, startsAt: D("2027-02-12T00:00:00Z"), endsAt: D("2027-02-14T00:00:00Z") }, [scheduled])).not.toThrow();
  });
});

describe("status", () => {
  const base = { startsAt: D("2027-02-07T00:00:00Z"), endsAt: D("2027-02-15T00:00:00Z") };
  test("computed from the stored status and the clock", () => {
    expect(campaignStatus({ ...base, status: "draft" }, D("2027-02-10T00:00:00Z"))).toBe("draft");
    expect(campaignStatus({ ...base, status: "cancelled" }, D("2027-02-10T00:00:00Z"))).toBe("cancelled");
    expect(campaignStatus({ ...base, status: "scheduled" }, D("2027-02-06T23:59:59Z"))).toBe("scheduled");
    expect(campaignStatus({ ...base, status: "scheduled" }, D("2027-02-07T00:00:00Z"))).toBe("live");
    expect(campaignStatus({ ...base, status: "scheduled" }, D("2027-02-14T23:59:59Z"))).toBe("live");
    expect(campaignStatus({ ...base, status: "scheduled" }, D("2027-02-15T00:00:00Z"))).toBe("ended");
  });
});

describe("edits by state", () => {
  const now = D("2027-02-10T00:00:00Z");
  const live = campaign({ startsAt: D("2027-02-07T00:00:00Z"), endsAt: D("2027-02-15T00:00:00Z") });

  test("a live campaign can only end earlier", () => {
    expect(applyEdit(live, { endsAt: D("2027-02-12T00:00:00Z") }, now).endsAt).toEqual(D("2027-02-12T00:00:00Z"));
    expect(() => applyEdit(live, { endsAt: D("2027-02-16T00:00:00Z") }, now)).toThrow(CampaignNotEditableError);
    expect(() => applyEdit(live, { name: "Autre" }, now)).toThrow(CampaignNotEditableError);
    expect(() => applyEdit(live, { endsAt: D("2027-02-12T00:00:00Z"), changeAppIcon: false }, now)).toThrow(CampaignNotEditableError);
    expect(() => applyEdit(live, { endsAt: D("2027-02-09T00:00:00Z") }, now)).toThrow(InvalidCampaignError);
  });

  test("a scheduled campaign keeps its dates, theme and targets but its texts can change", () => {
    const future = campaign({ startsAt: D("2027-02-20T00:00:00Z"), endsAt: D("2027-02-27T00:00:00Z") });
    expect(applyEdit(future, { name: "Renommée", changeAppIcon: false }, now)).toMatchObject({ name: "Renommée", changeAppIcon: false });
    expect(() => applyEdit(future, { endsAt: D("2027-02-26T00:00:00Z") }, now)).toThrow(CampaignNotEditableError);
    expect(() => applyEdit(future, { targets: [] }, now)).toThrow(CampaignNotEditableError);
  });

  test("a draft can change anything, still validated", () => {
    const draft = campaign({ status: "draft" });
    expect(applyEdit(draft, { themeId: "christmas", targets: [{ productId: "com.mazl.app.plus.1m", discountPercent: 10 }] }, now).themeId).toBe("christmas");
    expect(() => applyEdit(draft, { targets: [{ productId: "com.mazl.app.plus.1m", discountPercent: 95 }] }, now)).toThrow(InvalidCampaignError);
  });

  test("an ended or cancelled campaign is frozen", () => {
    expect(() => applyEdit(campaign({ endsAt: D("2027-02-09T00:00:00Z") }), { name: "x" }, now)).toThrow(CampaignNotEditableError);
    expect(() => applyEdit(campaign({ status: "cancelled" }), { name: "x" }, now)).toThrow(CampaignNotEditableError);
  });
});

describe("offer codes", () => {
  test("VALENTIN27 for a Valentine's campaign ending in February 2027", () => {
    expect(generateOfferCode({ themeId: "valentine", endsAt: D("2027-02-14T23:00:00Z"), months: null, taken: new Set() })).toBe("VALENTIN27");
  });

  test("the year is the one of the last day (New Year opens in December)", () => {
    expect(generateOfferCode({ themeId: "new_year", endsAt: D("2027-01-03T23:00:00Z"), months: null, taken: new Set() })).toBe("NOUVELAN27");
  });

  test("one code per subscription when a campaign has several", () => {
    expect(generateOfferCode({ themeId: "valentine", endsAt: D("2027-02-14T23:00:00Z"), months: 3, taken: new Set() })).toBe("VALENTIN27M3");
  });

  test("a taken code is never reused", () => {
    const taken = new Set(["VALENTIN27", "VALENTIN27B"]);
    expect(generateOfferCode({ themeId: "valentine", endsAt: D("2027-02-14T23:00:00Z"), months: null, taken })).toBe("VALENTIN27C");
  });

  test("every theme gives a code Apple accepts (A-Z0-9, 6 to 64)", () => {
    for (const themeId of THEME_IDS) {
      for (const months of [null, 1, 12]) {
        const code = generateOfferCode({ themeId, endsAt: D("2027-03-01T00:00:00Z"), months, taken: new Set() });
        expect(isValidOfferCode(code)).toBe(true);
      }
    }
  });
});

describe("Accept-Language", () => {
  test("French by default, quality order, regions, the old Hebrew code", () => {
    expect(negotiateLanguage(null)).toBe("fr");
    expect(negotiateLanguage("de-DE,de;q=0.9")).toBe("fr");
    expect(negotiateLanguage("en-US,en;q=0.9,fr;q=0.8")).toBe("en");
    expect(negotiateLanguage("fr;q=0.5, ru;q=0.9")).toBe("ru");
    expect(negotiateLanguage("iw")).toBe("he");
    expect(negotiateLanguage("es-MX")).toBe("es");
    expect(negotiateLanguage("en;q=0")).toBe("fr");
  });
});
