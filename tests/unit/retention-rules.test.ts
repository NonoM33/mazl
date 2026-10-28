import { describe, expect, test } from "bun:test";
import { describeReport, runRetentionPass } from "../../src/features/retention/application/purge";
import type { RetentionStore } from "../../src/features/retention/application/ports";
import { RETENTION_INTERVAL_MS, RETENTION_RULES, type RetentionRule } from "../../src/features/retention/domain/rules";
import { startRetentionSweeper } from "../../src/features/retention/infra/sweeper";

// Durations written from the brief (privacy policy), not read from the code.
const EXPECTED: { table: string; column: string; age: string; keepWhileUnexpired: boolean }[] = [
  { table: "location_updates", column: "created_at", age: "30 days", keepWhileUnexpired: false },
  { table: "face_verification_sessions", column: "created_at", age: "12 months", keepWhileUnexpired: true },
  { table: "moderation_logs", column: "created_at", age: "12 months", keepWhileUnexpired: false },
  { table: "banned_document_fingerprints", column: "banned_at", age: "5 years", keepWhileUnexpired: false },
];

describe("retention rules", () => {
  test("cover exactly the four tables with the announced durations", () => {
    const actual: { table: string; column: string; age: string; keepWhileUnexpired: boolean }[] = RETENTION_RULES.map((r) => ({ table: r.table, column: r.column, age: `${r.amount} ${r.unit}`, keepWhileUnexpired: r.keepWhileUnexpired }));
    expect(actual).toEqual(EXPECTED);
  });

  test("the pass runs every rule and reports the count per table", async () => {
    const seen: string[] = [];
    const store: RetentionStore = { purge: async (rule: RetentionRule) => { seen.push(rule.table); return seen.length; } };
    const report = await runRetentionPass(store, RETENTION_RULES);
    expect(report).toEqual({ location_updates: 1, face_verification_sessions: 2, moderation_logs: 3, banned_document_fingerprints: 4 });
    expect(describeReport(report)).toBe("retention: purged location_updates=1 face_verification_sessions=2 moderation_logs=3 banned_document_fingerprints=4");
  });

  test("runs every 6 hours", () => {
    expect(RETENTION_INTERVAL_MS).toBe(21_600_000);
  });
});

describe("retention sweeper", () => {
  const silence = (): { info: string[]; error: unknown[][]; restore: () => void } => {
    const info: string[] = [];
    const error: unknown[][] = [];
    const [i, e] = [console.info, console.error];
    console.info = (m: string) => { info.push(m); };
    console.error = (...a: unknown[]) => { error.push(a); };
    return { info, error, restore: () => { console.info = i; console.error = e; } };
  };

  test("logs one line only when rows were deleted, logs errors by name, never overlaps", async () => {
    const log = silence();
    let calls = 0;
    let release: () => void = () => undefined;
    const results = [{ a: 0 }, { a: 2 }];
    const stop = startRetentionSweeper(async () => {
      calls += 1;
      if (calls === 3) throw new TypeError("secret detail");
      if (calls === 4) await new Promise<void>((resolve) => { release = resolve; });
      return results[calls - 1] ?? { a: 0 };
    }, 5);
    try {
      await Bun.sleep(80);
      release();
      await Bun.sleep(30);
    } finally {
      stop();
      log.restore();
    }
    expect(log.info).toEqual(["retention: purged a=2"]);
    expect(log.error[0]).toEqual(["retention: purge failed", "TypeError"]);
    expect(calls).toBeGreaterThanOrEqual(4);
  });
});
