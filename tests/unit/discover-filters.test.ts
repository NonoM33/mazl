import { describe, expect, test } from "bun:test";
import {
  applicableFilters,
  applyPatch,
  candidateMatchesFilters,
  NO_FILTERS,
  patchAsksForAdvancedCriteria,
  patchAsksForReligiousCriteria,
  type DiscoverFilters,
} from "../../src/features/matching/domain/discover-filters";
import { exclusionReason } from "../../src/features/matching/domain/filters";
import { DEFAULT_PARAMS } from "../../src/features/matching/domain/params";
import { context, profile } from "./matching-support";

const filters = (overrides: Partial<DiscoverFilters> = {}): DiscoverFilters => ({ ...NO_FILTERS, ...overrides });

describe("candidateMatchesFilters", () => {
  test("no criterion lets everyone through, including a candidate who answered nothing", () => {
    expect(candidateMatchesFilters(profile({ denomination: null, kashrut: null, shabbat: null, photoCount: 0, verification: "none" }), NO_FILTERS)).toBe(true);
  });

  test("a religious criterion keeps the listed answers, whatever the case or surrounding spaces", () => {
    const wanted = filters({ denominations: ["massorti", "Orthodox"] });
    expect(candidateMatchesFilters(profile({ denomination: "Massorti" }), wanted)).toBe(true);
    expect(candidateMatchesFilters(profile({ denomination: " ORTHODOX " }), wanted)).toBe(true);
    expect(candidateMatchesFilters(profile({ denomination: "Laique" }), wanted)).toBe(false);
  });

  test("a religious criterion excludes the candidate who did not answer", () => {
    expect(candidateMatchesFilters(profile({ denomination: null }), filters({ denominations: ["Massorti"] }))).toBe(false);
    expect(candidateMatchesFilters(profile({ kashrut: null }), filters({ kashrutLevels: ["Strict"] }))).toBe(false);
    expect(candidateMatchesFilters(profile({ shabbat: null }), filters({ shabbatObservances: ["Observant"] }))).toBe(false);
    expect(candidateMatchesFilters(profile({ shabbat: "   " }), filters({ shabbatObservances: ["Observant"] }))).toBe(false);
  });

  test("the three religious criteria all have to hold", () => {
    const wanted = filters({ denominations: ["Massorti"], kashrutLevels: ["Strict"], shabbatObservances: ["Observant"] });
    expect(candidateMatchesFilters(profile({ denomination: "Massorti", kashrut: "Strict", shabbat: "Observant" }), wanted)).toBe(true);
    expect(candidateMatchesFilters(profile({ denomination: "Massorti", kashrut: "Non", shabbat: "Observant" }), wanted)).toBe(false);
  });

  test("onlyVerified keeps selfie and identity checks, drops unverified profiles", () => {
    const wanted = filters({ onlyVerified: true });
    expect(candidateMatchesFilters(profile({ verification: "selfie" }), wanted)).toBe(true);
    expect(candidateMatchesFilters(profile({ verification: "identity" }), wanted)).toBe(true);
    expect(candidateMatchesFilters(profile({ verification: "none" }), wanted)).toBe(false);
  });

  test("onlyWithPhoto needs at least one photo", () => {
    const wanted = filters({ onlyWithPhoto: true });
    expect(candidateMatchesFilters(profile({ photoCount: 1 }), wanted)).toBe(true);
    expect(candidateMatchesFilters(profile({ photoCount: 0 }), wanted)).toBe(false);
  });
});

