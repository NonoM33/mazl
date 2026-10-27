import { describe, expect, test } from "bun:test";
import { createActivityRecorder } from "../../src/features/boost-timing/application/activity-recorder";
import { createBoostTimingService } from "../../src/features/boost-timing/application/boost-timing-service";
import type { ActivityStore, BoostLauncher, LaunchOutcome, ScheduleStore, ScheduledBoostNotifier } from "../../src/features/boost-timing/application/ports";
import {
  busiestSlot, checkScheduleTime, cityKeyOf, isoWeekday, MIN_SESSIONS_FOR_A_CITY, nextOccurrence, type HourCount,
} from "../../src/features/boost-timing/domain/best-time";

// docs/premium/MONETISATION.md section 8.

const SATURDAY = 6;

describe("busiestSlot", () => {
  test("the busiest hour of the week", () => {
    const counts: HourCount[] = [
      { dow: 2, hour: 20, sessions: 30 },
      { dow: SATURDAY, hour: 21, sessions: 90 },
      { dow: 0, hour: 9, sessions: 40 },
    ];
    expect(busiestSlot(counts)).toEqual({ dow: SATURDAY, hour: 21 });
  });

  test("a tie goes to the earliest hour of the week, not to the order of the rows", () => {
    const counts: HourCount[] = [{ dow: 5, hour: 20, sessions: 40 }, { dow: 1, hour: 8, sessions: 40 }, { dow: 3, hour: 3, sessions: 1 }];
    expect(busiestSlot(counts)).toEqual({ dow: 1, hour: 8 });
  });

  test("a quiet city says nothing: too few sessions to mean anything", () => {
    expect(busiestSlot([{ dow: 1, hour: 8, sessions: MIN_SESSIONS_FOR_A_CITY - 1 }])).toBeNull();
    expect(busiestSlot([{ dow: 1, hour: 8, sessions: MIN_SESSIONS_FOR_A_CITY }])).toEqual({ dow: 1, hour: 8 });
    expect(busiestSlot([])).toBeNull();
  });
});

describe("nextOccurrence", () => {
  test("the coming Saturday 21:00 UTC", () => {
    // Tuesday 2026-10-27 12:00 UTC.
    const next = nextOccurrence({ dow: SATURDAY, hour: 21 }, new Date("2026-10-27T12:00:00Z"));
    expect(next.toISOString()).toBe("2026-10-31T21:00:00.000Z");
  });

  test("later today when the hour is still ahead, next week when it has passed", () => {
    const tuesday = { dow: 2, hour: 20 };
    expect(nextOccurrence(tuesday, new Date("2026-10-27T12:00:00Z")).toISOString()).toBe("2026-10-27T20:00:00.000Z");
    expect(nextOccurrence(tuesday, new Date("2026-10-27T20:30:00Z")).toISOString()).toBe("2026-11-03T20:00:00.000Z");
  });

  test("never closer than the lead time", () => {
    const slot = { dow: 2, hour: 12 };
    expect(nextOccurrence(slot, new Date("2026-10-27T11:59:00Z")).toISOString()).toBe("2026-11-03T12:00:00.000Z");
  });

  test("weekday as the app reads it: Monday 1 to Sunday 7", () => {
    expect(isoWeekday(new Date("2026-10-26T10:00:00Z"))).toBe(1);
    expect(isoWeekday(new Date("2026-10-31T10:00:00Z"))).toBe(6);
    expect(isoWeekday(new Date("2026-11-01T10:00:00Z"))).toBe(7);
  });
});

describe("checkScheduleTime", () => {
  const now = new Date("2026-10-27T12:00:00Z");
  test("between two minutes and seven days ahead", () => {
    expect(checkScheduleTime(new Date("2026-10-27T12:01:59Z"), now).ok).toBe(false);
    expect(checkScheduleTime(new Date("2026-10-27T12:02:00Z"), now).ok).toBe(true);
    expect(checkScheduleTime(new Date("2026-11-03T12:00:00Z"), now).ok).toBe(true);
    expect(checkScheduleTime(new Date("2026-11-03T12:00:01Z"), now).ok).toBe(false);
    expect(checkScheduleTime(new Date("2026-10-27T11:00:00Z"), now).ok).toBe(false);
    expect(checkScheduleTime(new Date("nonsense"), now).ok).toBe(false);
  });
});

