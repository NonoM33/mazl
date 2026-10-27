import type { CoupleDate, ReminderPlan } from "../domain/reminders";
import type { Ritual } from "../domain/rituals";

// What the reminder sweep needs from the outside world.

export interface ReminderCouple {
  readonly id: number;
  readonly memberIds: readonly [number, number];
  // The place of the member who created the couple; null when they never gave one.
  readonly latitude: number | null;
  readonly longitude: number | null;
}

export interface ReminderStore {
  // Active couples with a live MAZL Couple subscription: the only ones reminded.
  couplesWithPremium(): Promise<ReminderCouple[]>;
  dates(coupleId: number): Promise<CoupleDate[]>;
  enabledRituals(coupleId: number): Promise<Ritual[]>;
  // True once, for the first caller: the reminder is then theirs to send.
  claim(coupleId: number, plan: ReminderPlan): Promise<boolean>;
}

export interface ReminderPush {
  // False while push is not configured: the sweep claims nothing then, so nothing is lost.
  isEnabled(): boolean;
  send(userId: number, message: { readonly title: string; readonly message: string; readonly data: Readonly<Record<string, string>> }): Promise<void>;
}
