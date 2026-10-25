import { describe, expect, test } from "bun:test";
import { DiscoverFiltersService } from "../../src/features/matching/application/discover-filters-service";
import type { DiscoverFiltersStore, FilterEntitlements } from "../../src/features/matching/application/ports";
import { NO_FILTERS, type DiscoverFilters } from "../../src/features/matching/domain/discover-filters";

class MemoryStore implements DiscoverFiltersStore {
  readonly rows = new Map<number, DiscoverFilters>();
  reads = 0;
  async get(userId: number): Promise<DiscoverFilters> {
    this.reads += 1;
    return this.rows.get(userId) ?? NO_FILTERS;
  }
  async save(userId: number, filters: DiscoverFilters): Promise<void> {
    this.rows.set(userId, filters);
  }
}

function setup(entitlements: { plus: boolean; consent: boolean }) {
  const store = new MemoryStore();
  const calls = { plus: 0, consent: 0 };
  const guards: FilterEntitlements = {
    isPlus: async () => ((calls.plus += 1), entitlements.plus),
    allowsReligiousData: async () => ((calls.consent += 1), entitlements.consent),
  };
  return { store, calls, entitlements, service: new DiscoverFiltersService(store, guards) };
}

describe("DiscoverFiltersService.update", () => {
  test("a non-subscriber asking for a criterion gets plus_required and nothing is stored", async () => {
    const { service, store } = setup({ plus: false, consent: true });
    expect(await service.update(1, { onlyVerified: true })).toEqual({ ok: false, error: "plus_required" });
    expect(store.rows.size).toBe(0);
  });

  test("a non-subscriber may clear what an expired subscription left behind", async () => {
    const { service, store, entitlements } = setup({ plus: true, consent: true });
    await service.update(1, { onlyVerified: true, denominations: ["Massorti"] });
    entitlements.plus = false;
    const cleared = await service.update(1, { denominations: null, onlyVerified: false });
    expect(cleared).toEqual({ ok: true, filters: NO_FILTERS });
    expect(store.rows.get(1)).toEqual(NO_FILTERS);
  });

  test("a religious criterion without a valid consent gets religious_consent_required", async () => {
    const { service, store } = setup({ plus: true, consent: false });
    expect(await service.update(1, { kashrutLevels: ["Strict"] })).toEqual({ ok: false, error: "religious_consent_required" });
    expect(store.rows.size).toBe(0);
  });

  test("plus_required is checked before the consent", async () => {
    const { service } = setup({ plus: false, consent: false });
    expect(await service.update(1, { kashrutLevels: ["Strict"] })).toEqual({ ok: false, error: "plus_required" });
  });

  test("a subscriber without consent can still set the non-religious criteria", async () => {
    const { service } = setup({ plus: true, consent: false });
    const result = await service.update(1, { onlyWithPhoto: true });
    expect(result).toEqual({ ok: true, filters: { ...NO_FILTERS, onlyWithPhoto: true } });
  });

  test("a partial update keeps the criteria it does not mention", async () => {
    const { service } = setup({ plus: true, consent: true });
    await service.update(1, { denominations: ["Massorti"] });
    const result = await service.update(1, { shabbatObservances: ["Observant"] });
    expect(result).toEqual({ ok: true, filters: { ...NO_FILTERS, denominations: ["Massorti"], shabbatObservances: ["Observant"] } });
  });
});

describe("DiscoverFiltersService.read", () => {
  test("hands the stored criteria back whether or not they apply, with the mazl+ state", async () => {
    const { service, entitlements } = setup({ plus: true, consent: true });
    await service.update(1, { onlyVerified: true });
    entitlements.plus = false;
    expect(await service.read(1)).toEqual({ filters: { ...NO_FILTERS, onlyVerified: true }, plus: false });
  });
});

describe("DiscoverFiltersService.applicableFor", () => {
  test("a member without any criterion costs no subscription nor consent lookup", async () => {
    const { service, calls } = setup({ plus: true, consent: true });
    expect(await service.applicableFor(1)).toEqual(NO_FILTERS);
    expect(calls).toEqual({ plus: 0, consent: 0 });
  });

  test("an expired subscription applies nothing but keeps the stored criteria", async () => {
    const { service, entitlements, store } = setup({ plus: true, consent: true });
    await service.update(1, { onlyVerified: true, kashrutLevels: ["Strict"] });
    entitlements.plus = false;
    expect(await service.applicableFor(1)).toEqual(NO_FILTERS);
    expect(store.rows.get(1)?.kashrutLevels).toEqual(["Strict"]);
  });

  test("the consent is only looked up when a religious criterion is stored", async () => {
    const { service, calls } = setup({ plus: true, consent: true });
    await service.update(1, { onlyVerified: true });
    calls.consent = 0;
    expect(await service.applicableFor(1)).toEqual({ ...NO_FILTERS, onlyVerified: true });
    expect(calls.consent).toBe(0);
  });

  test("an outdated consent drops the religious criteria from the applied set", async () => {
    const { service, entitlements } = setup({ plus: true, consent: true });
    await service.update(1, { onlyVerified: true, denominations: ["Massorti"] });
    entitlements.consent = false;
    expect(await service.applicableFor(1)).toEqual({ ...NO_FILTERS, onlyVerified: true });
  });
});
