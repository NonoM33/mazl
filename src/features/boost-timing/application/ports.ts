import type { HourCount } from "../domain/best-time";

export interface ActivityStore {
  // One more session in the member's city for this weekday and hour (UTC); nothing when the member has no city.
  record(userId: number, dow: number, hour: number): Promise<void>;
  // The member's city (display name and key), null when the profile has none.
  cityOf(userId: number): Promise<{ readonly key: string; readonly label: string } | null>;
  counts(cityKey: string): Promise<HourCount[]>;
}

export type ScheduleOutcome = "scheduled" | "already_scheduled";

export interface ScheduleStore {
  schedule(userId: number, runAt: Date): Promise<ScheduleOutcome>;
  get(userId: number): Promise<Date | null>;
  cancel(userId: number): Promise<void>;
  // Claims the schedules due at `now` (not older than `graceMs`) so that two
  // sweeps never run the same one; returns their members. Older ones are dropped.
  claimDue(now: Date, graceMs: number): Promise<number[]>;
  // Forgets the schedules already run.
  forgetRun(userIds: readonly number[]): Promise<void>;
}

export type LaunchOutcome = "started" | "no_credit" | "already_active";

export interface BoostLauncher {
  available(userId: number): Promise<number>;
  // Takes a Boost credit and starts the Boost (the credit goes back if starting fails).
  launch(userId: number): Promise<LaunchOutcome>;
}

export interface ScheduledBoostNotifier {
  started(userId: number): Promise<void>;
  notStarted(userId: number): Promise<void>;
}