describe("exclusionReason with filters", () => {
  const viewer = profile({ userId: 1, gender: "male", lookingFor: "female" });
  const woman = (o = {}) => profile({ userId: 2, gender: "female", lookingFor: "male", ...o });

  test("a candidate who fails the member's filters is left out for the 'filters' reason", () => {
    const ctx = { ...context(), filters: filters({ onlyWithPhoto: true }) };
    expect(exclusionReason(viewer, woman({ photoCount: 0 }), ctx, DEFAULT_PARAMS)).toBe("filters");
    expect(exclusionReason(viewer, woman({ photoCount: 2 }), ctx, DEFAULT_PARAMS)).toBeNull();
  });

  test("without filters in the context nothing changes", () => {
    expect(exclusionReason(viewer, woman({ photoCount: 0, verification: "none" }), context(), DEFAULT_PARAMS)).toBeNull();
  });

  test("gender and age keep priority over the filters", () => {
    const ctx = { ...context(), filters: filters({ onlyVerified: true }) };
    expect(exclusionReason(viewer, woman({ gender: "male", verification: "none" }), ctx, DEFAULT_PARAMS)).toBe("gender");
  });
});

describe("applicableFilters", () => {
  const stored = filters({ denominations: ["Massorti"], kashrutLevels: ["Strict"], onlyVerified: true });

  test("a non-subscriber has nothing applied, the stored criteria are untouched", () => {
    expect(applicableFilters(stored, { plus: false, religiousConsent: true })).toEqual(NO_FILTERS);
  });

  test("a subscriber without a valid art. 9 consent keeps only the non-religious criteria", () => {
    expect(applicableFilters(stored, { plus: true, religiousConsent: false })).toEqual(filters({ onlyVerified: true }));
  });

  test("a subscriber with consent has everything applied", () => {
    expect(applicableFilters(stored, { plus: true, religiousConsent: true })).toEqual(stored);
  });
});

describe("applyPatch", () => {
  const current = filters({ denominations: ["Massorti"], onlyWithPhoto: true });

  test("an absent field is kept, null clears it", () => {
    expect(applyPatch(current, { kashrutLevels: ["Strict"] })).toEqual(filters({ denominations: ["Massorti"], kashrutLevels: ["Strict"], onlyWithPhoto: true }));
    expect(applyPatch(current, { denominations: null })).toEqual(filters({ onlyWithPhoto: true }));
  });

  test("answers are trimmed, deduplicated without regard to case, and an empty list clears the criterion", () => {
    expect(applyPatch(NO_FILTERS, { denominations: [" Massorti", "massorti ", "Orthodox", ""] }).denominations).toEqual(["Massorti", "Orthodox"]);
    expect(applyPatch(current, { denominations: [] }).denominations).toBeNull();
    expect(applyPatch(current, { denominations: ["  "] }).denominations).toBeNull();
  });

  test("booleans are replaced", () => {
    expect(applyPatch(current, { onlyWithPhoto: false, onlyVerified: true })).toEqual(filters({ denominations: ["Massorti"], onlyVerified: true }));
  });
});

describe("what a patch asks for", () => {
  test("setting a criterion asks for mazl+, clearing one does not", () => {
    expect(patchAsksForAdvancedCriteria({ onlyVerified: true })).toBe(true);
    expect(patchAsksForAdvancedCriteria({ onlyWithPhoto: true })).toBe(true);
    expect(patchAsksForAdvancedCriteria({ kashrutLevels: ["Strict"] })).toBe(true);
    expect(patchAsksForAdvancedCriteria({ onlyVerified: false, onlyWithPhoto: false })).toBe(false);
    expect(patchAsksForAdvancedCriteria({ denominations: null, kashrutLevels: [], shabbatObservances: null })).toBe(false);
    expect(patchAsksForAdvancedCriteria({})).toBe(false);
  });

  test("only a religious list asks for the art. 9 consent", () => {
    expect(patchAsksForReligiousCriteria({ shabbatObservances: ["Observant"] })).toBe(true);
    expect(patchAsksForReligiousCriteria({ onlyVerified: true })).toBe(false);
    expect(patchAsksForReligiousCriteria({ denominations: null })).toBe(false);
    expect(patchAsksForReligiousCriteria({ denominations: [" "] })).toBe(false);
  });
});
