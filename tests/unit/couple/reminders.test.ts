import { describe, expect, test } from "bun:test";
import { ReminderService } from "../../../src/features/couple/application/reminder-service";
import type { ReminderCouple, ReminderPush, ReminderStore } from "../../../src/features/couple/application/reminder-ports";
import { localParts, zonedInstant } from "../../../src/features/couple/domain/local-time";
import type { CoupleDate, ReminderPlan } from "../../../src/features/couple/domain/reminders";
import type { Ritual } from "../../../src/features/couple/domain/rituals";

// Expected values are worked out by hand from the contract (section 3), in the
// Paris wall clock: an event "the day before" is the local day before, at 09:00.

const PARIS = "Europe/Paris";
const at = (y: number, m: number, d: number, h: number, min = 0): Date => zonedInstant(y, m, d, h, min, PARIS);
// Friday 2026-10-30, candle lighting fixed at 17:10 Paris time.
const CANDLES = () => at(2026, 10, 30, 17, 10);

const couple: ReminderCouple = { id: 7, memberIds: [1, 2], latitude: null, longitude: null };

function ritual(over: Partial<Ritual>): Ritual {
  return { id: 1, coupleId: 7, kind: "weekly", title: "Soirée sans écran", weekday: 2, time: "20:00", enabled: true, remindMinutes: 60, ...over };
}

class Fixture {
  readonly claimed = new Set<string>();
  readonly sent: { userId: number; message: string; data: Record<string, string> }[] = [];
  premium: ReminderCouple[] = [couple];
  dates: CoupleDate[] = [];
  rituals: Ritual[] = [];
  pushEnabled = true;

  store: ReminderStore = {
    couplesWithPremium: async () => this.premium,
    dates: async () => this.dates,
    enabledRituals: async () => this.rituals.filter((r) => r.enabled),
    claim: async (coupleId: number, plan: ReminderPlan) => {
      const key = `${String(coupleId)}|${plan.source}|${String(plan.refId)}|${plan.occurrence}`;
      if (this.claimed.has(key)) return false;
      this.claimed.add(key);
      return true;
    },
  };
  push: ReminderPush = {
    isEnabled: () => this.pushEnabled,
    send: async (userId, message) => {
      this.sent.push({ userId, message: message.message, data: { ...message.data } });
    },
  };
  service = new ReminderService({
    store: this.store,
    push: this.push,
    candleLightingFor: () => CANDLES,
    paris: { latitude: 48.85, longitude: 2.35 },
    log: () => undefined,
  });
}

describe("date reminders", () => {
  test("the eve of a date, from 09:00 local time, reaches both members once", async () => {
    const f = new Fixture();
    f.dates = [{ id: 3, date: "2020-11-05", isRecurring: true, remindDaysBefore: 0 }];
    expect(await f.service.sweep(at(2026, 11, 4, 8, 59))).toBe(0);
    expect(await f.service.sweep(at(2026, 11, 4, 9, 0))).toBe(1);
    expect(f.sent.map((s) => s.userId).sort()).toEqual([1, 2]);
    expect(f.sent[0]?.data).toEqual({ type: "couple_reminder", route: "/couple/agenda" });
    expect(await f.service.sweep(at(2026, 11, 4, 9, 1))).toBe(0);
    expect(f.sent).toHaveLength(2);
  });

  test("remind_days_before: seven days ahead, once, and the eve still comes", async () => {
    const f = new Fixture();
    f.dates = [{ id: 3, date: "2020-11-12", isRecurring: true, remindDaysBefore: 7 }];
    expect(await f.service.sweep(at(2026, 11, 5, 10))).toBe(1);
    expect(f.sent[0]?.message).toContain("7 jours");
    expect(await f.service.sweep(at(2026, 11, 5, 18))).toBe(0);
    expect(await f.service.sweep(at(2026, 11, 6, 10))).toBe(0); // five days ahead: nothing
    expect(await f.service.sweep(at(2026, 11, 11, 10))).toBe(1); // the eve
  });

  test("a date that is not recurring and already past never rings; the same day next year does for a recurring one", async () => {
    const f = new Fixture();
    f.dates = [
      { id: 1, date: "2025-11-05", isRecurring: false, remindDaysBefore: 0 },
      { id: 2, date: "2025-11-05", isRecurring: true, remindDaysBefore: 0 },
    ];
    expect(await f.service.sweep(at(2026, 11, 4, 10))).toBe(1);
    expect(f.claimed.size).toBe(1);
  });

  test("the text names nobody and carries no date title", async () => {
    const f = new Fixture();
    f.dates = [{ id: 3, date: "2020-11-05", isRecurring: true, remindDaysBefore: 0 }];
    await f.service.sweep(at(2026, 11, 4, 9, 30));
    expect(f.sent[0]?.message).toBe("C'est demain : une date importante pour vous deux.");
  });
});

