import type { ActivityStore } from "./ports";

// Counts a member once per hour: opening Discover ten times is one session.
// The memory holds ids for the current hour only (no history of who was there).
export function createActivityRecorder(store: ActivityStore, clock: () => Date = () => new Date()) {
  let hourStart = -1;
  let seen = new Set<number>();
  return {
    async touch(userId: number): Promise<void> {
      const now = clock();
      const bucket = Math.floor(now.getTime() / 3_600_000);
      if (bucket !== hourStart) {
        hourStart = bucket;
        seen = new Set();
      }
      if (seen.has(userId)) return;
      seen.add(userId);
      try {
        await store.record(userId, now.getUTCDay(), now.getUTCHours());
      } catch (error: unknown) {
        seen.delete(userId);
        throw error;
      }
    },
  };
}

export type ActivityRecorder = ReturnType<typeof createActivityRecorder>;
