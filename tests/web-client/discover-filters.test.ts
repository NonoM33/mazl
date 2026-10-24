import { describe, expect, test } from "bun:test";
import { applyFilters, filterOptions, hasActiveFilters, NO_FILTERS } from "../../web/src/features/discover/advanced-filters";
import { isPlus } from "../../web/src/features/discover/plus";
import { card } from "./discover-fixtures";

const David = card(1, { denomination: "Massorti", kashrut_level: "A la maison", shabbat_observance: "Observant", relationship_intention: "serious", is_verified: true });
const Nathan = card(2, { denomination: "Laique", kashrut_level: "Non", shabbat_observance: "Non observant" });
const Yoni = card(3, { denomination: "massorti", kashrut_level: "kasher_a_la_maison", shabbat_observance: "partiellement" });
const all = [David, Nathan, Yoni];
const ids = (list: readonly { user_id: number }[]) => list.map((item) => item.user_id);

describe("advanced filters", () => {
  test("no filter keeps every profile", () => {
    expect(hasActiveFilters(NO_FILTERS)).toBe(false);
    expect(applyFilters(all, NO_FILTERS)).toBe(all);
  });

  test("a denomination matches whatever way the answer was stored", () => {
    expect(ids(applyFilters(all, { ...NO_FILTERS, denomination: "Massorti" }))).toEqual([1, 3]);
  });

  test("kashrut matches the stored variants of « à la maison »", () => {
    expect(ids(applyFilters(all, { ...NO_FILTERS, kashrut: "Cacher à la maison" }))).toEqual([1, 3]);
  });

  test("criteria add up and an unanswered profile never matches a chosen answer", () => {
    expect(ids(applyFilters(all, { ...NO_FILTERS, denomination: "Massorti", shabbat: "Shabbat observé" }))).toEqual([1]);
    expect(ids(applyFilters(all, { ...NO_FILTERS, intention: "Relation sérieuse" }))).toEqual([1]);
  });

  test("verified only keeps verified profiles", () => {
    expect(ids(applyFilters(all, { ...NO_FILTERS, verifiedOnly: true }))).toEqual([1]);
  });

  test("the options are the labels members see as chips, without the hidden answers", () => {
    expect(filterOptions("kashrut")).toEqual(["Cacher à la maison", "Cacher strict", "Glatt cacher"]);
    expect(filterOptions("denomination")).not.toContain("Autre");
    expect(filterOptions("intention")).toContain("Mariage");
  });
});

describe("mazl+", () => {
  const now = Date.parse("2026-10-24T12:00:00Z");
  const row = (status: string | null, expires: string | null) => ({ plan_type: "plus", status, store: "apple", expires_at: expires });
  test("active and not expired", () => expect(isPlus(row("active", "2026-11-01T00:00:00Z"), now)).toBe(true));
  test("expired", () => expect(isPlus(row("active", "2026-10-01T00:00:00Z"), now)).toBe(false));
  test("not active", () => expect(isPlus(row("cancelled", "2026-11-01T00:00:00Z"), now)).toBe(false));
  test("no subscription", () => { expect(isPlus(null, now)).toBe(false); expect(isPlus(row("active", null), now)).toBe(false); });
});
