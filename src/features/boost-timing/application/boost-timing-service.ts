import { busiestSlot, checkScheduleTime, isoWeekday, nextOccurrence } from "../domain/best-time";
import type { ActivityStore, BoostLauncher, ScheduleOutcome, ScheduleStore, ScheduledBoostNotifier } from "./ports";

export interface BestTimeView {
  readonly city: string | null;
  readonly bestTime: { readonly startsAt: Date; readonly weekday: number; readonly hour: number } | null;
  readonly scheduledAt: Date | null;
}

export type ScheduleResult =
  | { readonly kind: "scheduled"; readonly scheduledAt: Date }
  | { readonly kind: "invalid_time" }
  | { readonly kind: "boosts_exhausted" }
  | { readonly kind: "already_scheduled" };

export interface BoostTimingDeps {
  readonly activity: ActivityStore;
  readonly schedules: ScheduleStore;
  readonly boosts: BoostLauncher;
  readonly notifier: ScheduledBoostNotifier;
  readonly clock?: () => Date;
  readonly minimumSessions?: number;
}

// A schedule the server could not run within this delay (it was down) is dropped, not run late.
const RUN_GRACE_MS = 15 * 60_000;

export function createBoostTimingService(deps: BoostTimingDeps) {
  const clock = deps.clock ?? (() => new Date());

  async function bestTime(userId: number): Promise<BestTimeView> {
    const [city, scheduledAt] = await Promise.all([deps.activity.cityOf(userId), deps.schedules.get(userId)]);
    if (city === null) return { city: null, bestTime: null, scheduledAt };
    const slot = busiestSlot(await deps.activity.counts(city.key), deps.minimumSessions);
    if (slot === null) return { city: city.label, bestTime: null, scheduledAt };
    const startsAt = nextOccurrence(slot, clock());
    return { city: city.label, bestTime: { startsAt, weekday: isoWeekday(startsAt), hour: startsAt.getUTCHours() }, scheduledAt };
  }

  // No credit is taken now: it is taken when the Boost starts, and a member who
  // has none left by then is told, charged nothing.
  async function schedule(userId: number, at: Date): Promise<ScheduleResult> {
    const verdict = checkScheduleTime(at, clock());
    if (!verdict.ok) return { kind: "invalid_time" };
    if ((await deps.boosts.available(userId)) < 1) return { kind: "boosts_exhausted" };
    const outcome: ScheduleOutcome = await deps.schedules.schedule(userId, verdict.at);
    return outcome === "scheduled" ? { kind: "scheduled", scheduledAt: verdict.at } : { kind: "already_scheduled" };
  }

  async function cancel(userId: number): Promise<void> {
    await deps.schedules.cancel(userId);
  }

  // The task of the sweep (every minute): starts the Boosts that are due.
  async function runDue(): Promise<number> {
    const due = await deps.schedules.claimDue(clock(), RUN_GRACE_MS);
    for (const userId of due) {
      try {
        const outcome = await deps.boosts.launch(userId);
        // A Boost already running needs no word: it is what the member wanted.
        if (outcome === "started") await deps.notifier.started(userId);
        else if (outcome === "no_credit") await deps.notifier.notStarted(userId);
      } catch (error: unknown) {
        console.error("Scheduled Boost failed:", error instanceof Error ? error.name : "unknown");
      }
    }
    await deps.schedules.forgetRun(due);
    return due.length;
  }

  return { bestTime, schedule, cancel, runDue };
}

export type BoostTimingService = ReturnType<typeof createBoostTimingService>;
