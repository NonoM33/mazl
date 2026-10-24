import { describe, expect, test } from "bun:test";
import { startPurgeScheduler, PURGE_INTERVAL_MS } from "../../src/features/documents/infra/purge-scheduler";

describe("purge scheduler", () => {
  test("runs once at boot, then every 6 hours", async () => {
    let runs = 0;
    let tick: (() => void) | undefined;
    let interval = 0;
    const stop = startPurgeScheduler(
      async () => {
        runs += 1;
        return { decided: 0, stale: 0 };
      },
      {
        schedule: (fn, ms) => {
          tick = fn;
          interval = ms;
          return { cancel: () => undefined };
        },
        log: () => undefined,
      },
    );
    await Promise.resolve();
    expect(runs).toBe(1);
    expect(interval).toBe(6 * 60 * 60 * 1000);
    expect(PURGE_INTERVAL_MS).toBe(interval);
    tick?.();
    await Promise.resolve();
    expect(runs).toBe(2);
    stop();
  });

  test("a failing sweep is logged and does not stop the schedule", async () => {
    const logged: string[] = [];
    let tick: (() => void) | undefined;
    startPurgeScheduler(
      async () => {
        throw new Error("db down");
      },
      {
        schedule: (fn) => {
          tick = fn;
          return { cancel: () => undefined };
        },
        log: (line) => logged.push(line),
      },
    );
    await new Promise((r) => setTimeout(r, 0));
    expect(logged.length).toBe(1);
    expect(() => tick?.()).not.toThrow();
  });
});