describe("cityKeyOf", () => {
  test("the first part of the location, lower-cased", () => {
    expect(cityKeyOf("Paris, France")).toBe("paris");
    expect(cityKeyOf("  Tel   Aviv , Israël")).toBe("tel aviv");
    expect(cityKeyOf("")).toBeNull();
    expect(cityKeyOf(null)).toBeNull();
    expect(cityKeyOf(", France")).toBeNull();
  });
});

class FakeActivity implements ActivityStore {
  readonly recorded: Array<{ userId: number; dow: number; hour: number }> = [];
  city: { key: string; label: string } | null = { key: "paris", label: "Paris" };
  rows: HourCount[] = [];
  async record(userId: number, dow: number, hour: number) { this.recorded.push({ userId, dow, hour }); }
  async cityOf() { return this.city; }
  async counts() { return this.rows; }
}

class FakeSchedules implements ScheduleStore {
  readonly rows = new Map<number, { runAt: Date; claimed: boolean }>();
  async schedule(userId: number, runAt: Date) {
    const existing = this.rows.get(userId);
    if (existing !== undefined && !existing.claimed) return "already_scheduled" as const;
    this.rows.set(userId, { runAt, claimed: false });
    return "scheduled" as const;
  }
  async get(userId: number) { const row = this.rows.get(userId); return row === undefined || row.claimed ? null : row.runAt; }
  async cancel(userId: number) { if (this.rows.get(userId)?.claimed === false) this.rows.delete(userId); }
  async claimDue(now: Date, graceMs: number) {
    const claimed: number[] = [];
    for (const [userId, row] of this.rows) {
      if (row.claimed) continue;
      if (row.runAt.getTime() < now.getTime() - graceMs) this.rows.delete(userId);
      else if (row.runAt <= now) { row.claimed = true; claimed.push(userId); }
    }
    return claimed;
  }
  async forgetRun(userIds: readonly number[]) { for (const id of userIds) if (this.rows.get(id)?.claimed) this.rows.delete(id); }
}

function setup(options: { boosts?: number; launch?: LaunchOutcome } = {}) {
  const activity = new FakeActivity();
  const schedules = new FakeSchedules();
  const launched: number[] = [];
  const told: string[] = [];
  const clock = { now: new Date("2026-10-27T12:00:00Z") };
  const boosts: BoostLauncher = {
    async available() { return options.boosts ?? 1; },
    async launch(userId) { launched.push(userId); return options.launch ?? "started"; },
  };
  const notifier: ScheduledBoostNotifier = {
    async started(userId) { told.push(`started:${userId}`); },
    async notStarted(userId) { told.push(`missed:${userId}`); },
  };
  const service = createBoostTimingService({ activity, schedules, boosts, notifier, clock: () => clock.now });
  return { activity, schedules, launched, told, clock, service };
}

describe("best time for a city", () => {
  test("names the next busiest hour, in UTC and as a weekday", async () => {
    const { activity, service } = setup();
    activity.rows = [{ dow: SATURDAY, hour: 21, sessions: 80 }, { dow: 1, hour: 12, sessions: 20 }];
    const view = await service.bestTime(7);
    expect(view.city).toBe("Paris");
    expect(view.bestTime?.startsAt.toISOString()).toBe("2026-10-31T21:00:00.000Z");
    expect([view.bestTime?.weekday, view.bestTime?.hour]).toEqual([6, 21]);
  });

  test("nothing to suggest for a quiet city or a member without a city", async () => {
    const quiet = setup();
    quiet.activity.rows = [{ dow: 1, hour: 12, sessions: 3 }];
    expect((await quiet.service.bestTime(7)).bestTime).toBeNull();
    const nowhere = setup();
    nowhere.activity.city = null;
    expect(await nowhere.service.bestTime(7)).toEqual({ city: null, bestTime: null, scheduledAt: null });
  });
});

describe("programming a Boost", () => {
  const at = new Date("2026-10-31T21:00:00Z");

  test("is kept, announced back, and takes no credit yet", async () => {
    const { service, launched } = setup();
    expect(await service.schedule(7, at)).toEqual({ kind: "scheduled", scheduledAt: at });
    expect((await service.bestTime(7)).scheduledAt).toEqual(at);
    expect(launched).toEqual([]);
  });

  test("refused in the past or beyond a week, whatever the credits", async () => {
    const { service } = setup();
    expect(await service.schedule(7, new Date("2026-10-27T11:00:00Z"))).toEqual({ kind: "invalid_time" });
    expect(await service.schedule(7, new Date("2026-12-01T11:00:00Z"))).toEqual({ kind: "invalid_time" });
  });

  test("refused without a Boost to spend, and a second one waits for the first", async () => {
    expect(await setup({ boosts: 0 }).service.schedule(7, at)).toEqual({ kind: "boosts_exhausted" });
    const { service } = setup();
    await service.schedule(7, at);
    expect(await service.schedule(7, new Date("2026-11-01T10:00:00Z"))).toEqual({ kind: "already_scheduled" });
  });

  test("can be cancelled, then programmed again", async () => {
    const { service } = setup();
    await service.schedule(7, at);
    await service.cancel(7);
    expect((await service.bestTime(7)).scheduledAt).toBeNull();
    expect((await service.schedule(7, at)).kind).toBe("scheduled");
  });
});

