import { DEFAULT_TIME_ZONE, timeZoneFor } from "../domain/local-time";
import { reminderText } from "../domain/reminder-texts";
import { planDateReminders, planRitualReminders, type CandleLighting } from "../domain/reminders";
import type { ReminderCouple, ReminderPush, ReminderStore } from "./reminder-ports";

export interface ReminderDeps {
  readonly store: ReminderStore;
  readonly push: ReminderPush;
  readonly candleLightingFor: (latitude: number, longitude: number, timeZone: string) => CandleLighting;
  readonly paris: { readonly latitude: number; readonly longitude: number };
  readonly log: (line: string) => void;
}

export const REMINDER_DATA = { type: "couple_reminder", route: "/couple/agenda" } as const;

// One pass of the sweep, run every minute: for each couple with MAZL Couple, the
// dates whose eve (or chosen advance) has come and the rituals about to start
// are pushed to BOTH members, once (the claim in the store).
export class ReminderService {
  constructor(private readonly deps: ReminderDeps) {}

  async sweep(now: Date): Promise<number> {
    if (!this.deps.push.isEnabled()) return 0;
    let sent = 0;
    for (const couple of await this.deps.store.couplesWithPremium()) {
      try {
        sent += await this.remind(couple, now);
      } catch (error: unknown) {
        this.deps.log(`Couple reminder failed: ${error instanceof Error ? error.name : "unknown"}`);
      }
    }
    return sent;
  }

  private async remind(couple: ReminderCouple, now: Date): Promise<number> {
    const hasPlace = couple.latitude !== null && couple.longitude !== null;
    const timeZone = hasPlace ? timeZoneFor(couple.latitude, couple.longitude) : DEFAULT_TIME_ZONE;
    const place = hasPlace && couple.latitude !== null && couple.longitude !== null ? { latitude: couple.latitude, longitude: couple.longitude } : this.deps.paris;
    const candleLighting = this.deps.candleLightingFor(place.latitude, place.longitude, timeZone);
    const plans = [
      ...planDateReminders(await this.deps.store.dates(couple.id), now, timeZone),
      ...planRitualReminders(await this.deps.store.enabledRituals(couple.id), now, timeZone, candleLighting),
    ];
    let sent = 0;
    for (const plan of plans) {
      if (!(await this.deps.store.claim(couple.id, plan))) continue;
      const text = reminderText(plan, timeZone);
      for (const userId of couple.memberIds) await this.deps.push.send(userId, { ...text, data: REMINDER_DATA });
      sent += 1;
    }
    return sent;
  }
}
