import {
  applicableFilters,
  applyPatch,
  hasCriterion,
  hasReligiousCriterion,
  NO_FILTERS,
  patchAsksForAdvancedCriteria,
  patchAsksForReligiousCriteria,
  type DiscoverFilters,
  type DiscoverFiltersPatch,
} from "../domain/discover-filters";
import type { ApplicableFilters, DiscoverFiltersStore, FilterEntitlements } from "./ports";

export type FiltersUpdate =
  | { readonly ok: true; readonly filters: DiscoverFilters }
  | { readonly ok: false; readonly error: "plus_required" | "religious_consent_required" };

export class DiscoverFiltersService implements ApplicableFilters {
  constructor(
    private readonly store: DiscoverFiltersStore,
    private readonly entitlements: FilterEntitlements,
  ) {}

  // What is stored, even when it no longer applies (expired mazl+).
  async read(userId: number): Promise<{ readonly filters: DiscoverFilters; readonly plus: boolean }> {
    const [filters, plus] = await Promise.all([this.store.get(userId), this.entitlements.isPlus(userId)]);
    return { filters, plus };
  }

  async update(userId: number, patch: DiscoverFiltersPatch): Promise<FiltersUpdate> {
    if (patchAsksForAdvancedCriteria(patch) && !(await this.entitlements.isPlus(userId))) {
      return { ok: false, error: "plus_required" };
    }
    if (patchAsksForReligiousCriteria(patch) && !(await this.entitlements.allowsReligiousData(userId))) {
      return { ok: false, error: "religious_consent_required" };
    }
    const filters = applyPatch(await this.store.get(userId), patch);
    await this.store.save(userId, filters);
    return { ok: true, filters };
  }

  // The criteria the feed applies. One read for the common case (no filter set).
  async applicableFor(userId: number): Promise<DiscoverFilters> {
    const stored = await this.store.get(userId);
    if (!hasCriterion(stored)) return NO_FILTERS;
    const plus = await this.entitlements.isPlus(userId);
    if (!plus) return NO_FILTERS;
    const religiousConsent = hasReligiousCriterion(stored) ? await this.entitlements.allowsReligiousData(userId) : false;
    return applicableFilters(stored, { plus, religiousConsent });
  }
}