describe("the sweep", () => {
  const at = new Date("2026-10-31T21:00:00Z");

  test("starts the Boost at the time and tells the member, once", async () => {
    const { service, clock, launched, told } = setup();
    await service.schedule(7, at);
    clock.now = new Date("2026-10-31T20:59:30Z");
    expect(await service.runDue()).toBe(0);
    clock.now = new Date("2026-10-31T21:00:20Z");
    expect(await service.runDue()).toBe(1);
    expect(await service.runDue()).toBe(0);
    expect(launched).toEqual([7]);
    expect(told).toEqual(["started:7"]);
  });

  test("a member with no Boost left by then is told, nothing is charged", async () => {
    const { service, clock, told } = setup({ launch: "no_credit" });
    await service.schedule(7, at);
    clock.now = new Date("2026-10-31T21:00:20Z");
    await service.runDue();
    expect(told).toEqual(["missed:7"]);
  });

  test("a Boost already running needs no word", async () => {
    const { service, clock, told } = setup({ launch: "already_active" });
    await service.schedule(7, at);
    clock.now = new Date("2026-10-31T21:00:20Z");
    await service.runDue();
    expect(told).toEqual([]);
  });

  test("a schedule missed by more than the grace period (server down) is dropped, not run late", async () => {
    const { service, clock, launched } = setup();
    await service.schedule(7, at);
    clock.now = new Date("2026-10-31T22:00:00Z");
    expect(await service.runDue()).toBe(0);
    expect(launched).toEqual([]);
    expect((await service.bestTime(7)).scheduledAt).toBeNull();
  });

  test("one failing launch does not stop the others", async () => {
    const { service, schedules, clock, told } = setup();
    schedules.rows.set(1, { runAt: new Date("2026-10-31T21:00:00Z"), claimed: false });
    schedules.rows.set(2, { runAt: new Date("2026-10-31T21:00:00Z"), claimed: false });
    clock.now = new Date("2026-10-31T21:00:20Z");
    const failing = createBoostTimingService({
      activity: new FakeActivity(), schedules,
      boosts: { available: async () => 1, launch: async (userId) => { if (userId === 1) throw new Error("db down"); return "started"; } },
      notifier: { started: async (userId) => { told.push(`started:${userId}`); }, notStarted: async () => undefined },
      clock: () => clock.now,
    });
    const originalError = console.error;
    console.error = () => undefined;
    try {
      expect(await failing.runDue()).toBe(2);
    } finally {
      console.error = originalError;
    }
    expect(told).toEqual(["started:2"]);
  });
});

describe("counting sessions", () => {
  test("a member opening Discover many times in an hour is one session; the next hour is another", async () => {
    const store = new FakeActivity();
    const clock = { now: new Date("2026-10-31T21:05:00Z") };
    const recorder = createActivityRecorder(store, () => clock.now);
    await recorder.touch(7);
    await recorder.touch(7);
    await recorder.touch(8);
    clock.now = new Date("2026-10-31T21:50:00Z");
    await recorder.touch(7);
    clock.now = new Date("2026-10-31T22:01:00Z");
    await recorder.touch(7);
    expect(store.recorded).toEqual([
      { userId: 7, dow: SATURDAY, hour: 21 },
      { userId: 8, dow: SATURDAY, hour: 21 },
      { userId: 7, dow: SATURDAY, hour: 22 },
    ]);
  });

  test("a failed write is tried again at the next opening", async () => {
    const store = new FakeActivity();
    let failing = true;
    const original = store.record.bind(store);
    store.record = async (userId, dow, hour) => { if (failing) throw new Error("db down"); await original(userId, dow, hour); };
    const recorder = createActivityRecorder(store, () => new Date("2026-10-31T21:05:00Z"));
    await expect(recorder.touch(7)).rejects.toThrow();
    failing = false;
    await recorder.touch(7);
    expect(store.recorded).toHaveLength(1);
  });
});