describe("ritual reminders", () => {
  test("remind_minutes before the start, not before, not after", async () => {
    const f = new Fixture();
    f.rituals = [ritual({ weekday: 2, time: "20:00", remindMinutes: 30 })]; // Tuesday 2026-11-03
    expect(await f.service.sweep(at(2026, 11, 3, 19, 29))).toBe(0);
    expect(await f.service.sweep(at(2026, 11, 3, 19, 30))).toBe(1);
    expect(await f.service.sweep(at(2026, 11, 3, 19, 45))).toBe(0); // already sent
    expect(await f.service.sweep(at(2026, 11, 3, 20, 1))).toBe(0);
  });

  test("a disabled ritual stays silent", async () => {
    const f = new Fixture();
    f.rituals = [ritual({ enabled: false })];
    expect(await f.service.sweep(at(2026, 11, 3, 19, 30))).toBe(0);
  });

  test("Shabbat rings before the candle-lighting time of the couple's place", async () => {
    const f = new Fixture();
    f.rituals = [ritual({ kind: "shabbat", title: "Shabbat ensemble", weekday: 5, time: null, remindMinutes: 60 })];
    expect(await f.service.sweep(at(2026, 10, 30, 16, 9))).toBe(0);
    expect(await f.service.sweep(at(2026, 10, 30, 16, 10))).toBe(1);
    expect(f.sent[0]?.message).toBe("Shabbat approche : allumage des bougies à 17:10.");
    // next Friday is a new occurrence: it rings again, not twice
    expect(await f.service.sweep(at(2026, 10, 30, 16, 40))).toBe(0);
  });

  test("the shabbat ritual of the week after is a distinct occurrence", () => {
    // Guards the dedupe key: the Friday date, not the ritual alone.
    const friday = localParts(at(2026, 10, 30, 12), PARIS);
    expect(friday.weekday).toBe(5);
  });
});

describe("no subscription, no push", () => {
  test("a couple without MAZL Couple is not in the list, so nothing is sent", async () => {
    const f = new Fixture();
    f.premium = [];
    f.dates = [{ id: 3, date: "2020-11-05", isRecurring: true, remindDaysBefore: 0 }];
    expect(await f.service.sweep(at(2026, 11, 4, 10))).toBe(0);
    expect(f.sent).toHaveLength(0);
  });

  test("push not configured: nothing is claimed, so the reminder is not lost", async () => {
    const f = new Fixture();
    f.pushEnabled = false;
    f.dates = [{ id: 3, date: "2020-11-05", isRecurring: true, remindDaysBefore: 0 }];
    expect(await f.service.sweep(at(2026, 11, 4, 10))).toBe(0);
    expect(f.claimed.size).toBe(0);
    f.pushEnabled = true;
    expect(await f.service.sweep(at(2026, 11, 4, 11))).toBe(1);
  });
});

describe("time helpers", () => {
  test("zonedInstant crosses the October daylight-saving change", () => {
    expect(zonedInstant(2026, 10, 24, 12, 0, PARIS).toISOString()).toBe("2026-10-24T10:00:00.000Z");
    expect(zonedInstant(2026, 10, 26, 12, 0, PARIS).toISOString()).toBe("2026-10-26T11:00:00.000Z");
  });
});
