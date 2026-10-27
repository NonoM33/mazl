import type { EffectiveSettings, Passport } from "../domain/settings";
import type { PlusLookup, SettingsStore } from "./ports";

export type Switch<T> = { readonly ok: true; readonly value: T } | { readonly ok: false; readonly reason: "plus_required" };

export class PremiumSettingsService {
  constructor(
    private readonly store: SettingsStore,
    private readonly plus: PlusLookup,
  ) {}

  // A passport or a discreet mode kept from a past subscription is not in force:
  // it is neither reported nor applied until mazl+ is back.
  async read(userId: number): Promise<EffectiveSettings> {
    const [stored, isPlus] = await Promise.all([this.store.read(userId), this.plus.isPlus(userId)]);
    return { isPlus, passport: isPlus ? stored.passport : null, incognito: isPlus && stored.incognito, sendReadReceipts: stored.sendReadReceipts };
  }

  // Coming back home is always allowed, even once the subscription has ended.
  async setPassport(userId: number, passport: Passport | null): Promise<Switch<Passport | null>> {
    if (passport !== null && !(await this.plus.isPlus(userId))) return { ok: false, reason: "plus_required" };
    await this.store.setPassport(userId, passport);
    return { ok: true, value: passport };
  }

  async setIncognito(userId: number, enabled: boolean): Promise<Switch<boolean>> {
    if (enabled && !(await this.plus.isPlus(userId))) return { ok: false, reason: "plus_required" };
    await this.store.setIncognito(userId, enabled);
    return { ok: true, value: enabled };
  }

  // Everybody may stop (or resume) sending their receipts; only seeing them is mazl+.
  async setReadReceipts(userId: number, enabled: boolean): Promise<boolean> {
    await this.store.setReadReceipts(userId, enabled);
    return enabled;
  }
}
